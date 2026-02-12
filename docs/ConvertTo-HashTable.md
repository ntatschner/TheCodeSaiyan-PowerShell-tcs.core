---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# ConvertTo-HashTable

## SYNOPSIS
Converts a PSCustomObject to a hashtable.

## SYNTAX

```
ConvertTo-HashTable [-InputObject] <PSObject> [-Recurse] [-ExcludeEmpty] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-HashTable function converts a PSCustomObject (or any PSObject) into an
ordered hashtable.
It supports recursive conversion of nested PSCustomObjects and arrays,
as well as filtering out properties with null or empty values.
This is useful when working
with data from ConvertFrom-Json or other cmdlets that produce PSCustomObjects and you need
a hashtable for splatting, comparison, or other operations.

## EXAMPLES

### EXAMPLE 1
```
$obj = [PSCustomObject]@{ Name = "Test"; Value = 42 }
$obj | ConvertTo-HashTable
```

Converts a simple PSCustomObject to a hashtable with keys Name and Value.

### EXAMPLE 2
```
$json = '{"user":{"name":"Alice","age":30}}' | ConvertFrom-Json
ConvertTo-HashTable -InputObject $json -Recurse
```

Converts a nested JSON-derived PSCustomObject to a hashtable with the nested user
object also converted to a hashtable.

### EXAMPLE 3
```
[PSCustomObject]@{ A = "hello"; B = $null; C = "" } | ConvertTo-HashTable -ExcludeEmpty
```

Returns a hashtable containing only the key 'A', since B is null and C is an empty string.

## PARAMETERS

### -InputObject
The PSObject to convert to a hashtable.
Accepts pipeline input, allowing multiple objects
to be converted in sequence.

```yaml
Type:PSObject
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

### -Recurse
When specified, recursively converts nested PSCustomObjects and arrays of PSCustomObjects
into hashtables.

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

### -ExcludeEmpty
When specified, excludes properties with null or empty string values from the resulting
hashtable.

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

### System.Management.Automation.PSObject
### You can pipe one or more PSObjects to ConvertTo-HashTable.
## OUTPUTS

### System.Collections.Hashtable
### Returns a hashtable representing the properties of the input object.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This function is part of the tcs.core module and provides a convenient utility for
converting PSCustomObjects to hashtables, which is a common need when working with
JSON data, REST API responses, and PowerShell splatting.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

