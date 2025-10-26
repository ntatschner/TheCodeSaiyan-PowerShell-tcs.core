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
    Valid values are 'True' or 'False'. When set to 'True', the module will check for
    updates and display notifications to users.

.PARAMETER ModuleName
    The name of the module for which the configuration is being set. This is used for
    identification and logging purposes.

.PARAMETER ModuleConfigFilePath
    The full path to the module configuration JSON file. If the file doesn't exist,
    it will be created automatically.

.PARAMETER ModuleConfigPath
    The directory path where the module configuration file is located.

.PARAMETER ModulePath
    The root path of the module installation directory.

.PARAMETER BasicTelemetry
    Switch parameter that enables or disables basic telemetry collection for the module.
    When specified, basic usage telemetry will be collected according to privacy settings.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    None
    This function does not return any output. It modifies the configuration file directly.

.EXAMPLE
    Set-ModuleConfig -UpdateWarning "True" -ModuleName "tcs.core"
    
    Enables update warnings for the tcs.core module.

.EXAMPLE
    Set-ModuleConfig -UpdateWarning "False" -BasicTelemetry -ModuleName "MyModule" -ModuleConfigFilePath "C:\Config\MyModule.json"
    
    Disables update warnings, enables basic telemetry, and sets the configuration file path for MyModule.

.EXAMPLE
    Set-ModuleConfig -ModuleName "tcs.core" -ModulePath "C:\Modules\tcs.core" -ModuleConfigPath "C:\Config"
    
    Sets the module and configuration paths for the tcs.core module.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.1.7
    
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
    [CmdletBinding(HelpUri = 'https://PENDINGHOST/tcs.core/docs/Set-ModuleConfig.html')]
    param(
        [Parameter(HelpMessage = "Determines if the update message is displayed when the module is loaded.")]
        [ValidateSet('True', 'False')]
        [string]$UpdateWarning,
    
        [Parameter(HelpMessage = "Name of the module the configurationis being set for.")]
        [string]$ModuleName,

        [Parameter(HelpMessage = "Path of the module config.")]
        [string]$ModuleConfigFilePath,

        [Parameter(HelpMessage = "Path of the module.")]
        [string]$ModuleConfigPath,

        [Parameter(HelpMessage = "Path of the module.")]
        [string]$ModulePath,

        [switch]$BasicTelemetry
    )

    # Test to see if module config JSON exists and create it if it doesn't
    if (-not (Test-Path -Path $ModuleConfigFilePath)) {
        New-Item -Path $ModuleConfigFilePath -ItemType File -Force -Confirm:$false | Out-Null
        $NewConfig = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters
        $NewConfig | ConvertTo-Json | Set-Content -Path $ModuleConfigFilePath -Force -Confirm:$false
    }
    else {
        # Read the module config JSON
        $Config = (Get-Content -Path $ModuleConfigFilePath | ConvertFrom-Json)
        $ConfigHashTable = @{}
        $Config.PSObject.Properties | ForEach-Object { $ConfigHashTable[$_.Name] = $_.Value }
        # Update or add new values to the module config JSON
        $NewConfig = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters
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
    }
}
