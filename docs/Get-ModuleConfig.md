---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# Get-ModuleConfig

## SYNOPSIS
Retrieves the configuration for a PowerShell module.

## SYNTAX

```
Get-ModuleConfig [-CommandPath] <Object> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-ModuleConfig function loads and returns the configuration for a PowerShell module.
It automatically discovers the module path by traversing up from the command path to find
the module manifest file (.psd1).
The function manages both default configuration values
and user-specific configuration overrides stored in a JSON file.

## EXAMPLES

### EXAMPLE 1
```
$config = Get-ModuleConfig -CommandPath $PSCommandPath
```

Retrieves the configuration for the current module.

### EXAMPLE 2
```
$config = Get-ModuleConfig -CommandPath "C:\Modules\MyModule\MyModule.psm1"
```

Retrieves the configuration for a module at a specific path.

## PARAMETERS

### -CommandPath
The path to the command or script file from which to determine the module location.
This is typically passed as $PSCommandPath from the calling module.

```yaml
Type:Object
Parameter Sets:   (All)
Aliases:
Required: True
Position: 1Default
Default value: None
Default value: None
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
### Returns a hashtable containing the module configuration settings including module name,
### version, paths, and user-configured options.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This is a private function used internally by the tcs.core module for configuration
management.
It handles automatic creation of configuration files with default values
and maintains version tracking for module updates.

## RELATED LINKS
