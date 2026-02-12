---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# Get-ModuleStatus

## SYNOPSIS
Checks the status of a PowerShell module and optionally displays update notifications.

## SYNTAX

```
Get-ModuleStatus [-ShowMessage] [-ModuleName] <String> [-ModulePath] <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-ModuleStatus function compares the currently installed version of a module
with the latest version available in the PowerShell Gallery.
It always returns a
structured PSCustomObject with version information.
When the ShowMessage parameter
is specified, it also displays a warning message if an update is available.
This function is typically called during module import to notify users of available updates.

## EXAMPLES

### EXAMPLE 1
```
Get-ModuleStatus -ModuleName "tcs.core" -ModulePath "C:\Modules\tcs.core" -ShowMessage
```

Checks for updates to the tcs.core module, displays a message if an update is available,
and returns a status object.

### EXAMPLE 2
```
$status = Get-ModuleStatus -ModuleName "MyModule" -ModulePath $ModulePath
if ($status.UpdateAvailable) { Write-Host "Update available!" }
```

Checks the module status and uses the returned object to determine if an update is available.

## PARAMETERS

### -ShowMessage
Switch parameter that determines whether to display update notification messages.
When specified, the function will show a warning if a newer version is available.

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

### -ModuleName
The name of the module to check for updates.
This must match the module name
as it appears in the PowerShell Gallery.

```yaml
Type:String
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

### -ModulePath
The local file system path where the module is installed.
This is used to
locate the module manifest file (.psd1) to determine the current version.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 2Default
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

### PSCustomObject
### Returns a PSCustomObject with ModuleName, CurrentVersion, LatestVersion, and
### UpdateAvailable properties. May also display warning messages when ShowMessage
### is specified and updates are available.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This is a private function used internally by the tcs.core module for update
checking.
It gracefully handles errors and will not interrupt module loading
if the PowerShell Gallery is unavailable or if network issues occur.

## RELATED LINKS
