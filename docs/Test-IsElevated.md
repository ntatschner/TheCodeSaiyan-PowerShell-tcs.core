---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# Test-IsElevated

## SYNOPSIS
Tests whether the current PowerShell session is running with elevated (administrator/root) privileges.

## SYNTAX

```
Test-IsElevated [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Test-IsElevated function checks if the current session has elevated privileges.
On Windows, it verifies membership in the built-in Administrator role.
On Linux and
macOS, it checks whether the effective user ID is 0 (root).
This is useful for
gating operations that require administrative access.

## EXAMPLES

### EXAMPLE 1
```
Test-IsElevated
```

Returns $true if the current session is running as Administrator (Windows) or root (Linux/macOS).

### EXAMPLE 2
```
if (Test-IsElevated) { Write-Output "Running elevated" } else { Write-Output "Not elevated" }
```

Conditionally executes logic based on whether the session is elevated.

### EXAMPLE 3
```
$elevated = Test-IsElevated
Write-Output "Elevated: $elevated"
```

Stores the elevation status in a variable for later use.

## PARAMETERS

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

### System.Boolean
### Returns $true if the session is elevated/running as administrator or root, $false otherwise.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This function is part of the tcs.core module and provides a cross-platform way to
check for elevated privileges in PowerShell 7+ environments.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

