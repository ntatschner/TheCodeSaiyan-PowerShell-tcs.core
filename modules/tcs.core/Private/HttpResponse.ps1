<#
.SYNOPSIS
    Internal helpers that read HTTP details from the errors thrown by web cmdlets.

.DESCRIPTION
    Windows PowerShell 5.1 throws System.Net.WebException, whose Response is an
    HttpWebResponse (StatusCode, StatusDescription, WebHeaderCollection headers and a body
    stream). PowerShell 7 throws Microsoft.PowerShell.Commands.HttpResponseException, whose
    Response is an HttpResponseMessage (StatusCode, ReasonPhrase and typed headers with a
    RetryAfter property). In both, Invoke-RestMethod and Invoke-WebRequest put the response
    body in ErrorRecord.ErrorDetails.Message. .NET's HttpRequestException has a StatusCode
    property on .NET 5 and later.

.NOTES
    Private helpers for the tcs.core module. Duck-typed so that wrapped exceptions and test
    doubles work on both editions.
#>

function ConvertTo-RetryAfterDelay {
    <#
    .SYNOPSIS
        Converts a Retry-After header value (delay in seconds or an HTTP date) to seconds from now.
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    # System.Net.Http.Headers.RetryConditionHeaderValue (PowerShell 7 / HttpClient)
    if ($Value.PSObject.Properties['Delta'] -or $Value.PSObject.Properties['Date']) {
        if ($null -ne $Value.Delta) {
            return [Math]::Max(0, $Value.Delta.TotalSeconds)
        }
        if ($null -ne $Value.Date) {
            return [Math]::Max(0, ($Value.Date.UtcDateTime - [datetime]::UtcNow).TotalSeconds)
        }
        return $null
    }

    $text = ([string]@($Value)[0]).Trim()
    if ([string]::IsNullOrEmpty($text)) {
        return $null
    }
    $seconds = [double]0
    if ([double]::TryParse($text, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$seconds)) {
        return [Math]::Max(0, $seconds)
    }
    $date = [System.DateTimeOffset]::MinValue
    $styles = [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AllowWhiteSpaces
    if ([System.DateTimeOffset]::TryParse($text, [System.Globalization.CultureInfo]::InvariantCulture, $styles, [ref]$date)) {
        return [Math]::Max(0, ($date.UtcDateTime - [datetime]::UtcNow).TotalSeconds)
    }
    return $null
}

function Get-HttpResponseInfo {
    <#
    .SYNOPSIS
        Returns StatusCode, StatusDescription, Body, RetryAfterSeconds, Uri and Response for an
        error that carries an HTTP response, or $null when it has none.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowNull()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }

    $errorRecord = $null
    $exception = $null
    if ($InputObject -is [System.Management.Automation.ErrorRecord]) {
        $errorRecord = $InputObject
        $exception = $InputObject.Exception
    }
    elseif ($InputObject -is [System.Exception]) {
        $exception = $InputObject
    }
    elseif ($InputObject.PSObject.Properties['Exception']) {
        $exception = $InputObject.Exception
    }
    else {
        $exception = $InputObject
    }

    # Find the first exception in the chain that has a response or a status code
    $response = $null
    $statusCode = $null
    $current = $exception
    $depth = 0
    while ($null -ne $current -and $depth -lt 10) {
        if ($current.PSObject.Properties['Response'] -and $null -ne $current.Response) {
            $response = $current.Response
            break
        }
        if ($current.PSObject.Properties['StatusCode'] -and $null -ne $current.StatusCode) {
            $statusCode = [int]$current.StatusCode
            break
        }
        if ($current.PSObject.Properties['InnerException']) {
            $current = $current.InnerException
        }
        else {
            $current = $null
        }
        $depth++
    }

    if ($null -eq $response -and $null -eq $statusCode) {
        return $null
    }

    $statusDescription = $null
    $retryAfter = $null
    $uri = $null
    if ($null -ne $response) {
        if ($response.PSObject.Properties['StatusCode'] -and $null -ne $response.StatusCode) {
            $statusCode = [int]$response.StatusCode
        }
        if ($response.PSObject.Properties['StatusDescription']) {
            $statusDescription = [string]$response.StatusDescription
        }
        elseif ($response.PSObject.Properties['ReasonPhrase']) {
            $statusDescription = [string]$response.ReasonPhrase
        }
        if ($response.PSObject.Properties['ResponseUri'] -and $response.ResponseUri) {
            $uri = [string]$response.ResponseUri
        }
        elseif ($response.PSObject.Properties['RequestMessage'] -and $response.RequestMessage -and $response.RequestMessage.RequestUri) {
            $uri = [string]$response.RequestMessage.RequestUri
        }

        $headers = $null
        if ($response.PSObject.Properties['Headers']) {
            $headers = $response.Headers
        }
        if ($null -ne $headers) {
            if ($headers -is [System.Collections.IDictionary] -or $headers -is [System.Collections.Specialized.NameValueCollection]) {
                # WebHeaderCollection (Windows PowerShell) and plain dictionaries
                $retryAfter = ConvertTo-RetryAfterDelay -Value $headers['Retry-After']
            }
            elseif ($headers.PSObject.Properties['RetryAfter']) {
                # HttpResponseHeaders (PowerShell 7)
                $retryAfter = ConvertTo-RetryAfterDelay -Value $headers.RetryAfter
            }
        }
    }

    $body = $null
    if ($errorRecord -and $errorRecord.ErrorDetails -and -not [string]::IsNullOrEmpty($errorRecord.ErrorDetails.Message)) {
        $body = $errorRecord.ErrorDetails.Message
    }
    elseif ($null -ne $response) {
        try {
            if ($response.PSObject.Methods['GetResponseStream']) {
                $stream = $response.GetResponseStream()
                if ($stream) {
                    if ($stream.CanSeek) {
                        $stream.Position = 0
                    }
                    $reader = New-Object System.IO.StreamReader -ArgumentList $stream
                    try {
                        $body = $reader.ReadToEnd()
                    }
                    finally {
                        $reader.Dispose()
                    }
                }
            }
            elseif ($response.PSObject.Properties['Content'] -and $null -ne $response.Content) {
                if ($response.Content -is [string]) {
                    $body = $response.Content
                }
                elseif ($response.Content.PSObject.Methods['ReadAsStringAsync']) {
                    $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                }
            }
        }
        catch {
            Write-Verbose "Could not read the HTTP response body: $($_.Exception.Message)"
        }
    }

    return [PSCustomObject]@{
        PSTypeName        = 'Tcs.HttpErrorDetail'
        StatusCode        = $statusCode
        StatusDescription = $statusDescription
        Body              = $body
        RetryAfterSeconds = $retryAfter
        Uri               = $uri
        Response          = $response
    }
}
