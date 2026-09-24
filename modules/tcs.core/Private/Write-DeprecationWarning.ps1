<#
.SYNOPSIS
    Writes a deprecation warning once per session for each deprecated feature.

.NOTES
    Private helper for the tcs.core module.
#>

$script:DeprecationWarningsShown = @{}

function Write-DeprecationWarning {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Feature,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if ($script:DeprecationWarningsShown.ContainsKey($Feature)) {
        return
    }
    $script:DeprecationWarningsShown[$Feature] = $true
    Write-Warning "$Feature is deprecated and will be removed in tcs.core 1.0. $Message"
}
