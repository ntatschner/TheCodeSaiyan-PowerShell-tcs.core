<#
.SYNOPSIS
    Converts a PSCustomObject to a hashtable.

.DESCRIPTION
    The ConvertTo-HashTable function converts a PSCustomObject (or any PSObject) into an
    ordered hashtable. It supports recursive conversion of nested PSCustomObjects and arrays,
    as well as filtering out properties with null or empty values. This is useful when working
    with data from ConvertFrom-Json or other cmdlets that produce PSCustomObjects and you need
    a hashtable for splatting, comparison, or other operations.

.PARAMETER InputObject
    The PSObject to convert to a hashtable. Accepts pipeline input, allowing multiple objects
    to be converted in sequence.

.PARAMETER Recurse
    When specified, recursively converts nested PSCustomObjects and arrays of PSCustomObjects
    into hashtables.

.PARAMETER ExcludeEmpty
    When specified, excludes properties with null or empty string values from the resulting
    hashtable.

.INPUTS
    System.Management.Automation.PSObject
    You can pipe one or more PSObjects to ConvertTo-HashTable.

.OUTPUTS
    System.Collections.Hashtable
    Returns a hashtable representing the properties of the input object.

.EXAMPLE
    $obj = [PSCustomObject]@{ Name = "Test"; Value = 42 }
    $obj | ConvertTo-HashTable

    Converts a simple PSCustomObject to a hashtable with keys Name and Value.

.EXAMPLE
    $json = '{"user":{"name":"Alice","age":30}}' | ConvertFrom-Json
    ConvertTo-HashTable -InputObject $json -Recurse

    Converts a nested JSON-derived PSCustomObject to a hashtable with the nested user
    object also converted to a hashtable.

.EXAMPLE
    [PSCustomObject]@{ A = "hello"; B = $null; C = "" } | ConvertTo-HashTable -ExcludeEmpty

    Returns a hashtable containing only the key 'A', since B is null and C is an empty string.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

    This function is part of the tcs.core module and provides a convenient utility for
    converting PSCustomObjects to hashtables, which is a common need when working with
    JSON data, REST API responses, and PowerShell splatting.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function ConvertTo-HashTable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "The PSObject to convert to a hashtable.")]
        [PSObject]$InputObject,

        [Parameter(HelpMessage = "Recursively convert nested PSCustomObjects.")]
        [switch]$Recurse,

        [Parameter(HelpMessage = "Exclude properties with null or empty string values.")]
        [switch]$ExcludeEmpty
    )

    process {
        $hashtable = @{}

        foreach ($property in $InputObject.PSObject.Properties) {
            $value = $property.Value

            if ($ExcludeEmpty) {
                if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrEmpty($value))) {
                    continue
                }
            }

            if ($Recurse -and $null -ne $value) {
                if ($value -is [System.Management.Automation.PSCustomObject]) {
                    $value = ConvertTo-HashTable -InputObject $value -Recurse:$Recurse -ExcludeEmpty:$ExcludeEmpty
                }
                elseif ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
                    $convertedArray = @()
                    foreach ($item in $value) {
                        if ($item -is [System.Management.Automation.PSCustomObject]) {
                            $convertedArray += ConvertTo-HashTable -InputObject $item -Recurse:$Recurse -ExcludeEmpty:$ExcludeEmpty
                        }
                        else {
                            $convertedArray += $item
                        }
                    }
                    $value = $convertedArray
                }
            }

            $hashtable[$property.Name] = $value
        }

        return $hashtable
    }
}
