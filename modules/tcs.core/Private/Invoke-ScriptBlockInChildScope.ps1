<#
.SYNOPSIS
    Internal helper for Invoke-WithRetry -RetryOnNonTerminatingError.

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
