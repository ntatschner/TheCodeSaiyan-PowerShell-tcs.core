---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Set-ModuleConfig

## SYNOPSIS
Sets or updates configuration values for a module in the tcs suite.

## SYNTAX

### ByName (Default)
```
Set-ModuleConfig [-ModuleName] <String> [-UpdateWarning <Boolean>] [-UpdateCheckIntervalHours <Int32>]
 [-Telemetry <Boolean>] [-TelemetryUri <String>] [-TelemetryApiKey <String>] [-Setting <Hashtable>] [-Reset]
 [-PassThru] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByPath
```
Set-ModuleConfig -ModuleConfigFilePath <String> [-UpdateWarning <Boolean>] [-UpdateCheckIntervalHours <Int32>]
 [-Telemetry <Boolean>] [-TelemetryUri <String>] [-TelemetryApiKey <String>] [-Setting <Hashtable>] [-Reset]
 [-PassThru] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-ModuleConfig function updates a module's settings file
(\<ApplicationData\>/PowerShell/Config/\<ModuleName\>/Module.Config.json by default).
Only the
settings you pass are changed; other settings are kept.
The file is created if it does not
exist.
The change also applies to the current session.

## EXAMPLES

### EXAMPLE 1
```
Set-ModuleConfig -ModuleName 'tcs.core' -UpdateWarning $false
```

Turns off update warnings for tcs.core.

### EXAMPLE 2
```
Set-ModuleConfig -ModuleName 'tcs.jira' -Telemetry $false
```

Turns off telemetry for tcs.jira.

### EXAMPLE 3
```
Set-ModuleConfig -ModuleName 'tcs.jira' -Setting @{ DefaultProject = 'OPS'; PageSize = 100 }
```

Changes module-specific settings that have no parameter of their own.

### EXAMPLE 4
```
Set-ModuleConfig -ModuleName 'tcs.core' -Reset -PassThru
```

Restores the defaults and returns the resulting settings.

## PARAMETERS

### -ModuleName
The name of the module to configure, for example 'tcs.core' or 'tcs.jira'.
Only letters,
digits, '.', '_' and '-' are allowed, and the name must start with a letter or digit.

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleConfigFilePath
The full path of a settings file to update, instead of resolving it from ModuleName.

```yaml
Type: String
Parameter Sets: ByPath
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateWarning
Whether to show a warning when a newer version of the module is available.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UpdateCheckIntervalHours
How often (in hours) to check the PowerShell Gallery for a newer version.
Default 24.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Telemetry
Whether anonymous usage telemetry is sent.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TelemetryUri
The HTTPS ingestion endpoint for telemetry.
An empty string clears it.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TelemetryApiKey
The API key sent to the telemetry endpoint in the X-API-Key header.
It is stored encrypted
with Protect-ConfigValue (current user) and shown as '********' in -PassThru and
Get-ModuleConfig output.
An empty string clears it.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Setting
A hashtable of settings to change, for settings that have no parameter of their own (for
example a module-specific setting from that module's Config/Module.Defaults.json).
Each
value is converted to the type of its default; a value that cannot be converted is
rejected.
A setting also passed as its own parameter (for example -Telemetry) uses the
parameter value.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Reset
Restores the settings file to the defaults before applying any other settings passed.
The
defaults include the module's own Config/Module.Defaults.json when the module is loaded or
installed.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Outputs the resulting settings as a hashtable.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
### This function does not accept pipeline input.
## OUTPUTS

### System.Collections.Hashtable
### When PassThru is specified. The telemetry API key is masked.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

## RELATED LINKS

[Get-ModuleConfig]()

