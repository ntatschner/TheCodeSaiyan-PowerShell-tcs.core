<#
.SYNOPSIS
    Converts a PSCustomObject to a hashtable.

.DESCRIPTION
    The ConvertTo-HashTable function converts a PSCustomObject (or any PSObject) into a
    hashtable (or an ordered dictionary with -Ordered). It supports recursive conversion of nested PSCustomObjects and arrays,
    as well as filtering out properties with null or empty values. This is useful when working
    with data from ConvertFrom-Json or other cmdlets that produce PSCustomObjects and you need
    a hashtable for splatting, comparison, or other operations.

    DEPRECATED: ConvertTo-HashTable writes a deprecation warning (once per session) and is
    planned for removal in tcs.core 1.0. On PowerShell 7 use ConvertFrom-Json -AsHashtable;
    for other objects build the hashtable from $object.PSObject.Properties.

.PARAMETER InputObject
    The PSObject to convert to a hashtable. Accepts pipeline input, allowing multiple objects
    to be converted in sequence.

.PARAMETER Recurse
    When specified, recursively converts nested PSCustomObjects and arrays of PSCustomObjects
    into hashtables.

.PARAMETER ExcludeEmpty
    When specified, excludes properties with null or empty string values from the resulting
    hashtable.

.PARAMETER Ordered
    Returns an ordered dictionary that keeps the property order of the input object.

.INPUTS
    System.Management.Automation.PSObject
    You can pipe one or more PSObjects to ConvertTo-HashTable.

.OUTPUTS
    System.Collections.Hashtable
    System.Collections.Specialized.OrderedDictionary (with -Ordered)

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

    This function is part of the tcs.core module and provides a convenient utility for
    converting PSCustomObjects to hashtables, which is a common need when working with
    JSON data, REST API responses, and PowerShell splatting.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function ConvertTo-HashTable {
    [CmdletBinding()]
    [OutputType([hashtable], [System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "The PSObject to convert to a hashtable.")]
        [PSObject]$InputObject,

        [Parameter(HelpMessage = "Recursively convert nested PSCustomObjects.")]
        [switch]$Recurse,

        [Parameter(HelpMessage = "Exclude properties with null or empty string values.")]
        [switch]$ExcludeEmpty,

        [Parameter(HelpMessage = "Return an ordered dictionary that keeps property order.")]
        [switch]$Ordered
    )

    begin {
        Write-DeprecationWarning -Feature 'ConvertTo-HashTable' -Message 'On PowerShell 7 use ConvertFrom-Json -AsHashtable.'
    }

    process {
        $hashtable = if ($Ordered) { [ordered]@{} } else { @{} }

        # A dictionary is already key/value data; its PSObject properties would be Keys, Count, etc.
        $entries = if ($InputObject -is [System.Collections.IDictionary]) {
            foreach ($key in $InputObject.Keys) { [PSCustomObject]@{ Name = [string]$key; Value = $InputObject[$key] } }
        }
        else {
            $InputObject.PSObject.Properties | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Value = $_.Value } }
        }

        foreach ($entry in $entries) {
            $value = $entry.Value

            if ($ExcludeEmpty) {
                if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrEmpty($value))) {
                    continue
                }
            }

            if ($Recurse -and $null -ne $value) {
                $value = ConvertTo-HashTableValue -Value $value -ExcludeEmpty:$ExcludeEmpty -Ordered:$Ordered
            }

            $hashtable[$entry.Name] = $value
        }

        return $hashtable
    }
}

function ConvertTo-HashTableValue {
    # Recursion helper for ConvertTo-HashTable -Recurse (nested objects and arrays of any depth)
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [AllowNull()]
        [object]$Value,

        [switch]$ExcludeEmpty,

        [switch]$Ordered
    )

    if ($Value -is [System.Management.Automation.PSCustomObject] -or $Value -is [System.Collections.IDictionary]) {
        return (ConvertTo-HashTable -InputObject $Value -Recurse -ExcludeEmpty:$ExcludeEmpty -Ordered:$Ordered)
    }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $list = New-Object System.Collections.Generic.List[object]
        foreach ($item in $Value) {
            $list.Add((ConvertTo-HashTableValue -Value $item -ExcludeEmpty:$ExcludeEmpty -Ordered:$Ordered))
        }
        # The leading comma stops PowerShell from unrolling one-item arrays
        return , $list.ToArray()
    }
    return $Value
}
