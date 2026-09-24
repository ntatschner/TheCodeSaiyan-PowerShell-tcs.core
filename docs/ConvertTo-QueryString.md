---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# ConvertTo-QueryString

## SYNOPSIS
Converts a hashtable to a URL query string.

## SYNTAX

```
ConvertTo-QueryString [-InputObject] <IDictionary> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The ConvertTo-QueryString function builds a query string such as 'a=1&b=x%20y' from a
hashtable or ordered dictionary:

  - Keys and values are escaped with \[Uri\]::EscapeDataString (spaces become %20).
  - An ordered dictionary keeps its order; the keys of a plain hashtable are sorted, so
    the result is always the same.
  - Array values repeat the key: @{ id = 1, 2 } becomes 'id=1&id=2'.
  - $null values are left out.
Booleans are written as 'true' and 'false', dates as
    ISO 8601 (round-trip 'o' format) and numbers with the invariant culture.

An empty dictionary returns an empty string.
The '?' is not included.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-QueryString -InputObject ([ordered]@{ jql = 'project = OPS'; maxResults = 50 })
```

Returns 'jql=project%20%3D%20OPS&maxResults=50'.

### EXAMPLE 2
```
$query = ConvertTo-QueryString @{ expand = 'body.storage', 'version'; limit = 25 }
Invoke-RestMethod -Uri "https://example.com/wiki/rest/api/content?$query"
```

Returns 'expand=body.storage&expand=version&limit=25' and uses it in a request.

## PARAMETERS

### -InputObject
The hashtable or ordered dictionary of query parameters.

```yaml
Type: IDictionary
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

### System.Collections.IDictionary
### You can pipe a hashtable to ConvertTo-QueryString.
## OUTPUTS

### System.String
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

## RELATED LINKS
