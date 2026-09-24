---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Get-ModuleConfig

## SYNOPSIS
Retrieves the configuration for a PowerShell module in the tcs suite.

## SYNTAX

```
Get-ModuleConfig [[-CommandPath] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-ModuleConfig function finds the module that owns CommandPath (by walking up to the
nearest module manifest) and returns its configuration as a hashtable.

The configuration is built from:
  1.
The tcs.core defaults (Config/Module.Defaults.json in tcs.core).
  2.
The calling module's own Config/Module.Defaults.json, if it has one.
  3.
The user's settings file:
     \<ApplicationData\>/PowerShell/Config/\<ModuleName\>/Module.Config.json
     (the TCS_CONFIG_ROOT environment variable overrides the root folder).

The settings file is created with the defaults the first time a module is loaded so users
can edit it.
After that it is only read; change settings with Set-ModuleConfig.

A value that cannot be read as the type of its default, or that is out of range (for
example UpdateCheckIntervalHours below 1), is replaced by the default for that setting
only; the other settings in the file are still used.

The returned hashtable also contains ModuleName, ModulePath, ModuleVersion,
ModuleConfigPath and ModuleConfigFilePath.
The telemetry API key, if one is set, is shown
as '********'.

## EXAMPLES

### EXAMPLE 1
```
$config = Get-ModuleConfig -CommandPath $PSCommandPath
```

Retrieves the configuration for the module that contains the calling script.

### EXAMPLE 2
```
if ((Get-ModuleConfig).UpdateWarning) { 'Update warnings are on' }
```

Uses the calling script's path automatically.

## PARAMETERS

### -CommandPath
The path of the calling script or module file, normally $PSCommandPath.
When omitted, the
path of the calling script is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

If the settings file cannot be written (for example a read-only profile), defaults are
used for the session and a verbose message is written.

## RELATED LINKS

[Set-ModuleConfig]()

