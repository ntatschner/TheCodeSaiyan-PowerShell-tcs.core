---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Get-ModuleStatus

## SYNOPSIS
Checks whether a newer version of a module is available in the PowerShell Gallery.

## SYNTAX

```
Get-ModuleStatus [-ShowMessage] [-ModuleName] <String> [-ModulePath] <String> [[-CacheHours] <Int32>] [-Force]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-ModuleStatus function compares the installed version of a module with the latest
version in the PowerShell Gallery and returns a status object.

The gallery is queried at most once per CacheHours (default 24).
The result is cached in
\<ApplicationData\>/PowerShell/Config/\<ModuleName\>/UpdateCheck.json, so importing a module
does not make a network call every time.
Failed lookups (for example when offline) are
cached too, so they are not retried on every import.

The function never throws: if the check fails it writes a verbose message and returns a
status object with LatestVersion set to $null.

Set the TCS_SKIP_UPDATE_CHECK environment variable to 1 to turn the check off (for example
in CI).
-Force overrides this and the cache.

## EXAMPLES

### EXAMPLE 1
```
Get-ModuleStatus -ModuleName 'tcs.core' -ModulePath (Get-Module tcs.core).ModuleBase -ShowMessage
```

Warns if a newer tcs.core is available, using the cached result if it is less than a day old.

### EXAMPLE 2
```
(Get-ModuleStatus -ModuleName 'tcs.jira' -ModulePath $path -Force).UpdateAvailable
```

Queries the gallery now and returns whether an update is available.

## PARAMETERS

### -ShowMessage
Writes a warning when an update is available.

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

### -ModuleName
The name of the module as published in the PowerShell Gallery.
Only letters, digits, '.',
'_' and '-' are allowed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModulePath
The folder that contains the module manifest (\<ModuleName\>.psd1).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CacheHours
How long a gallery result is reused, in hours.
0 always queries the gallery.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 24
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Queries the gallery now, ignoring the cache and TCS_SKIP_UPDATE_CHECK.

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

### PSCustomObject
### ModuleName, CurrentVersion, LatestVersion, UpdateAvailable, CheckedAt (UTC) and Source
### ('Gallery', 'Cache' or 'Skipped').
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

Uses Find-PSResource (Microsoft.PowerShell.PSResourceGet) when available, otherwise
Find-Module (PowerShellGet).

## RELATED LINKS
