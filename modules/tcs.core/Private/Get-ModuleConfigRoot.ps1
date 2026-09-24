<#
.SYNOPSIS
    Returns the root directory used for per-user tcs module configuration.

.DESCRIPTION
    Resolves the directory that holds per-module configuration folders. The TCS_CONFIG_ROOT
    environment variable overrides the default, which is
    '<ApplicationData>/PowerShell/Config' ('%APPDATA%' on Windows, '~/.config' on Linux/macOS).

.OUTPUTS
    System.String

.NOTES
    Private helper for the tcs.core module.
#>
function Get-ModuleConfigRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if (-not [string]::IsNullOrWhiteSpace($env:TCS_CONFIG_ROOT)) {
        return $env:TCS_CONFIG_ROOT
    }

    $appData = [Environment]::GetFolderPath('ApplicationData')
    if ([string]::IsNullOrWhiteSpace($appData)) {
        # Service accounts and some containers have no profile folder
        $appData = [System.IO.Path]::GetTempPath()
    }
    return (Join-Path -Path (Join-Path -Path $appData -ChildPath 'PowerShell') -ChildPath 'Config')
}
