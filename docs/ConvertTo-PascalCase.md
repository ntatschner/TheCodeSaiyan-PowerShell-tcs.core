---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# ConvertTo-PascalCase

## SYNOPSIS
Converts a string to PascalCase format.

## SYNTAX

```
ConvertTo-PascalCase [-Value] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-PascalCase function takes a string input and converts it to PascalCase format.
It splits the input on spaces, underscores, hyphens, and PascalCase boundaries, then
capitalizes the first letter of each word and lowercases the rest before joining them.
This is useful for formatting class names, type names, or other identifiers that need
to follow PascalCase naming conventions.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-PascalCase -Value "hello_world"
Returns: "HelloWorld"
```

### EXAMPLE 2
```
ConvertTo-PascalCase -Value "hello-world"
Returns: "HelloWorld"
```

### EXAMPLE 3
```
"helloWorld" | ConvertTo-PascalCase
Returns: "HelloWorld"
```

## PARAMETERS

### -Value
The string value to convert to PascalCase format.
Accepts pipeline input and empty strings.
If the value is null or empty, the function returns the original value unchanged.

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
Accept pipeline input: True (ByPropertyName, ByValue)
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

### System.String
### You can pipe one or more strings to ConvertTo-PascalCase.
## OUTPUTS

### System.String
### Returns the input string converted to PascalCase format.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This function is part of the tcs.core module and is commonly used for formatting
strings to match .NET type or class naming conventions.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

