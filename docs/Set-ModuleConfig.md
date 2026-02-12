---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Set-ModuleConfig

## SYNOPSIS
Sets or updates configuration values for a PowerShell module.

## SYNTAX

```
Set-ModuleConfig [[-UpdateWarning] <Boolean>] [[-ModuleName] <String>] [-ModuleConfigFilePath] <String>
 [[-ModuleConfigPath] <String>] [[-ModulePath] <String>] [-BasicTelemetry] [-Reset] [-PassThru]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Set-ModuleConfig function manages module configuration by creating or updating a JSON
configuration file.
It handles various module settings including update warnings, telemetry
options, and module path information.
If the configuration file doesn't exist, it creates
a new one with the specified values.
If it exists, it updates the existing configuration
with new or changed values while preserving existing settings.

## EXAMPLES

### EXAMPLE 1
```
Set-ModuleConfig -UpdateWarning $true -ModuleName "tcs.core" -ModuleConfigFilePath "C:\Config\Module.Config.json"
```

Enables update warnings for the tcs.core module.

### EXAMPLE 2
```
Set-ModuleConfig -UpdateWarning $false -BasicTelemetry -ModuleName "MyModule" -ModuleConfigFilePath "C:\Config\MyModule.json"
```

Disables update warnings, enables basic telemetry, and sets the configuration file path for MyModule.

### EXAMPLE 3
```
Set-ModuleConfig -ModuleConfigFilePath "C:\Config\Module.Config.json" -Reset
```

Resets the module configuration to default values.

### EXAMPLE 4
```
$config = Set-ModuleConfig -ModuleName "tcs.core" -ModuleConfigFilePath "C:\Config\Module.Config.json" -PassThru
```

Sets the configuration and returns the resulting hashtable.

## PARAMETERS

### -UpdateWarning
Determines whether update warning messages are displayed when the module is loaded.
When set to $true, the module will check for updates and display notifications to users.

```yaml
Type:Boolean
Parameter Sets:   (All)
Aliases:
Required: False
Position: 1Default
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ModuleName
The name of the module for which the configuration is being set.
This is used for
identification and logging purposes.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 2Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ModuleConfigFilePath
The full path to the module configuration JSON file.
This parameter is mandatory.
If the file doesn't exist, it will be created automatically.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 3Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ModuleConfigPath
The directory path where the module configuration file is located.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 4Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ModulePath
The root path of the module installation directory.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 5Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -BasicTelemetry
Switch parameter that enables or disables basic telemetry collection for the module.
When specified, basic usage telemetry will be collected according to privacy settings.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Reset
Switch parameter that restores the configuration to default values from the module's
Config/Module.Defaults.json file.
When specified, the current configuration is replaced
with default values.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -PassThru
Switch parameter that outputs the final configuration hashtable after writing.
When specified, the function returns the resulting configuration as a hashtable.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type:ActionPreference
Parameter Sets:   (All)
Aliases:proga
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
### This function does not accept pipeline input.
## OUTPUTS

### System.Collections.Hashtable
### When PassThru is specified, returns a hashtable containing the final configuration.
### Otherwise, this function does not return any output.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This function is part of the tcs.core module configuration management system.
The configuration is stored in JSON format for easy reading and modification.

Configuration files are created with appropriate permissions and will be
force-created if they don't exist.
Existing configurations are merged with
new values, preserving settings that aren't being changed.

## RELATED LINKS

[Get-ModuleConfig]()

[Get-ModuleStatus]()

