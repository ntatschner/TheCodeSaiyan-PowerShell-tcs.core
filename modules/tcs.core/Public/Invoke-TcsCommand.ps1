<#
.SYNOPSIS
    Runs the body of a tcs command and records anonymous telemetry for it.

.DESCRIPTION
    The Invoke-TcsCommand function replaces the telemetry boilerplate in tcs module commands.
    Wrap the body of a command in it:

      function Get-Widget {
          [CmdletBinding()]
          param([string]$Name)
          Invoke-TcsCommand -ScriptBlock {
              Get-Item -Path $Name
          }
      }

    The script block runs in the scope of the calling command (it is dot-sourced), so it
    reads and sets the command's variables as if it were written inline, and $PSCmdlet,
    $_ and ShouldProcess work as usual. Two automatic variables are different inside the
    script block: $PSBoundParameters and $MyInvocation describe the script block, not the
    command. Copy them to a variable before Invoke-TcsCommand if the body needs them.

    What it does:
      - Writes exactly what the script block outputs, unchanged (collections are not
        unrolled or wrapped), and nothing else.
      - Reports the run as failed when the script block throws a terminating error or writes
        a non-terminating error (Write-Error or a cmdlet error) that reaches the error stream.
        Errors that are caught, or silenced with -ErrorAction SilentlyContinue/Ignore, do not
        count. Errors written directly with $PSCmdlet.WriteError() bypass it; use the -Token
        form and Complete-TcsTelemetry -Failed for those.
      - Rethrows terminating errors unchanged, and passes non-terminating errors through.
      - Reports only the outermost run: when an exported command calls another exported
        command of the same module, the inner run sends nothing (it is skipped, not tagged).
      - Never fails or changes the command because of telemetry; telemetry problems are
        written to the verbose stream only.

    Without -Token, one call is one run: it starts and completes the telemetry itself. The
    command, module and version are taken from the calling command.

    With -Token (from Start-TcsTelemetry), it only records errors on that token. Use this in
    the process block of pipeline functions, and complete the token in the end block. If the
    script block throws, or the pipeline is stopped early (for example by Select-Object
    -First), the token is completed here, because the end block will not run.

.PARAMETER ScriptBlock
    The body of the command.

.PARAMETER CommandName
    The name reported for the command. Defaults to the name of the calling command.

.PARAMETER ModuleName
    The module the command belongs to. Defaults to the module of the calling command.

.PARAMETER ModuleVersion
    The module version. Defaults to the version of the calling command's module.

.PARAMETER Token
    A token from Start-TcsTelemetry. Errors are recorded on it and the token is completed
    only if the script block throws or the pipeline is stopped.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Object
    The output of the script block.

.EXAMPLE
    function Remove-Widget {
        [CmdletBinding(SupportsShouldProcess)]
        param([Parameter(Mandatory)][string]$Name)
        $bound = $PSBoundParameters
        Invoke-TcsCommand -ScriptBlock {
            if ($PSCmdlet.ShouldProcess($Name, 'Remove widget')) {
                Invoke-RestMethod -Method Delete -Uri "https://api.example.com/widgets/$Name"
            }
            Write-Verbose "Parameters: $($bound.Keys -join ', ')"
        }
    }

    A simple function. $PSBoundParameters is copied to $bound first because inside the script
    block it describes the script block.

.EXAMPLE
    function Get-Widget {
        [CmdletBinding()]
        param([Parameter(ValueFromPipeline)][string]$Name)
        begin { $telemetry = Start-TcsTelemetry }
        process {
            Invoke-TcsCommand -Token $telemetry -ScriptBlock {
                Invoke-RestMethod -Uri "https://api.example.com/widgets/$Name"
            }
        }
        end { Complete-TcsTelemetry -Token $telemetry }
    }

    A pipeline function: one event for the whole pipeline run, failed if any item failed.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

    Invoke-TelemetryCollection is unchanged and still works for existing commands.

    Lines that native programs in the script block write to stderr are passed on through the
    error stream (without the wrapper, PowerShell 7 writes them straight to the console) and
    never mark the run as failed. On Windows PowerShell 5.1, a native program that writes to
    stderr while $ErrorActionPreference is 'Stop' raises a NativeCommandError, as it does
    whenever its errors are redirected; use -ErrorAction Continue around such calls.

