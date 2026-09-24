---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Start-TcsTelemetry

## SYNOPSIS
Starts timing one run of a command for telemetry and returns a token for Complete-TcsTelemetry.

## SYNTAX

```
Start-TcsTelemetry [[-CommandName] <String>] [[-ModuleName] <String>] [[-ModuleVersion] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Start-TcsTelemetry function is the first half of the telemetry wrapper for commands in
tcs modules.
Call it once at the start of a command (in the begin block of a pipeline
function), keep the token it returns, and pass the token to Complete-TcsTelemetry when the
command ends.
For commands without begin/process/end blocks, Invoke-TcsCommand does both
in one call.

The command, module and version are taken from the calling command when they are not
given.

Only the outermost run is reported.
When an exported command calls another exported
command of the same module, the inner run returns a token with IsOutermost = $false and
sends nothing, so one user action is one event.
Commands of other modules are reported
separately.

Telemetry never breaks the caller: if anything goes wrong, a token is still returned and
the failure is written to the verbose stream.
Nothing is sent when telemetry is turned
off; see Invoke-TelemetryCollection.

## EXAMPLES

### EXAMPLE 1
```
function Get-Widget {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)][string]$Name)
    begin {
        $telemetry = Start-TcsTelemetry
    }
    process {
        Invoke-TcsCommand -Token $telemetry -ScriptBlock {
            Get-Item -Path $Name
        }
    }
    end {
        Complete-TcsTelemetry -Token $telemetry
    }
}
```

A pipeline function: one event is sent for the whole pipeline run.
Invoke-TcsCommand
-Token records errors in each process block; a terminating error completes the run as
failed.

### EXAMPLE 2
```
begin { $telemetry = Start-TcsTelemetry }
process {
    try { Set-Thing -Name $Name -ErrorAction Stop }
    catch { Complete-TcsTelemetry -Token $telemetry -ErrorRecord $_; throw }
}
end { Complete-TcsTelemetry -Token $telemetry }
```

Completes the run by hand, as failed when an error is caught.

## PARAMETERS

### -CommandName
The name reported for the command.
Defaults to the name of the calling command.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleName
The module the command belongs to.
Defaults to the module of the calling command.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleVersion
The module version.
Defaults to the version of the calling command's module.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
### This function does not accept pipeline input.
## OUTPUTS

### Tcs.TelemetryToken
### Id, CommandName, ModuleName, ModuleVersion, IsOutermost, Failed, Completed and Exception.
### Assign it to a variable so it is not written to the pipeline.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

## RELATED LINKS

[Complete-TcsTelemetry]()

[Invoke-TcsCommand]()

