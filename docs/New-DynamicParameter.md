---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# New-DynamicParameter

## SYNOPSIS
Creates a dynamic parameter for use in PowerShell functions with DynamicParam blocks.

## SYNTAX

### Core (Default)
```
New-DynamicParameter -Name <String> -ParameterType <Type> [-ParameterSetName <String>] [-Mandatory]
 [-Position <Int32>] [-ValueFromPipelineByPropertyName] [-HelpMessage <String>] [-ValidateNotNullOrEmpty]
 [-Alias <String[]>] [-ValueFromPipeline] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ValidateSet
```
New-DynamicParameter -Name <String> -ParameterType <Type> [-ParameterSetName <String>] [-Mandatory]
 [-Position <Int32>] [-ValueFromPipelineByPropertyName] [-HelpMessage <String>] -ValidateSet <String[]>
 [-IgnoreCase <Boolean>] [-ValidateNotNullOrEmpty] [-Alias <String[]>] [-ValueFromPipeline]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### ValidateScript
```
New-DynamicParameter -Name <String> -ParameterType <Type> [-ParameterSetName <String>] [-Mandatory]
 [-Position <Int32>] [-ValueFromPipelineByPropertyName] [-HelpMessage <String>] -ValidateScript <ScriptBlock>
 [-ValidateNotNullOrEmpty] [-Alias <String[]>] [-ValueFromPipeline] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ValidatePattern
```
New-DynamicParameter -Name <String> -ParameterType <Type> [-ParameterSetName <String>] [-Mandatory]
 [-Position <Int32>] [-ValueFromPipelineByPropertyName] [-HelpMessage <String>] [-ValidateNotNullOrEmpty]
 -ValidatePattern <String> [-Alias <String[]>] [-ValueFromPipeline] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ValidateRange
```
New-DynamicParameter -Name <String> -ParameterType <Type> [-ParameterSetName <String>] [-Mandatory]
 [-Position <Int32>] [-ValueFromPipelineByPropertyName] [-HelpMessage <String>] [-ValidateNotNullOrEmpty]
 -ValidateRange <Int32[]> [-Alias <String[]>] [-ValueFromPipeline] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### ValidateLength
```
New-DynamicParameter -Name <String> -ParameterType <Type> [-ParameterSetName <String>] [-Mandatory]
 [-Position <Int32>] [-ValueFromPipelineByPropertyName] [-HelpMessage <String>] [-ValidateNotNullOrEmpty]
 -ValidateLength <Int32[]> [-Alias <String[]>] [-ValueFromPipeline] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The New-DynamicParameter function simplifies the creation of dynamic parameters in PowerShell functions.
Dynamic parameters are useful when certain parameters should only be available under specific conditions
or parameter sets.
This helper function reduces the boilerplate code required to build a dynamic parameter
with proper attributes, validation, and configuration.

## EXAMPLES

### EXAMPLE 1
```
# Create a simple string parameter
$dynParam = New-DynamicParameter -Name "ServerName" -ParameterType ([string]) -Mandatory
```

### EXAMPLE 2
```
# Create a parameter with validation set
$dynParam = New-DynamicParameter -Name "Environment" -ParameterType ([string]) -ValidateSet @("Dev", "Test", "Prod") -Mandatory
```

### EXAMPLE 3
```
# Create a parameter with custom validation script
$script = { $_ -match '^[A-Z]{2,3}$' }
$dynParam = New-DynamicParameter -Name "CountryCode" -ParameterType ([string]) -ValidateScript $script
```

### EXAMPLE 4
```
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
```

### EXAMPLE 5
```
# Create a parameter with ValidateNotNullOrEmpty and an alias
$dynParam = New-DynamicParameter -Name "UserName" -ParameterType ([string]) -ValidateNotNullOrEmpty -Alias @("User", "Name")
```

### EXAMPLE 6
```
# Create a parameter with ValidatePattern
$dynParam = New-DynamicParameter -Name "Email" -ParameterType ([string]) -ValidatePattern '^[\w.]+@[\w.]+$'
```

