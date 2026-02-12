<#
.SYNOPSIS
    Extracts and filters parameter values from PSBoundParameters.

.DESCRIPTION
    The Get-ParameterValues function processes the PSBoundParameters hashtable to extract
    meaningful parameter values while filtering out common PowerShell automatic variables
    and system parameters. This is useful for configuration management and parameter
    processing where only user-specified values are needed.

.PARAMETER PSBoundParametersHash
    The PSBoundParameters hashtable from a PowerShell function, containing all parameters
    that were explicitly provided by the caller.

.PARAMETER Exclude
    An array of parameter names to exclude from the output. This is combined with a default
    set of common PowerShell automatic variables like 'Verbose', 'Debug', 'ErrorAction', etc.

.PARAMETER Include
    An array of parameter names to include in the output. When provided, only keys in this
    list are returned (still excluding nulls and common parameters). When not provided,
    all non-excluded parameters are returned.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Collections.Hashtable
    Returns a hashtable containing only the filtered parameter values with null values
    and excluded parameters removed.

.EXAMPLE
    function Test-Function {
        [CmdletBinding()]
        param($Name, $Value, $Path)
        $params = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters
        return $params
    }
    
    Extracts only the user-provided parameters from the function call.

.EXAMPLE
    $filteredParams = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters -Exclude @('TempPath')
    
    Extracts parameters while excluding 'TempPath' in addition to the default exclusions.

.EXAMPLE
    $filteredParams = Get-ParameterValues -PSBoundParametersHash $PSBoundParameters -Include @('Name', 'Value')
    
    Extracts only the 'Name' and 'Value' parameters, ignoring all others.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0
    
    This is a private function used internally by the tcs.core module for parameter
    processing and configuration management. It automatically excludes common PowerShell
    system parameters to provide clean parameter sets for further processing.
#>
function Get-ParameterValues {
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PSBoundParametersHash,
        [string[]]$Exclude,
        [string[]]$Include
    )
    # Get all the PSBoundParameters and set the values as a hashtable
    $DefaultExclude = @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable')
    if ($null -eq $Exclude) {
        $Exclude = $DefaultExclude
    } else {
        $Exclude += $DefaultExclude
    }
    $Parameters = New-Object System.Collections.Hashtable
    $PSBoundParametersHash.GetEnumerator() | ForEach-Object {
        # Only add the key and value to the hashtable if the value is not null and not the default parameters
        if ($null -ne $_.Value -and $Exclude -notcontains $_.Key) {
            if ($null -eq $Include -or $Include -contains $_.Key) {
                $Key = $_.Key
                $Value = $_.Value
                $Parameters.Add($Key, $Value)
            }
        }
    }
    $Parameters
}
