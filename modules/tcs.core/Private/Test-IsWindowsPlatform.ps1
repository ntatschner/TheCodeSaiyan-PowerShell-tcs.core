<#
.SYNOPSIS
    Returns $true when running on Windows (Windows PowerShell or PowerShell 7 on Windows).

.OUTPUTS
    System.Boolean

.NOTES
    Private helper for the tcs.core module. $IsWindows does not exist in Windows PowerShell 5.1.
#>
function Test-IsWindowsPlatform {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows -eq $true)
}
