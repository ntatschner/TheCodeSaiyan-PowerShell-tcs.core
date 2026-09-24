---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# New-BasicAuthHeader

## SYNOPSIS
Builds an HTTP Basic Authorization header from a credential.

## SYNTAX

```
New-BasicAuthHeader [-Credential] <PSCredential> [-ValueOnly] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The New-BasicAuthHeader function returns a hashtable with an Authorization header of the
form 'Basic base64(user:password)', encoded as UTF-8, ready to pass to Invoke-RestMethod
-Headers.
Use -ValueOnly to get just the header value.

The password is only held in plain text for as long as it takes to encode it.
Build the
header just before each request rather than storing it.

## EXAMPLES

### EXAMPLE 1
```
$headers = New-BasicAuthHeader -Credential (Get-Credential)
Invoke-RestMethod -Uri 'https://example.atlassian.net/rest/api/3/myself' -Headers $headers
```

Calls an API with Basic authentication.

### EXAMPLE 2
```
$headers = @{ Accept = 'application/json' }
$headers.Authorization = New-BasicAuthHeader -Credential $credential -ValueOnly
```

Adds the Authorization value to an existing set of headers.

## PARAMETERS

### -Credential
The user name and password (or API token) to encode.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ValueOnly
Returns only the header value ('Basic ...') instead of a hashtable.

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

### System.Management.Automation.PSCredential
### You can pipe a credential to New-BasicAuthHeader.
## OUTPUTS

### System.Collections.Hashtable
### System.String (with -ValueOnly)
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

Basic authentication sends the credential with every request; only use it over HTTPS.

## RELATED LINKS