### EXAMPLE 7
```
# Create a parameter with ValidateRange
$dynParam = New-DynamicParameter -Name "Port" -ParameterType ([int]) -ValidateRange @(1, 65535)
```

### EXAMPLE 8
```
# Create a parameter with ValidateLength and ValueFromPipeline
$dynParam = New-DynamicParameter -Name "Code" -ParameterType ([string]) -ValidateLength @(2, 10) -ValueFromPipeline
```

## PARAMETERS

### -Name
The name of the dynamic parameter to create.
This will be the parameter name that users specify
when calling the function.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ParameterType
The .NET type of the dynamic parameter (e.g., \[string\], \[int\], \[switch\], etc.).
This determines what kind of values the parameter will accept.

```yaml
Type:Type
Parameter Sets:   (All)
Aliases:
Required: True
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ParameterSetName
The parameter set name that this dynamic parameter belongs to.
Defaults to '__AllParameterSets' which means the parameter is available in all parameter sets.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: __AllParameterSets
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Mandatory
Switch parameter that makes the dynamic parameter mandatory when specified.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Position
The position of the parameter in the parameter list.
Allows for positional parameter usage.

```yaml
Type:
Int32
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: 0
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ValueFromPipelineByPropertyName
Switch parameter that enables the parameter to accept values from pipeline input by property name.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -HelpMessage
The help message displayed to users when they request help for this parameter.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ValidateSet
An array of valid values for the parameter.
When specified, the parameter will only accept
values from this set.
This parameter is part of the 'ValidateSet' parameter set.

```yaml
Type: String[]
Parameter Sets: ValidateSet
Aliases:
Required: True
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -IgnoreCase
When using ValidateSet, determines whether case sensitivity is enforced for validation.
Defaults to $true (case-insensitive validation).

```yaml
Type:Boolean
Parameter Sets: ValidateSet
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: True
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ValidateScript
A script block used to validate the parameter value.
The script should return $true for valid
values and $false for invalid ones.
This parameter is part of the 'ValidateScript' parameter set.

```yaml
Type:ScriptBlock
Parameter Sets: ValidateScript
Aliases:
Required: True
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ValidateNotNullOrEmpty
Switch parameter that adds a ValidateNotNullOrEmpty attribute to the dynamic parameter.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ValidatePattern
A regex pattern string that adds a ValidatePattern attribute to the dynamic parameter.
This parameter is part of the 'ValidatePattern' parameter set.

```yaml
Type:String
Parameter Sets: ValidatePattern
Aliases:
Required: True
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ValidateRange
An array of two integers (min, max) that adds a ValidateRange attribute to the dynamic parameter.
This parameter is part of the 'ValidateRange' parameter set.

```yaml
Type: Int32[]
Parameter Sets: ValidateRange
Aliases:
Required: True
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ValidateLength
An array of two integers (min, max) that adds a ValidateLength attribute to the dynamic parameter.
This parameter is part of the 'ValidateLength' parameter set.

```yaml
Type: Int32[]
Parameter Sets: ValidateLength
Aliases:
Required: True
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Alias
An array of alias names for the dynamic parameter.

```yaml
Type: String[]
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ValueFromPipeline
Switch parameter that enables the dynamic parameter to accept values from pipeline input.

```yaml
Type:Switch
Parameter Sets:   (All)
Aliases:
Required: False
Position:Named
Default value: None
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type:ActionPreference
Parameter Sets:   (All)
Aliases:proga
Required: False
Position:Named
Default value: None
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String
### You can pipe parameter names to New-DynamicParameter.
## OUTPUTS

### PSCustomObject
### Returns a custom object with Name and Parameter properties, where Parameter contains
### the RuntimeDefinedParameter object ready for use in a DynamicParam block.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This function is part of the tcs.core module and is designed to simplify the creation
of dynamic parameters in advanced PowerShell functions.
It handles the complex
RuntimeDefinedParameter creation process and attribute configuration automatically.

## RELATED LINKS

[about_Functions_Advanced_Parameters]()

[about_Functions_DynamicParameters]()

