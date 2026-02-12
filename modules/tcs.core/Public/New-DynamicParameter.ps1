<#
.SYNOPSIS
    Creates a dynamic parameter for use in PowerShell functions with DynamicParam blocks.

.DESCRIPTION
    The New-DynamicParameter function simplifies the creation of dynamic parameters in PowerShell functions.
    Dynamic parameters are useful when certain parameters should only be available under specific conditions
    or parameter sets. This helper function reduces the boilerplate code required to build a dynamic parameter
    with proper attributes, validation, and configuration.

.PARAMETER Name
    The name of the dynamic parameter to create. This will be the parameter name that users specify
    when calling the function.

.PARAMETER ParameterType
    The .NET type of the dynamic parameter (e.g., [string], [int], [switch], etc.).
    This determines what kind of values the parameter will accept.

.PARAMETER ParameterSetName
    The parameter set name that this dynamic parameter belongs to.
    Defaults to '__AllParameterSets' which means the parameter is available in all parameter sets.

.PARAMETER Mandatory
    Switch parameter that makes the dynamic parameter mandatory when specified.

.PARAMETER Position
    The position of the parameter in the parameter list. Allows for positional parameter usage.

.PARAMETER ValueFromPipelineByPropertyName
    Switch parameter that enables the parameter to accept values from pipeline input by property name.

.PARAMETER HelpMessage
    The help message displayed to users when they request help for this parameter.

.PARAMETER ValidateSet
    An array of valid values for the parameter. When specified, the parameter will only accept
    values from this set. This parameter is part of the 'ValidateSet' parameter set.

.PARAMETER IgnoreCase
    When using ValidateSet, determines whether case sensitivity is enforced for validation.
    Defaults to $true (case-insensitive validation).

.PARAMETER ValidateScript
    A script block used to validate the parameter value. The script should return $true for valid
    values and $false for invalid ones. This parameter is part of the 'ValidateScript' parameter set.

.INPUTS
    System.String
    You can pipe parameter names to New-DynamicParameter.

.OUTPUTS
    PSCustomObject
    Returns a custom object with Name and Parameter properties, where Parameter contains
    the RuntimeDefinedParameter object ready for use in a DynamicParam block.

.EXAMPLE
    # Create a simple string parameter
    $dynParam = New-DynamicParameter -Name "ServerName" -ParameterType ([string]) -Mandatory
    
.EXAMPLE
    # Create a parameter with validation set
    $dynParam = New-DynamicParameter -Name "Environment" -ParameterType ([string]) -ValidateSet @("Dev", "Test", "Prod") -Mandatory
    
.EXAMPLE
    # Create a parameter with custom validation script
    $script = { $_ -match '^[A-Z]{2,3}$' }
    $dynParam = New-DynamicParameter -Name "CountryCode" -ParameterType ([string]) -ValidateScript $script

.EXAMPLE
    # Use in a DynamicParam block
    function Test-Function {
        [CmdletBinding()]
        param()
        
        DynamicParam {
            $paramDict = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $dynParam = New-DynamicParameter -Name "DynamicParam" -ParameterType ([string]) -Mandatory
            $paramDict.Add($dynParam.Name, $dynParam.Parameter)
            return $paramDict
        }
        
        process {
            $dynamicValue = $PSBoundParameters['DynamicParam']
            Write-Output "Dynamic parameter value: $dynamicValue"
        }
    }

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.1.7
    
    This function is part of the tcs.core module and is designed to simplify the creation
    of dynamic parameters in advanced PowerShell functions. It handles the complex
    RuntimeDefinedParameter creation process and attribute configuration automatically.

.LINK
    about_Functions_Advanced_Parameters
    
.LINK
    about_Functions_DynamicParameters
#>
function New-DynamicParameter {
    [CmdletBinding(DefaultParameterSetName = 'Core')]    
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $Name,
        
        [Parameter(Mandatory)]
        [System.Type]
        $ParameterType,

        [string]
        $ParameterSetName = '__AllParameterSets',
        
        [switch]
        $Mandatory,

        [int]
        $Position,

        [switch]
        $ValueFromPipelineByPropertyName,

        [string]
        $HelpMessage,

        [Parameter(Mandatory, ParameterSetName = 'ValidateSet')]
        [string[]]
        $ValidateSet,

        [Parameter(ParameterSetName = 'ValidateSet')]
        [bool]
        $IgnoreCase = $true,

        [Parameter(Mandatory, ParameterSetName = 'ValidateScript')]
        [scriptblock]
        $ValidateScript
    )

    process {
        $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $attributeCollection = New-Object Collections.ObjectModel.Collection[System.Attribute]
        if ($PSBoundParameters.ContainsKey('ParameterSetName')) {
            $parameterAttribute.ParameterSetName = $ParameterSetName
        }
        if ($PSBoundParameters.ContainsKey('Mandatory')) {
            $parameterAttribute.Mandatory = $Mandatory
        }
        if ($PSBoundParameters.ContainsKey('Position')) {
            $parameterAttribute.Position = $Position
        }
        if ($PSBoundParameters.ContainsKey('ValueFromPipelineByPropertyName')) {
            $parameterAttribute.ValueFromPipelineByPropertyName = $ValueFromPipelineByPropertyName
        }
        if (-not [String]::IsNullOrEmpty($HelpMessage)) {
            $parameterAttribute.HelpMessage = $HelpMessage
        }
        if (-not [String]::IsNullOrEmpty($ValidateSet)) {
            if ($PSCmdlet.ParameterSetName -eq 'ValidateSet') {
                $parameterValidateSet = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet
                $parameterValidateSet.IgnoreCase = $IgnoreCase
            }
            $attributeCollection.Add($parameterValidateSet)
        }
        if (-not [String]::IsNullOrEmpty($ValidateScript)) {
            if ($PSCmdlet.ParameterSetName -eq 'ValidateScript') {
                $parameterValidateScript = New-Object System.Management.Automation.ValidateScriptAttribute -ArgumentList $ValidateScript
            }
            $attributeCollection.Add($parameterValidateScript)
        }

        $attributeCollection.Add($parameterAttribute)

        $parameter = New-Object System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $ParameterType, $attributeCollection)

        [pscustomobject]@{
            Name      = $Name
            Parameter = $parameter
        }
    }
}
