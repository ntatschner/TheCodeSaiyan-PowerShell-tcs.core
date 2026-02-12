<#
.SYNOPSIS
    Converts a string to PascalCase format.

.DESCRIPTION
    The ConvertTo-PascalCase function takes a string input and converts it to PascalCase format.
    It splits the input on spaces, underscores, hyphens, and PascalCase boundaries, then
    capitalizes the first letter of each word and lowercases the rest before joining them.
    This is useful for formatting class names, type names, or other identifiers that need
    to follow PascalCase naming conventions.

.PARAMETER Value
    The string value to convert to PascalCase format. Accepts pipeline input and empty strings.
    If the value is null or empty, the function returns the original value unchanged.

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

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

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
        $result = ''
        foreach ($word in $words) {
            if ($word.Length -gt 0) {
                $result += $word.Substring(0, 1).ToUpper() + $word.Substring(1).ToLower()
            }
        }
        return $result
    }
}
