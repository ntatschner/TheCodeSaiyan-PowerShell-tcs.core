<#
.SYNOPSIS
    Sets or updates configuration values for a PowerShell module.

.DESCRIPTION
    The Set-ModuleConfig function manages module configuration by creating or updating a JSON
    configuration file. It handles various module settings including update warnings, telemetry
    options, and module path information. If the configuration file doesn't exist, it creates
    a new one with the specified values. If it exists, it updates the existing configuration
    with new or changed values while preserving existing settings.

.PARAMETER UpdateWarning
    Determines whether update warning messages are displayed when the module is loaded.
    When set to $true, the module will check for updates and display notifications to users.

.PARAMETER ModuleName
    The name of the module for which the configuration is being set. This is used for
    identification and logging purposes.

.PARAMETER ModuleConfigFilePath
    The full path to the module configuration JSON file. This parameter is mandatory.
    If the file doesn't exist, it will be created automatically.

.PARAMETER ModuleConfigPath
    The directory path where the module configuration file is located.

.PARAMETER ModulePath
    The root path of the module installation directory.

.PARAMETER BasicTelemetry
    Switch parameter that enables or disables basic telemetry collection for the module.
    When specified, basic usage telemetry will be collected according to privacy settings.

.PARAMETER Reset
    Switch parameter that restores the configuration to default values from the module's
    Config/Module.Defaults.json file. When specified, the current configuration is replaced
    with default values.

.PARAMETER PassThru
    Switch parameter that outputs the final configuration hashtable after writing.
    When specified, the function returns the resulting configuration as a hashtable.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Collections.Hashtable
    When PassThru is specified, returns a hashtable containing the final configuration.
    Otherwise, this function does not return any output.

.EXAMPLE
    Set-ModuleConfig -UpdateWarning $true -ModuleName "tcs.core" -ModuleConfigFilePath "C:\Config\Module.Config.json"
    
    Enables update warnings for the tcs.core module.

.EXAMPLE
    Set-ModuleConfig -UpdateWarning $false -BasicTelemetry -ModuleName "MyModule" -ModuleConfigFilePath "C:\Config\MyModule.json"
    
    Disables update warnings, enables basic telemetry, and sets the configuration file path for MyModule.

.EXAMPLE
    Set-ModuleConfig -ModuleConfigFilePath "C:\Config\Module.Config.json" -Reset
    
    Resets the module configuration to default values.

.EXAMPLE
    $config = Set-ModuleConfig -ModuleName "tcs.core" -ModuleConfigFilePath "C:\Config\Module.Config.json" -PassThru
    
    Sets the configuration and returns the resulting hashtable.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0
    
    This function is part of the tcs.core module configuration management system.
    The configuration is stored in JSON format for easy reading and modification.
    
    Configuration files are created with appropriate permissions and will be
    force-created if they don't exist. Existing configurations are merged with
    new values, preserving settings that aren't being changed.

.LINK
    Get-ModuleConfig

.LINK
    Get-ModuleStatus
#>
function Set-ModuleConfig {
    [CmdletBinding(HelpUri = 'https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/')]
    [OutputType([hashtable])]
    param(
        [Parameter(HelpMessage = "Determines if the update message is displayed when the module is loaded.")]
        [bool]$UpdateWarning,
    
        [Parameter(HelpMessage = "Name of the module the configuration is being set for.")]
        [string]$ModuleName,

        [Parameter(Mandatory, HelpMessage = "Path of the module config file.")]
        [string]$ModuleConfigFilePath,

        [Parameter(HelpMessage = "Path of the module config directory.")]
        [string]$ModuleConfigPath,

        [Parameter(HelpMessage = "Path of the module.")]
        [string]$ModulePath,

        [switch]$BasicTelemetry,

        [Parameter(HelpMessage = "Restores configuration to default values.")]
        [switch]$Reset,

        [Parameter(HelpMessage = "Outputs the final configuration hashtable.")]
        [switch]$PassThru
    )

    if ($Reset) {
        $ConfigDefaultsPath = Join-Path -Path $(Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Config\Module.Defaults.json"
        $DefaultConfig = Get-Content -Path $ConfigDefaultsPath | ConvertFrom-Json
        $ConfigHashTable = @{}
        $DefaultConfig.PSObject.Properties | ForEach-Object { $ConfigHashTable[$_.Name] = $_.Value }
        $ConfigHashTable | ConvertTo-Json | Set-Content -Path $ModuleConfigFilePath -Force -Confirm:$false
        if ($PassThru) {
            $ConfigHashTable
        }
        return
    }

    # Test to see if module config JSON exists and create it if it doesn't
    if (-not (Test-Path -Path $ModuleConfigFilePath)) {
        New-Item -Path $ModuleConfigFilePath -ItemType File -Force -Confirm:$false | Out-Null
        $NewConfig = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters -Exclude @('Reset', 'PassThru')
        $NewConfig | ConvertTo-Json | Set-Content -Path $ModuleConfigFilePath -Force -Confirm:$false
        if ($PassThru) {
            $NewConfig
        }
    }
    else {
        # Read the module config JSON
        $Config = (Get-Content -Path $ModuleConfigFilePath | ConvertFrom-Json)
        $ConfigHashTable = @{}
        $Config.PSObject.Properties | ForEach-Object { $ConfigHashTable[$_.Name] = $_.Value }
        # Update or add new values to the module config JSON
        $NewConfig = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters -Exclude @('Reset', 'PassThru')
        Write-Verbose "Updating module config with the following values: $NewConfig"
        $NewConfig.GetEnumerator() | ForEach-Object {
            $Key = $_.Key
            $Value = $_.Value
            if ($ConfigHashTable.ContainsKey($Key)) {
                $ConfigHashTable[$Key] = $Value
            }
            else {
                $ConfigHashTable.Add($Key, $Value)
            }
        }
        $ConfigHashTable | ConvertTo-Json | Set-Content -Path $ModuleConfigFilePath -Force -Confirm:$false
        if ($PassThru) {
            $ConfigHashTable
        }
    }
}
