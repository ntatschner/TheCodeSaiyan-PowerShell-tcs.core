<#
.SYNOPSIS
    Checks the status of a PowerShell module and optionally displays update notifications.

.DESCRIPTION
    The Get-ModuleStatus function compares the currently installed version of a module
    with the latest version available in the PowerShell Gallery. When the ShowMessage
    parameter is specified, it displays a warning message if an update is available.
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
    None
    This function does not return any output. It may display warning messages
    when ShowMessage is specified and updates are available.

.EXAMPLE
    Get-ModuleStatus -ModuleName "tcs.core" -ModulePath "C:\Modules\tcs.core" -ShowMessage
    
    Checks for updates to the tcs.core module and displays a message if an update is available.

.EXAMPLE
    Get-ModuleStatus -ModuleName "MyModule" -ModulePath $ModulePath
    
    Checks the module status without displaying any messages.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.1.7
    
    This is a private function used internally by the tcs.core module for update
    checking. It gracefully handles errors and will not interrupt module loading
    if the PowerShell Gallery is unavailable or if network issues occur.
#>
function Get-ModuleStatus {
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
        # Get the current version of the installed module and check against the latest version in PSGallery, then notify the user as a warning message that an update is availible.
        $PSD1File = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
        if ($ShowMessage) {
            $CurrentlyLoadedModuleVersion = (Import-PowerShellDataFile -Path $PSD1File).ModuleVersion
            $LatestModuleVersion = (Find-PSResource -Name $ModuleName).Version
            if ($CurrentlyLoadedModuleVersion -lt $LatestModuleVersion) {
                Write-Host -ForegroundColor Yellow "An update is available for the module '$ModuleName'. Installed version: $CurrentlyLoadedModuleVersion, Latest version: $LatestModuleVersion.`nPlease run 'Update-Module $ModuleName' to update the module."
            }
            return
        }
        else {
            return
        }
    }
    catch {
        return
    }
}