.LINK
    Start-TcsTelemetry

.LINK
    Complete-TcsTelemetry
#>
function Invoke-TcsCommand {
    [CmdletBinding(DefaultParameterSetName = 'Command')]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The body of the command.')]
        [scriptblock]$ScriptBlock,

        [Parameter(ParameterSetName = 'Command', HelpMessage = 'Name reported for the command.')]
        [string]$CommandName,

        [Parameter(ParameterSetName = 'Command', HelpMessage = 'Module the command belongs to.')]
        [string]$ModuleName,

        [Parameter(ParameterSetName = 'Command', HelpMessage = 'Version of the module.')]
        [string]$ModuleVersion,

        [Parameter(Mandatory, ParameterSetName = 'Token', HelpMessage = 'Token from Start-TcsTelemetry.')]
        [PSTypeName('Tcs.TelemetryToken')]
        [PSCustomObject]$Token
    )

    $ownsToken = $PSCmdlet.ParameterSetName -eq 'Command'
    if ($ownsToken) {
        $Token = $null
        try {
            $invocation = $null
            $callStack = @(Get-PSCallStack)
            if ($callStack.Count -gt 1) {
                $invocation = $callStack[1].InvocationInfo
            }
            $Token = New-TcsTelemetryToken -Invocation $invocation -CommandName $CommandName -ModuleName $ModuleName -ModuleVersion $ModuleVersion
        }
        catch {
            Write-Verbose "Telemetry could not be started: $($_.Exception.Message)"
        }
    }

    # The error stream is merged into the output only to watch it. An ErrorRecord that
    # PowerShell also recorded as a written error (-ErrorVariable) is written back to the error
    # stream unchanged, as are stderr lines of native programs (which never count as
    # failures); everything else, including ErrorRecords output as data, is written to the
    # output as it is (never unrolled). Errors that were caught or silenced inside the script
    # block are recorded but never reach the stream, so they do not count.
    # The errors already passed the calling command's error action, so pass them on as they are.
    $ErrorActionPreference = 'Continue'
    $recordedErrors = $null
    $firstWrittenError = $null
    $terminatingError = $null
    $finished = $false
    try {
        Invoke-TcsScriptBlock -ScriptBlock $ScriptBlock -ErrorVariable recordedErrors 2>&1 | ForEach-Object -Process {
            $item = $_
            $isError = $false
            if ($item -is [System.Management.Automation.ErrorRecord]) {
                if (Test-NativeCommandErrorRecord -ErrorRecord $item) {
                    $isError = $true
                }
                else {
                    foreach ($recorded in @($recordedErrors)) {
                        if ([object]::ReferenceEquals($recorded, $item)) {
                            $isError = $true
                            if ($null -eq $firstWrittenError) {
                                $firstWrittenError = $item
                            }
                            break
                        }
                    }
                }
            }
            if ($isError) {
                $PSCmdlet.WriteError($item)
            }
            else {
                $PSCmdlet.WriteObject($item)
            }
        }
        $finished = $true
    }
    catch {
        $terminatingError = $_
        throw
    }
    finally {
        # Runs for success, errors and a stopped pipeline alike; telemetry must never fail the command
        try {
            if ($Token) {
                if ($null -ne $terminatingError) {
                    Set-TcsTelemetryFailure -Token $Token -ErrorRecord $terminatingError
                }
                elseif ($null -ne $firstWrittenError) {
                    Set-TcsTelemetryFailure -Token $Token -ErrorRecord $firstWrittenError
                }
                if ($ownsToken -or -not $finished) {
                    Complete-TcsTelemetryToken -Token $Token
                }
            }
        }
        catch {
            Write-Verbose "Telemetry could not be completed: $($_.Exception.Message)"
        }
    }
}
