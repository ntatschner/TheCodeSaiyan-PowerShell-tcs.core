<#
.SYNOPSIS
    Converts a string to camelCase format.

.DESCRIPTION
    The ConvertTo-CamelCase function takes a string input and converts it to camelCase format.
    It splits the input on spaces, underscores, hyphens, and PascalCase boundaries, then
    lowercases the first word and PascalCases subsequent words. This is useful for formatting
    property names, variable names, or other identifiers that need to follow camelCase naming
    conventions.

.PARAMETER Value
    The string value to convert to camelCase format. Accepts pipeline input and string arrays.
    If the value is null or empty, the function returns the original value unchanged.

.INPUTS
    System.String
    You can pipe one or more strings to ConvertTo-CamelCase.

.OUTPUTS
    System.String
    Returns the input string converted to camelCase format.

.EXAMPLE
    ConvertTo-CamelCase -Value "HelloWorld"
    Returns: "helloWorld"

.EXAMPLE
    ConvertTo-CamelCase -Value "hello_world"
    Returns: "helloWorld"

.EXAMPLE
    ConvertTo-CamelCase -Value "hello-world"
    Returns: "helloWorld"

.EXAMPLE
    ConvertTo-CamelCase -Value "hello world"
    Returns: "helloWorld"

.EXAMPLE
    ConvertTo-CamelCase -Value "XML"
    Returns: "xml"

.EXAMPLE
    "MyProperty" | ConvertTo-CamelCase
    Returns: "myProperty"

.EXAMPLE
    ConvertTo-CamelCase -Value ""
    Returns: "" (empty string unchanged)

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0
    
    This function is part of the tcs.core module and is commonly used for formatting
    strings to match JavaScript or JSON property naming conventions.
#>
function ConvertTo-CamelCase {
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
        $result = $words[0].ToLower()
        for ($i = 1; $i -lt $words.Count; $i++) {
            $word = $words[$i]
            if ($word.Length -gt 0) {
                $result += $word.Substring(0, 1).ToUpper() + $word.Substring(1).ToLower()
            }
        }
        return $result
    }
}
