<#
.SYNOPSIS
    Starts timing one run of a command for telemetry and returns a token for Complete-TcsTelemetry.

.DESCRIPTION
    The Start-TcsTelemetry function is the first half of the telemetry wrapper for commands in
    tcs modules. Call it once at the start of a command (in the begin block of a pipeline
    function), keep the token it returns, and pass the token to Complete-TcsTelemetry when the
    command ends. For commands without begin/process/end blocks, Invoke-TcsCommand does both
    in one call.

    The command, module and version are taken from the calling command when they are not
    given.

    Only the outermost run is reported. When an exported command calls another exported
    command of the same module, the inner run returns a token with IsOutermost = $false and
    sends nothing, so one user action is one event. Commands of other modules are reported
    separately.

    Telemetry never breaks the caller: if anything goes wrong, a token is still returned and
    the failure is written to the verbose stream. Nothing is sent when telemetry is turned
    off; see Invoke-TelemetryCollection.

.PARAMETER CommandName
    The name reported for the command. Defaults to the name of the calling command.

.PARAMETER ModuleName
    The module the command belongs to. Defaults to the module of the calling command.

.PARAMETER ModuleVersion
    The module version. Defaults to the version of the calling command's module.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    Tcs.TelemetryToken
    Id, CommandName, ModuleName, ModuleVersion, IsOutermost, Failed, Completed and Exception.
    Assign it to a variable so it is not written to the pipeline.

.EXAMPLE
    function Get-Widget {
        [CmdletBinding()]
        param([Parameter(ValueFromPipeline)][string]$Name)
        begin {
            $telemetry = Start-TcsTelemetry
        }
        process {
            Invoke-TcsCommand -Token $telemetry -ScriptBlock {
                Get-Item -Path $Name
            }
        }
        end {
            Complete-TcsTelemetry -Token $telemetry
        }
    }

    A pipeline function: one event is sent for the whole pipeline run. Invoke-TcsCommand
    -Token records errors in each process block; a terminating error completes the run as
    failed.

.EXAMPLE
    begin { $telemetry = Start-TcsTelemetry }
    process {
        try { Set-Thing -Name $Name -ErrorAction Stop }
        catch { Complete-TcsTelemetry -Token $telemetry -ErrorRecord $_; throw }
    }
    end { Complete-TcsTelemetry -Token $telemetry }

    Completes the run by hand, as failed when an error is caught.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

.LINK
    Complete-TcsTelemetry

.LINK
    Invoke-TcsCommand
#>
function Start-TcsTelemetry {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only starts an in-memory timer; nothing on the system is changed.')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(HelpMessage = 'Name reported for the command.')]
        [string]$CommandName,

        [Parameter(HelpMessage = 'Module the command belongs to.')]
        [string]$ModuleName,

        [Parameter(HelpMessage = 'Version of the module.')]
        [string]$ModuleVersion
    )

    $invocation = $null
    try {
        $callStack = @(Get-PSCallStack)
        if ($callStack.Count -gt 1) {
            $invocation = $callStack[1].InvocationInfo
        }
        return (New-TcsTelemetryToken -Invocation $invocation -CommandName $CommandName -ModuleName $ModuleName -ModuleVersion $ModuleVersion)
    }
    catch {
        Write-Verbose "Telemetry could not be started: $($_.Exception.Message)"
        # A token that sends nothing, so the caller's Complete-TcsTelemetry still works
        return [PSCustomObject]@{
            PSTypeName    = 'Tcs.TelemetryToken'
            Id            = [guid]::NewGuid().ToString()
            CommandName   = $CommandName
            ModuleName    = $ModuleName
            ModuleVersion = $ModuleVersion
            IsOutermost   = $false
            Failed        = $false
            Completed     = $false
            Exception     = $null
        }
    }
}
