<#
.SYNOPSIS
    Converts a string to camelCase format.

.DESCRIPTION
    The ConvertTo-CamelCase function takes a string input and converts it to camelCase format
    by making the first character lowercase while preserving the rest of the string's casing.
    This is useful for formatting property names, variable names, or other identifiers that
    need to follow camelCase naming conventions.

.PARAMETER Value
    The string value to convert to camelCase format. If the value is null or empty,
    the function returns the original value unchanged.

.INPUTS
    System.String
    You can pipe a string to ConvertTo-CamelCase.

.OUTPUTS
    System.String
    Returns the input string with the first character converted to lowercase.

.EXAMPLE
    ConvertTo-CamelCase -Value "HelloWorld"
    Returns: "helloWorld"

.EXAMPLE
    ConvertTo-CamelCase -Value "XML"
    Returns: "xML"

.EXAMPLE
    "MyProperty" | ConvertTo-CamelCase
    Returns: "myProperty"

.EXAMPLE
    ConvertTo-CamelCase -Value ""
    Returns: "" (empty string unchanged)

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.1.7
    
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
        return $Value.Substring(0, 1).ToLower() + $Value.Substring(1)
    }
}
