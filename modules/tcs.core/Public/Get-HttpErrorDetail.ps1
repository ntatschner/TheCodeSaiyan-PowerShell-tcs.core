<#
.SYNOPSIS
    Returns the HTTP status code, body and Retry-After delay of a failed web request.

.DESCRIPTION
    The Get-HttpErrorDetail function reads the HTTP details from the error thrown by
    Invoke-RestMethod or Invoke-WebRequest (or HttpClient), in the same way on Windows
    PowerShell 5.1 and PowerShell 7:

      - Windows PowerShell 5.1 throws System.Net.WebException with an HttpWebResponse.
      - PowerShell 7 throws HttpResponseException with an HttpResponseMessage.
      - HttpRequestException (.NET 5 and later) carries only a status code.

    Wrapped exceptions (InnerException) are searched too. The body is taken from
    ErrorDetails.Message (where both editions put the response body) or read from the
    response. Nothing is returned when the error has no HTTP response, for example a DNS or
    connection failure.

.PARAMETER ErrorRecord
    The error to inspect: an ErrorRecord (such as $_ in a catch block) or an Exception.

.INPUTS
    System.Management.Automation.ErrorRecord
    You can pipe errors to Get-HttpErrorDetail.

.OUTPUTS
    Tcs.HttpErrorDetail
    StatusCode (int), StatusDescription, Body, RetryAfterSeconds (double, $null when the
    response has no Retry-After header), Uri and Response (the raw response object).

.EXAMPLE
    try {
        Invoke-RestMethod -Uri 'https://api.example.com/items/42'
    }
    catch {
        $detail = Get-HttpErrorDetail -ErrorRecord $_
        if ($detail.StatusCode -eq 404) { return $null }
        throw "Request failed with $($detail.StatusCode): $($detail.Body)"
    }

    Handles a 404 and reports other failures with the response body.

.EXAMPLE
    $Error[0] | Get-HttpErrorDetail | Select-Object StatusCode, RetryAfterSeconds

    Shows the status code and Retry-After delay of the most recent error.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

.LINK
    Invoke-WithRetry
#>
function Get-HttpErrorDetail {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, HelpMessage = 'The ErrorRecord or Exception to inspect.')]
        [ValidateNotNull()]
        [object]$ErrorRecord
    )

    process {
        $detail = Get-HttpResponseInfo -InputObject $ErrorRecord
        if ($null -ne $detail) {
            $detail
        }
    }
}
