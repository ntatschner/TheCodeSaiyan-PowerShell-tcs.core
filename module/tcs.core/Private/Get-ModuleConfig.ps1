<#
.SYNOPSIS
    Retrieves the configuration for a PowerShell module.

.DESCRIPTION
    The Get-ModuleConfig function loads and returns the configuration for a PowerShell module.
    It automatically discovers the module path by traversing up from the command path to find
    the module manifest file (.psd1). The function manages both default configuration values
    and user-specific configuration overrides stored in a JSON file.

.PARAMETER CommandPath
    The path to the command or script file from which to determine the module location.
    This is typically passed as $PSCommandPath from the calling module.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Collections.Hashtable
    Returns a hashtable containing the module configuration settings including module name,
    version, paths, and user-configured options.

.EXAMPLE
    $config = Get-ModuleConfig -CommandPath $PSCommandPath
    
    Retrieves the configuration for the current module.

.EXAMPLE
    $config = Get-ModuleConfig -CommandPath "C:\Modules\MyModule\MyModule.psm1"
    
    Retrieves the configuration for a module at a specific path.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.1.7
    
    This is a private function used internally by the tcs.core module for configuration
    management. It handles automatic creation of configuration files with default values
    and maintains version tracking for module updates.
#>
function Get-ModuleConfig {
    [OutputType([hashtable])]

    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $CommandPath
    )
    try {
        Write-Verbose "CommandPath: $CommandPath"
        $BaseCommandPath = Split-Path -Path $CommandPath -Parent
        Write-Verbose "Initial BaseCommandPath: $BaseCommandPath"
        # Recursively step back through the CommandPath to find the module path that contains the module manifest file and get the module base path and module name
        while (-not (Get-ChildItem -Path $BaseCommandPath -Filter *.psd1)) {
            $ParentPath = Split-Path -Path $BaseCommandPath -Parent
            Write-Verbose "ParentPath: $ParentPath"
            if ($ParentPath -eq $BaseCommandPath) {
                Write-Verbose "ParentPath: $ParentPath is the same as BaseCommandPath: $BaseCommandPath"
                # Break the loop if the parent path is the same as the current path,
                # indicating that we've reached the root directory
                break
            }
            $BaseCommandPath = $ParentPath
            Write-Verbose "Recursive BaseCommandPath: $BaseCommandPath"
        }
        $ModuleFilePath = Join-Path -Path $BaseCommandPath -ChildPath $(Split-Path -Path $(Get-ChildItem -Path $BaseCommandPath -Filter *.psd1 | Select-Object -First 1) -Leaf)
        Write-Verbose "ModuleFilePath: $ModuleFilePath"
        $ModuleVersion = (Import-PowerShellDataFile -Path $($ModuleFilePath.Replace('.psm1','.psd1'))).ModuleVersion
        $ModulePath = Split-Path -Path $ModuleFilePath -Parent
        if ([string]::IsNullOrEmpty($ModulePath)) {
            Write-Error "ModulePath is empty or null."
            throw
        }
        Write-Verbose "ModulePath: $ModulePath"
        $ModuleName = Get-ChildItem -Path $ModuleFilePath -Filter "*.psd1" -File | Select-Object -First 1 | Select-Object -ExpandProperty BaseName
        Write-Verbose "ModuleName: $ModuleName"
        $UserPowerShellModuleConfigPath = Join-Path -Path $(Split-Path -Path $($env:PSModulePath -split ';' | ForEach-Object { if (($_ -match $([regex]::Escape($env:USERNAME))) -and ($_ -notmatch '\.')) { $_ } }) -Parent) -ChildPath 'Config'
        Write-Verbose "UserPowerShellModuleConfigPath: $UserPowerShellModuleConfigPath"
        $ModuleConfigPath = Join-Path -Path $UserPowerShellModuleConfigPath -ChildPath $ModuleName
        Write-Verbose "ModuleConfigPath: $ModuleConfigPath"
        $ModuleConfigFilePath = Join-Path -Path $ModuleConfigPath -ChildPath 'Module.Config.json'
        Write-Verbose "ModuleConfigFilePath: $ModuleConfigFilePath"
        $ConfigDefaultsPath = Join-Path -Path $(Split-Path -Path $PSScriptRoot -Parent) -ChildPath "\Config\Module.Defaults.json"
        Write-Verbose "ConfigDefaultsPath: $ConfigDefaultsPath"
        $DefaultConfig = Get-Content -Path $ConfigDefaultsPath | ConvertFrom-Json
        Write-Verbose "DefaultConfig: $DefaultConfig"
    }
    catch {
        Write-Error "CommandPath: $($CommandPath)`nError: `n$($_)`n Invocation $($_.InvocationInfo.ScriptLineNumber) $($_.InvocationInfo.ScriptName)"
        return
    }
    # Test to see if module config JSON exists and create it if it doesn't
    if (-not (Test-Path -Path $ModuleConfigFilePath)) {
        $HashTable = @{}
        $DefaultConfig.PSObject.Properties | ForEach-Object { $HashTable[$_.Name] = $_.Value }
        $HashTable.Add('ModuleName', $ModuleName)
        $HashTable.Add('ModulePath', $ModulePath)
        $HashTable.Add('ModuleVersion', $ModuleVersion)
        $HashTable.Add('ModuleConfigPath', $ModuleConfigPath)
        $HashTable.Add('ModuleConfigFilePath', $ModuleConfigFilePath)
        New-Item -Path $ModuleConfigFilePath -ItemType File -Value $($HashTable | ConvertTo-Json) -Force -Confirm:$false
    }
    else {
        $Config = Get-Content -Path $ModuleConfigFilePath | ConvertFrom-Json
        $DefaultConfig.PSObject.Properties | ForEach-Object {
            if ($Config.PSObject.Properties.Name -notcontains $_.Name) {
                $Config | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value
            }
        }
        # Update Module Path if it has changed
        $CurrentlyLoadedModuleVersion = (Import-PowerShellDataFile -Path $($ModuleFilePath.Replace('.psm1','.psd1'))).ModuleVersion
        if ($Config.ModuleVersion -ne $CurrentlyLoadedModuleVersion) {
            $Config.ModuleVersion = $CurrentlyLoadedModuleVersion
            $Config | ConvertTo-Json | Set-Content -Path $ModuleConfigFilePath -Force -Confirm:$false
            $Config = Get-Content -Path $ModuleConfigFilePath | ConvertFrom-Json
        }
        if ($Config.ModulePath -ne $ModulePath) {
            $Config.ModulePath = $ModulePath
            $Config | ConvertTo-Json | Set-Content -Path $ModuleConfigFilePath -Force -Confirm:$false
            $Config = Get-Content -Path $ModuleConfigFilePath | ConvertFrom-Json
        }
        $HashTable = @{}
        $Config.PSObject.Properties | ForEach-Object { $HashTable[$_.Name] = $_.Value }
        $HashTable
    }
}
