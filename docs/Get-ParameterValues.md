---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# Get-ParameterValues

## SYNOPSIS
Extracts and filters parameter values from PSBoundParameters.

## SYNTAX

```
Get-ParameterValues [-PSBoundParametersHash] <Hashtable> [[-Exclude] <String[]>] [[-Include] <String[]>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-ParameterValues function processes the PSBoundParameters hashtable to extract
meaningful parameter values while filtering out common PowerShell automatic variables
and system parameters.
This is useful for configuration management and parameter
processing where only user-specified values are needed.

## EXAMPLES

### EXAMPLE 1
```
function Test-Function {
    [CmdletBinding()]
    param($Name, $Value, $Path)
    $params = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters
    return $params
}
```

Extracts only the user-provided parameters from the function call.

### EXAMPLE 2
```
$filteredParams = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters -Exclude @('TempPath')
```

Extracts parameters while excluding 'TempPath' in addition to the default exclusions.

### EXAMPLE 3
```
$filteredParams = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters -Include @('Name', 'Value')
```

Extracts only the 'Name' and 'Value' parameters, ignoring all others.

## PARAMETERS

### -PSBoundParametersHash
The PSBoundParameters hashtable from a PowerShell function, containing all parameters
that were explicitly provided by the caller.

```yaml
Type:Hashtable
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

### -Exclude
An array of parameter names to exclude from the output.
This is combined with a default
set of common PowerShell automatic variables like 'Verbose', 'Debug', 'ErrorAction', etc.

```yaml
Type: String[]
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

### -Include
An array of parameter names to include in the output.
When provided, only keys in this
list are returned (still excluding nulls and common parameters).
When not provided,
all non-excluded parameters are returned.

```yaml
Type: String[]
Parameter Sets:   (All)
Aliases:
Required: False
Position: 3Default
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
### Returns a hashtable containing only the filtered parameter values with null values
### and excluded parameters removed.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This is a private function used internally by the tcs.core module for parameter
processing and configuration management.
It automatically excludes common PowerShell
system parameters to provide clean parameter sets for further processing.

## RELATED LINKS
