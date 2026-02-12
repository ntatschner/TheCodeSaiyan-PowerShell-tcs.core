---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# New-TemporaryDirectory

## SYNOPSIS
Creates a new temporary directory with an optional name prefix.

## SYNTAX

```
New-TemporaryDirectory [[-Prefix] <String>] [[-BasePath] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The New-TemporaryDirectory function creates a uniquely named temporary directory under
the system temp path or a specified base path.
The directory name is composed of the
given prefix followed by the first 8 characters of a new GUID, ensuring uniqueness.
The function returns the DirectoryInfo object for the created directory.

## EXAMPLES

### EXAMPLE 1
```
New-TemporaryDirectory
```

Creates a directory like 'C:\Users\\\<user\>\AppData\Local\Temp\tcs_a1b2c3d4' and returns
its DirectoryInfo object.

### EXAMPLE 2
```
New-TemporaryDirectory -Prefix "build" -BasePath "D:\Staging"
```

Creates a directory like 'D:\Staging\build_e5f6a7b8' and returns its DirectoryInfo object.

### EXAMPLE 3
```
$tmpDir = New-TemporaryDirectory -Prefix "test"
Set-Location $tmpDir.FullName
```

Creates a temporary directory with a 'test' prefix and changes to it.

## PARAMETERS

### -Prefix
A prefix string for the temporary directory name.
Defaults to 'tcs'.
The final directory
name follows the pattern '{Prefix}_{first8-guid-chars}'.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 1Default
Default value: None
Default value: Tcs
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -BasePath
An optional base directory path under which the temporary directory is created.
Defaults
to the system temporary path returned by \[System.IO.Path\]::GetTempPath().

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

### System.IO.DirectoryInfo
### Returns the DirectoryInfo object representing the newly created temporary directory.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This function is part of the tcs.core module and provides a convenient way to create
uniquely named temporary directories for build artifacts, test isolation, or other
transient file operations.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

