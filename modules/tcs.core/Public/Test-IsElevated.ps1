<#
.SYNOPSIS
    Tests whether the current PowerShell session is running with elevated (administrator/root) privileges.

.DESCRIPTION
    The Test-IsElevated function checks if the current session has elevated privileges.
    On Windows, it verifies membership in the built-in Administrator role. On Linux and
    macOS, it checks whether the effective user ID is 0 (root). This is useful for
    gating operations that require administrative access.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Boolean
    Returns $true if the session is elevated/running as administrator or root, $false otherwise.

.EXAMPLE
    Test-IsElevated

    Returns $true if the current session is running as Administrator (Windows) or root (Linux/macOS).

.EXAMPLE
    if (Test-IsElevated) { Write-Output "Running elevated" } else { Write-Output "Not elevated" }

    Conditionally executes logic based on whether the session is elevated.

.EXAMPLE
    $elevated = Test-IsElevated
    Write-Output "Elevated: $elevated"

    Stores the elevation status in a variable for later use.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

    This function is part of the tcs.core module and provides a cross-platform way to
    check for elevated privileges in PowerShell 7+ environments.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function Test-IsElevated {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($IsWindows -or ($PSVersionTable.PSEdition -eq 'Desktop')) {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else {
        # Linux / macOS
        return ($(id -u) -eq 0)
    }
}
