---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# ConvertTo-SnakeCase

## SYNOPSIS
Converts a string to snake_case format.

## SYNTAX

```
ConvertTo-SnakeCase [-Value] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-SnakeCase function takes a string input and converts it to snake_case format.
It splits the input on spaces, underscores, hyphens, and PascalCase boundaries, then
lowercases each word and joins them with underscores.
This is useful for formatting
database column names, Python-style identifiers, or other identifiers that need to follow
snake_case naming conventions.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-SnakeCase -Value "HelloWorld"
Returns: "hello_world"
```

### EXAMPLE 2
```
ConvertTo-SnakeCase -Value "hello-world"
Returns: "hello_world"
```

### EXAMPLE 3
```
"XMLParser" | ConvertTo-SnakeCase
Returns: "xml_parser"
```

## PARAMETERS

### -Value
The string value to convert to snake_case format.
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
### You can pipe one or more strings to ConvertTo-SnakeCase.
## OUTPUTS

### System.String
### Returns the input string converted to snake_case format.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This function is part of the tcs.core module and is commonly used for formatting
strings to match Python or database column naming conventions.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

