---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Get-HttpErrorDetail

## SYNOPSIS
Returns the HTTP status code, body and Retry-After delay of a failed web request.

## SYNTAX

```
Get-HttpErrorDetail [-ErrorRecord] <Object> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-HttpErrorDetail function reads the HTTP details from the error thrown by
Invoke-RestMethod or Invoke-WebRequest (or HttpClient), in the same way on Windows
PowerShell 5.1 and PowerShell 7:

  - Windows PowerShell 5.1 throws System.Net.WebException with an HttpWebResponse.
  - PowerShell 7 throws HttpResponseException with an HttpResponseMessage.
  - HttpRequestException (.NET 5 and later) carries only a status code.

Wrapped exceptions (InnerException) are searched too.
The body is taken from
ErrorDetails.Message (where both editions put the response body) or read from the
response.
Nothing is returned when the error has no HTTP response, for example a DNS or
connection failure.

## EXAMPLES

### EXAMPLE 1
```
try {
    Invoke-RestMethod -Uri 'https://api.example.com/items/42'
}
catch {
    $detail = Get-HttpErrorDetail -ErrorRecord $_
    if ($detail.StatusCode -eq 404) { return $null }
    throw "Request failed with $($detail.StatusCode): $($detail.Body)"
}
```

Handles a 404 and reports other failures with the response body.

### EXAMPLE 2
```
$Error[0] | Get-HttpErrorDetail | Select-Object StatusCode, RetryAfterSeconds
```

Shows the status code and Retry-After delay of the most recent error.

## PARAMETERS

### -ErrorRecord
The error to inspect: an ErrorRecord (such as $_ in a catch block) or an Exception.

```yaml
Type: Object
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

### System.Management.Automation.ErrorRecord
### You can pipe errors to Get-HttpErrorDetail.
## OUTPUTS

### Tcs.HttpErrorDetail
### StatusCode (int), StatusDescription, Body, RetryAfterSeconds (double, $null when the
### response has no Retry-After header), Uri and Response (the raw response object).
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

## RELATED LINKS

[Invoke-WithRetry]()

