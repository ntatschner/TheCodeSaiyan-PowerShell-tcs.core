<#
.SYNOPSIS
    Converts a string to PascalCase format.

.DESCRIPTION
    The ConvertTo-PascalCase function takes a string input and converts it to PascalCase format.
    It splits the input on spaces, underscores, hyphens, case changes (including letters
    outside A-Z, such as 'Ä') and a digit followed by a capital ('Version2Update'), then
    capitalizes the first letter of each word and lowercases the rest before joining them.
    This is useful for formatting class names, type names, or other identifiers that need
    to follow PascalCase naming conventions.

.PARAMETER Value
    The string value to convert to PascalCase format. Accepts pipeline input and empty strings.
    If the value is null or empty, the function returns the original value unchanged.

.PARAMETER PreserveAcronyms
    Keeps words written in capitals (at least two capital letters, such as 'XML', 'FA' or
    'HTML5') as they are instead of capitalising only their first letter: 'XMLHttpRequest'
    becomes 'XMLHttpRequest' instead of 'XmlHttpRequest'.

.INPUTS
    System.String
    You can pipe one or more strings to ConvertTo-PascalCase.

.OUTPUTS
    System.String
    Returns the input string converted to PascalCase format.

.EXAMPLE
    ConvertTo-PascalCase -Value "hello_world"
    Returns: "HelloWorld"

.EXAMPLE
    ConvertTo-PascalCase -Value "hello-world"
    Returns: "HelloWorld"

.EXAMPLE
    "helloWorld" | ConvertTo-PascalCase
    Returns: "HelloWorld"

.EXAMPLE
    ConvertTo-PascalCase -Value 'user2FA'
    Returns: "User2Fa"

.EXAMPLE
    ConvertTo-PascalCase -Value 'parse_XML_file' -PreserveAcronyms
    Returns: "ParseXMLFile"

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

    This function is part of the tcs.core module and is commonly used for formatting
    strings to match .NET type or class naming conventions.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function ConvertTo-PascalCase {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(HelpMessage = 'Keep all-capitals words such as XML as they are.')]
        [switch]$PreserveAcronyms
    )

    process {
        if ([string]::IsNullOrEmpty($Value)) {
            return $Value
        }
        # Split on spaces, underscores, hyphens, case changes and digit/capital boundaries
        $words = Split-CaseWord -Value $Value
        if ($words.Count -eq 0) {
            return $Value
        }
        $result = ''
        foreach ($word in $words) {
            $result += ConvertTo-CapitalisedWord -Word $word -PreserveAcronyms:$PreserveAcronyms
        }
        return $result
    }
}
