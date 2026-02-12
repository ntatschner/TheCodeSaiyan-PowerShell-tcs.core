---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# Invoke-TelemetryCollection

## SYNOPSIS
Collects and sends telemetry data for module usage tracking.

## SYNTAX

```
Invoke-TelemetryCollection [[-ModuleName] <String>] [[-ModuleVersion] <String>] [[-ModulePath] <String>]
 [[-CommandName] <String>] [-ExecutionID] <String> [-Stage] <String> [[-Failed] <Boolean>]
 [[-Exception] <String>] [-Minimal] [-ClearTimer] [-URI] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Invoke-TelemetryCollection function gathers system, PowerShell, and module-specific
telemetry data for usage analytics.
It collects non-identifying hardware information,
operating system details, PowerShell version information, and module execution metrics.
The data is sent asynchronously to a specified URI endpoint for analysis while preserving
user privacy through anonymization techniques.

## EXAMPLES

### EXAMPLE 1
```
Invoke-TelemetryCollection -ModuleName "tcs.core" -ExecutionID "12345" -Stage "Start" -URI "https://telemetry.example.com/api"
```

Starts telemetry collection for the tcs.core module.

### EXAMPLE 2
```
Invoke-TelemetryCollection -ExecutionID "12345" -Stage "End" -Failed $true -Exception $_.Exception -URI $TelemetryURI
```

Records the end of execution with failure information.

## PARAMETERS

### -ModuleName
The name of the module generating the telemetry data.
Defaults to 'UnknownModule'
if not specified.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 1Default
Default value: None
Default value: UnknownModule
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ModuleVersion
The version of the module generating the telemetry data.
Defaults to 'UnknownModuleVersion'
if not specified.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 2Default
Default value: None
Default value: UnknownModuleVersion
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ModulePath
The file system path where the module is installed.
Defaults to 'UnknownModulePath'
if not specified.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 3Default
Default value: None
Default value: UnknownModulePath
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -CommandName
The name of the command or function being executed.
Defaults to 'UnknownCommand'
if not specified.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 4Default
Default value: None
Default value: UnknownCommand
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -ExecutionID
A unique identifier for the current execution session.
This is mandatory and used
to correlate telemetry events across different stages.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 5Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Stage
The current stage of execution.
Valid values are:
- 'Start': Beginning of command execution
- 'In-Progress': During command execution
- 'End': Completion of command execution  
- 'Module-Load': Module loading/import

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 6Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Failed
Boolean value indicating whether the operation failed.
Defaults to $false.

```yaml
Type:Boolean
Parameter Sets:   (All)
Aliases:
Required: False
Position: 7Default
Default value: None
Default value: False
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Exception
String containing exception details if the operation failed.
Used for error tracking.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 8Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Minimal
Switch parameter that limits the telemetry data collected to essential information only,
further enhancing privacy protection.

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

### -ClearTimer
Switch parameter that forces clearing and resetting of execution timing variables.

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

### -URI
The endpoint URI where telemetry data will be sent.
This parameter is mandatory.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 9Default
Default value: None
Default value: None
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

### None
### This function does not accept pipeline input.
## OUTPUTS

### None
### This function does not return any output. It sends data asynchronously via background jobs.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This is a private function used internally by the tcs.core module for telemetry
collection.
All data collected is anonymized and used solely for improving module
functionality and user experience.
No personally identifiable information is collected.

The function uses background jobs to ensure telemetry collection doesn't impact
module performance or user experience.

## RELATED LINKS
