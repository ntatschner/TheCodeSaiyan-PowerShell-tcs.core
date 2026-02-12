<#
.SYNOPSIS
    Converts a string to kebab-case format.

.DESCRIPTION
    The ConvertTo-KebabCase function takes a string input and converts it to kebab-case format.
    It splits the input on spaces, underscores, hyphens, and PascalCase boundaries, then
    lowercases each word and joins them with hyphens. This is useful for formatting URL slugs,
    CSS class names, or other identifiers that need to follow kebab-case naming conventions.

.PARAMETER Value
    The string value to convert to kebab-case format. Accepts pipeline input and empty strings.
    If the value is null or empty, the function returns the original value unchanged.

.INPUTS
    System.String
    You can pipe one or more strings to ConvertTo-KebabCase.

.OUTPUTS
    System.String
    Returns the input string converted to kebab-case format.

.EXAMPLE
    ConvertTo-KebabCase -Value "HelloWorld"
    Returns: "hello-world"

.EXAMPLE
    ConvertTo-KebabCase -Value "hello_world"
    Returns: "hello-world"

.EXAMPLE
    "XMLParser" | ConvertTo-KebabCase
    Returns: "xml-parser"

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

    This function is part of the tcs.core module and is commonly used for formatting
    strings to match URL slug or CSS class naming conventions.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function ConvertTo-KebabCase {
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
        $result = ($words | ForEach-Object { $_.ToLower() }) -join '-'
        return $result
    }
}
