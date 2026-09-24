<#
.SYNOPSIS
    Internal helpers for running script blocks while watching the errors they write
    (Invoke-TcsCommand and Invoke-WithRetry -RetryOnNonTerminatingError).

.NOTES
    Private helper for the tcs.core module.
#>
function Invoke-ScriptBlockInChildScope {
    <#
    .SYNOPSIS
        Runs a script block like '& $ScriptBlock'. Being an advanced function, it lets the
        caller see the errors the script block writes with -ErrorVariable.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    & $ScriptBlock
}

function Test-NativeCommandErrorRecord {
    <#
    .SYNOPSIS
        Returns $true for an ErrorRecord that holds a line a native program wrote to stderr.
        Such lines are captured as ErrorRecords when the error stream is redirected; they are
        not PowerShell errors and must not count as failures.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()]
        [object]$ErrorRecord
    )

    return ($ErrorRecord -is [System.Management.Automation.ErrorRecord] -and
        [string]$ErrorRecord.FullyQualifiedErrorId -like 'NativeCommandError*')
}
