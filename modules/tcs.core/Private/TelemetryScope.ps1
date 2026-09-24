<#
.SYNOPSIS
    Internal helpers for Start-TcsTelemetry, Complete-TcsTelemetry and Invoke-TcsCommand.

.DESCRIPTION
    Each command run gets a token. Only the outermost run of a module is reported: when an
    exported command calls another exported command of the same module, the inner run gets a
    token with IsOutermost = $false and sends nothing.

    A run counts as nested when a run of the same module that has not completed is still on
    the call stack. Checking the call stack (rather than keeping a counter) means a run that
    never completed, for example because a downstream Select-Object -First stopped the
    pipeline, cannot hide later runs.

.NOTES
    Private helpers for the tcs.core module.
#>

# Runs that have started and not completed, per module: list of @{ Token; Invocation }
$script:ActiveTelemetryRuns = @{}

function New-TcsTelemetryToken {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only creates an in-memory object.')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowNull()]
        [System.Management.Automation.InvocationInfo]$Invocation,

        [string]$CommandName,

        [string]$ModuleName,

        [string]$ModuleVersion
    )

    $command = $null
    if ($Invocation) {
        $command = $Invocation.MyCommand
    }
    if ([string]::IsNullOrEmpty($CommandName)) {
        $CommandName = if ($command -and $command.Name) { [string]$command.Name } else { 'UnknownCommand' }
    }
    if ([string]::IsNullOrEmpty($ModuleName)) {
        $ModuleName = if ($command -and $command.Module) { [string]$command.Module.Name } else { 'UnknownModule' }
    }
    if ([string]::IsNullOrEmpty($ModuleVersion)) {
        $ModuleVersion = if ($command -and $command.Module -and $command.Module.Version) { [string]$command.Module.Version } else { 'Unknown' }
    }

    $runs = $script:ActiveTelemetryRuns[$ModuleName]
    if (-not $runs) {
        $runs = New-Object System.Collections.Generic.List[object]
        $script:ActiveTelemetryRuns[$ModuleName] = $runs
    }

    $isOutermost = $true
    if ($runs.Count -gt 0) {
        $frames = @(Get-PSCallStack)
        foreach ($run in $runs) {
            foreach ($frame in $frames) {
                if ($null -ne $frame.InvocationInfo -and [object]::ReferenceEquals($frame.InvocationInfo, $run.Invocation)) {
                    $isOutermost = $false
                    break
                }
            }
            if (-not $isOutermost) {
                break
            }
        }
    }

    $token = [PSCustomObject]@{
        PSTypeName    = 'Tcs.TelemetryToken'
        Id            = [guid]::NewGuid().ToString()
        CommandName   = $CommandName
        ModuleName    = $ModuleName
        ModuleVersion = $ModuleVersion
        IsOutermost   = $isOutermost
        Failed        = $false
        Completed     = $false
        Exception     = $null
    }

    if ($isOutermost) {
        # Runs that never completed are kept (they cannot cause false nesting), but not forever
        while ($runs.Count -ge 100) {
            $runs.RemoveAt(0)
        }
        $runs.Add(@{ Token = $token; Invocation = $Invocation })
        Invoke-TelemetryCollection -ModuleName $ModuleName -ModuleVersion $ModuleVersion -CommandName $CommandName -ExecutionID $token.Id -Stage Start -ClearTimer
    }
    return $token
}

function Set-TcsTelemetryFailure {
    <#
    .SYNOPSIS
        Marks a run as failed and remembers the first error, whose type is reported.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only changes an in-memory object.')]
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('Tcs.TelemetryToken')]
        [PSCustomObject]$Token,

        [AllowNull()]
        [object]$ErrorRecord
    )

    $Token.Failed = $true
    if ($null -eq $ErrorRecord -or $null -ne $Token.Exception) {
        return
    }
    $exception = if ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) { $ErrorRecord.Exception } else { $ErrorRecord }
    if ($exception -is [System.Exception]) {
        $Token.Exception = $exception
    }
}

function Complete-TcsTelemetryToken {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSTypeName('Tcs.TelemetryToken')]
        [PSCustomObject]$Token
    )

    if ($Token.Completed) {
        return
    }
    $Token.Completed = $true

    $runs = $script:ActiveTelemetryRuns[$Token.ModuleName]
    if ($runs) {
        for ($i = $runs.Count - 1; $i -ge 0; $i--) {
            if ([object]::ReferenceEquals($runs[$i].Token, $Token)) {
                $runs.RemoveAt($i)
            }
        }
    }

    if ($Token.IsOutermost) {
        Invoke-TelemetryCollection -ModuleName $Token.ModuleName -ModuleVersion $Token.ModuleVersion -CommandName $Token.CommandName -ExecutionID $Token.Id -Stage End -Failed ([bool]$Token.Failed) -Exception $Token.Exception
    }
}

function Invoke-TcsScriptBlock {
    <#
    .SYNOPSIS
        Runs a script block in the scope it was written in (dot-sourced), so its variables
        persist, as if it were written inline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    . $ScriptBlock
}
