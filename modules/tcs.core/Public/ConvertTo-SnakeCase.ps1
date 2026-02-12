<#
.SYNOPSIS
    Converts a string to snake_case format.

.DESCRIPTION
    The ConvertTo-SnakeCase function takes a string input and converts it to snake_case format.
    It splits the input on spaces, underscores, hyphens, and PascalCase boundaries, then
    lowercases each word and joins them with underscores. This is useful for formatting
    database column names, Python-style identifiers, or other identifiers that need to follow
    snake_case naming conventions.

.PARAMETER Value
    The string value to convert to snake_case format. Accepts pipeline input and empty strings.
    If the value is null or empty, the function returns the original value unchanged.

.INPUTS
    System.String
    You can pipe one or more strings to ConvertTo-SnakeCase.

.OUTPUTS
    System.String
    Returns the input string converted to snake_case format.

.EXAMPLE
    ConvertTo-SnakeCase -Value "HelloWorld"
    Returns: "hello_world"

.EXAMPLE
    ConvertTo-SnakeCase -Value "hello-world"
    Returns: "hello_world"

.EXAMPLE
    "XMLParser" | ConvertTo-SnakeCase
    Returns: "xml_parser"

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

    This function is part of the tcs.core module and is commonly used for formatting
    strings to match Python or database column naming conventions.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function ConvertTo-SnakeCase {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Value
    )

    process {
        if ([string]::IsNullOrEmpty($Value)) {
            return $Value
        }
        # Split on spaces, underscores, hyphens, and PascalCase boundaries
        $words = [regex]::Split($Value, '[\s_\-]+|(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])') | Where-Object { $_ -ne '' }
        if ($words.Count -eq 0) {
            return $Value
        }
        $result = ($words | ForEach-Object { $_.ToLower() }) -join '_'
        return $result
    }
}
