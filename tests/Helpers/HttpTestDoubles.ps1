# Test doubles for the HTTP error shapes of Windows PowerShell 5.1 and PowerShell 7.
# Dot-source from a BeforeAll block.

if (-not ('TcsTests.FakeWebResponse' -as [type])) {
    Add-Type -IgnoreWarnings -TypeDefinition @'
namespace TcsTests
{
    // Stands in for System.Net.HttpWebResponse, which cannot be constructed
    public class FakeWebResponse : System.Net.WebResponse
    {
        private readonly System.Net.WebHeaderCollection headers = new System.Net.WebHeaderCollection();
        private readonly byte[] body;

        public FakeWebResponse(int statusCode, string statusDescription, string bodyText)
        {
            StatusCode = (System.Net.HttpStatusCode)statusCode;
            StatusDescription = statusDescription;
            body = System.Text.Encoding.UTF8.GetBytes(bodyText ?? string.Empty);
        }

        public System.Net.HttpStatusCode StatusCode { get; private set; }
        public string StatusDescription { get; private set; }
        public override System.Net.WebHeaderCollection Headers { get { return headers; } }
        public override System.Uri ResponseUri { get { return new System.Uri("https://api.example.com/items"); } }
        public override System.IO.Stream GetResponseStream() { return new System.IO.MemoryStream(body); }
    }
}
'@
}

function New-TestWebException {
    # The error Windows PowerShell 5.1 web cmdlets throw: a WebException with an HttpWebResponse
    param([int]$StatusCode, [string]$Description = 'Error', [string]$Body = '', [string]$RetryAfter)
    $response = New-Object TcsTests.FakeWebResponse -ArgumentList $StatusCode, $Description, $Body
    if ($RetryAfter) {
        $response.Headers.Add('Retry-After', $RetryAfter)
    }
    return (New-Object System.Net.WebException -ArgumentList "The remote server returned an error: ($StatusCode) $Description.", $null, ([System.Net.WebExceptionStatus]::ProtocolError), $response)
}

function New-TestHttpResponseException {
    # The error PowerShell 7 web cmdlets throw: HttpResponseException with an HttpResponseMessage
    param([int]$StatusCode, [string]$Reason = 'Error', [string]$Body = '', [timespan]$RetryAfter)
    $message = New-Object System.Net.Http.HttpResponseMessage -ArgumentList ([System.Net.HttpStatusCode]$StatusCode)
    $message.ReasonPhrase = $Reason
    $message.Content = New-Object System.Net.Http.StringContent -ArgumentList $Body
    $message.RequestMessage = New-Object System.Net.Http.HttpRequestMessage -ArgumentList ([System.Net.Http.HttpMethod]::Get), 'https://api.example.com/items'
    if ($RetryAfter) {
        $message.Headers.RetryAfter = New-Object System.Net.Http.Headers.RetryConditionHeaderValue -ArgumentList $RetryAfter
    }
    return (New-Object Microsoft.PowerShell.Commands.HttpResponseException -ArgumentList "Response status code does not indicate success: $StatusCode ($Reason).", $message)
}

function New-TestErrorRecord {
    param([System.Exception]$Exception, [string]$ErrorDetails)
    $record = New-Object System.Management.Automation.ErrorRecord -ArgumentList $Exception, 'WebCmdletWebResponseException', ([System.Management.Automation.ErrorCategory]::InvalidOperation), $null
    if ($ErrorDetails) {
        $record.ErrorDetails = New-Object System.Management.Automation.ErrorDetails -ArgumentList $ErrorDetails
    }
    return $record
}
