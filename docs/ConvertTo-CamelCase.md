---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# ConvertTo-CamelCase

## SYNOPSIS
Converts a string to camelCase format.

## SYNTAX

```
ConvertTo-CamelCase [-Value] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-CamelCase function takes a string input and converts it to camelCase format.
It splits the input on spaces, underscores, hyphens, and PascalCase boundaries, then
lowercases the first word and PascalCases subsequent words.
This is useful for formatting
property names, variable names, or other identifiers that need to follow camelCase naming
conventions.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-CamelCase -Value "HelloWorld"
Returns: "helloWorld"
```

### EXAMPLE 2
```
ConvertTo-CamelCase -Value "hello_world"
Returns: "helloWorld"
```

### EXAMPLE 3
```
ConvertTo-CamelCase -Value "hello-world"
Returns: "helloWorld"
```

### EXAMPLE 4
```
ConvertTo-CamelCase -Value "hello world"
Returns: "helloWorld"
```

### EXAMPLE 5
```
ConvertTo-CamelCase -Value "XML"
Returns: "xml"
```

### EXAMPLE 6
```
"MyProperty" | ConvertTo-CamelCase
Returns: "myProperty"
```

### EXAMPLE 7
```
ConvertTo-CamelCase -Value ""
Returns: "" (empty string unchanged)
```

## PARAMETERS

### -Value
The string value to convert to camelCase format.
Accepts pipeline input and string arrays.
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
### You can pipe one or more strings to ConvertTo-CamelCase.
## OUTPUTS

### System.String
### Returns the input string converted to camelCase format.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This function is part of the tcs.core module and is commonly used for formatting
strings to match JavaScript or JSON property naming conventions.

## RELATED LINKS
