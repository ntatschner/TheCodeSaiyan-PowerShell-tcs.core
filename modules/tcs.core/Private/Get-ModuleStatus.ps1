<#
.SYNOPSIS
    Checks the status of a PowerShell module and optionally displays update notifications.

.DESCRIPTION
    The Get-ModuleStatus function compares the currently installed version of a module
    with the latest version available in the PowerShell Gallery. It always returns a
    structured PSCustomObject with version information. When the ShowMessage parameter
    is specified, it also displays a warning message if an update is available.
    This function is typically called during module import to notify users of available updates.

.PARAMETER ShowMessage
    Switch parameter that determines whether to display update notification messages.
    When specified, the function will show a warning if a newer version is available.

.PARAMETER ModuleName
    The name of the module to check for updates. This must match the module name
    as it appears in the PowerShell Gallery.

.PARAMETER ModulePath
    The local file system path where the module is installed. This is used to
    locate the module manifest file (.psd1) to determine the current version.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    PSCustomObject
    Returns a PSCustomObject with ModuleName, CurrentVersion, LatestVersion, and
    UpdateAvailable properties. May also display warning messages when ShowMessage
    is specified and updates are available.

.EXAMPLE
    Get-ModuleStatus -ModuleName "tcs.core" -ModulePath "C:\Modules\tcs.core" -ShowMessage
    
    Checks for updates to the tcs.core module, displays a message if an update is available,
    and returns a status object.

.EXAMPLE
    $status = Get-ModuleStatus -ModuleName "MyModule" -ModulePath $ModulePath
    if ($status.UpdateAvailable) { Write-Host "Update available!" }
    
    Checks the module status and uses the returned object to determine if an update is available.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0
    
    This is a private function used internally by the tcs.core module for update
    checking. It gracefully handles errors and will not interrupt module loading
    if the PowerShell Gallery is unavailable or if network issues occur.
#>
function Get-ModuleStatus {
    [OutputType([PSCustomObject])]
    param (
        [switch]$ShowMessage,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string]$ModulePath
    )
    try {
        $PSD1File = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
        $CurrentlyLoadedModuleVersion = [version](Import-PowerShellDataFile -Path $PSD1File).ModuleVersion
        $LatestModuleVersion = [version](Find-PSResource -Name $ModuleName).Version
        if ($ShowMessage -and ($CurrentlyLoadedModuleVersion -lt $LatestModuleVersion)) {
            Write-Host -ForegroundColor Yellow "An update is available for the module '$ModuleName'. Installed version: $CurrentlyLoadedModuleVersion, Latest version: $LatestModuleVersion.`nPlease run 'Update-Module $ModuleName' to update the module."
        }
        [PSCustomObject]@{
            ModuleName      = $ModuleName
            CurrentVersion  = $CurrentlyLoadedModuleVersion
            LatestVersion   = $LatestModuleVersion
            UpdateAvailable = $CurrentlyLoadedModuleVersion -lt $LatestModuleVersion
        }
    }
    catch {
        return
    }
}
