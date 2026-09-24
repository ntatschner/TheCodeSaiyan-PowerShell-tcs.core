<#
.SYNOPSIS
    Builds an HTTP Basic Authorization header from a credential.

.DESCRIPTION
    The New-BasicAuthHeader function returns a hashtable with an Authorization header of the
    form 'Basic base64(user:password)', encoded as UTF-8, ready to pass to Invoke-RestMethod
    -Headers. Use -ValueOnly to get just the header value.

    The password is only held in plain text for as long as it takes to encode it. Build the
    header just before each request rather than storing it.

.PARAMETER Credential
    The user name and password (or API token) to encode.

.PARAMETER ValueOnly
    Returns only the header value ('Basic ...') instead of a hashtable.

.INPUTS
    System.Management.Automation.PSCredential
    You can pipe a credential to New-BasicAuthHeader.

.OUTPUTS
    System.Collections.Hashtable
    System.String (with -ValueOnly)

.EXAMPLE
    $headers = New-BasicAuthHeader -Credential (Get-Credential)
    Invoke-RestMethod -Uri 'https://example.atlassian.net/rest/api/3/myself' -Headers $headers

    Calls an API with Basic authentication.

.EXAMPLE
    $headers = @{ Accept = 'application/json' }
    $headers.Authorization = New-BasicAuthHeader -Credential $credential -ValueOnly

    Adds the Authorization value to an existing set of headers.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

    Basic authentication sends the credential with every request; only use it over HTTPS.
#>
function New-BasicAuthHeader {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Only builds an in-memory value; nothing on the system is changed.')]
    [CmdletBinding()]
    [OutputType([hashtable], [string])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, HelpMessage = 'The credential to encode.')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(HelpMessage = 'Return only the header value.')]
        [switch]$ValueOnly
    )

    process {
        $pair = '{0}:{1}' -f $Credential.UserName, $Credential.GetNetworkCredential().Password
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
        try {
            $value = 'Basic ' + [Convert]::ToBase64String($bytes)
        }
        finally {
            [Array]::Clear($bytes, 0, $bytes.Length)
            $pair = $null
        }

        if ($ValueOnly) {
            return $value
        }
        return @{ Authorization = $value }
    }
}
