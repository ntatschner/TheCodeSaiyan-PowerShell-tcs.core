<#
.SYNOPSIS
    Extracts and filters parameter values from PSBoundParameters.

.DESCRIPTION
    The Get-ParameterValues function processes the PSBoundParameters hashtable to extract
    meaningful parameter values while filtering out common PowerShell automatic variables
    and system parameters. This is useful for configuration management and parameter
    processing where only user-specified values are needed.

    DEPRECATED: Get-ParameterValues writes a deprecation warning (once per session) and is
    planned for removal in tcs.core 1.0. Use $PSBoundParameters directly, removing the keys
    you do not want, for example:
    $params = @{} + $PSBoundParameters; $params.Remove('Verbose')

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

    Common parameters (Verbose, ErrorAction, WhatIf, Confirm, ...) are always excluded.
#>
function Get-ParameterValues {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification = 'Public name used by other tcs modules; renaming would break them.')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PSBoundParametersHash,
        [string[]]$Exclude,
        [string[]]$Include
    )
    Write-DeprecationWarning -Feature 'Get-ParameterValues' -Message 'Use $PSBoundParameters directly.'

    # Get all the PSBoundParameters and set the values as a hashtable
    $DefaultExclude = @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ProgressAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'WhatIf', 'Confirm')
    if ($null -eq $Exclude) {
        $Exclude = $DefaultExclude
    } else {
        $Exclude += $DefaultExclude
    }
    $Parameters = @{}
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
