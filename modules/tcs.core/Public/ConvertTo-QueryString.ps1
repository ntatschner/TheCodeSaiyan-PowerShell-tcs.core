<#
.SYNOPSIS
    Converts a hashtable to a URL query string.

.DESCRIPTION
    The ConvertTo-QueryString function builds a query string such as 'a=1&b=x%20y' from a
    hashtable or ordered dictionary:

      - Keys and values are escaped with [Uri]::EscapeDataString (spaces become %20).
      - An ordered dictionary keeps its order; the keys of a plain hashtable are sorted, so
        the result is always the same.
      - Array values repeat the key: @{ id = 1, 2 } becomes 'id=1&id=2'.
      - $null values are left out. Booleans are written as 'true' and 'false', dates as
        ISO 8601 (round-trip 'o' format) and numbers with the invariant culture.

    An empty dictionary returns an empty string. The '?' is not included.

.PARAMETER InputObject
    The hashtable or ordered dictionary of query parameters.

.INPUTS
    System.Collections.IDictionary
    You can pipe a hashtable to ConvertTo-QueryString.

.OUTPUTS
    System.String

.EXAMPLE
    ConvertTo-QueryString -InputObject ([ordered]@{ jql = 'project = OPS'; maxResults = 50 })

    Returns 'jql=project%20%3D%20OPS&maxResults=50'.

.EXAMPLE
    $query = ConvertTo-QueryString @{ expand = 'body.storage', 'version'; limit = 25 }
    Invoke-RestMethod -Uri "https://example.com/wiki/rest/api/content?$query"

    Returns 'expand=body.storage&expand=version&limit=25' and uses it in a request.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
#>
function ConvertTo-QueryString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, HelpMessage = 'The query parameters.')]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary]$InputObject
    )

    process {
        $keys = @($InputObject.Keys)
        if ($InputObject -isnot [System.Collections.Specialized.IOrderedDictionary]) {
            $keys = @($keys | Sort-Object -Property { [string]$_ })
        }

        $pairs = New-Object System.Collections.Generic.List[string]
        foreach ($key in $keys) {
            $value = $InputObject[$key]
            if ($null -eq $value) {
                continue
            }
            $values = if ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) { @($value) } else { @(, $value) }
            foreach ($item in $values) {
                if ($null -eq $item) {
                    continue
                }
                $text = if ($item -is [bool]) {
                    $item.ToString().ToLowerInvariant()
                }
                elseif ($item -is [datetime] -or $item -is [System.DateTimeOffset]) {
                    $item.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
                }
                elseif ($item -is [System.IFormattable]) {
                    $item.ToString($null, [System.Globalization.CultureInfo]::InvariantCulture)
                }
                else {
                    [string]$item
                }
                $pairs.Add(('{0}={1}' -f [Uri]::EscapeDataString([string]$key), [Uri]::EscapeDataString($text)))
            }
        }
        return ($pairs -join '&')
    }
}
