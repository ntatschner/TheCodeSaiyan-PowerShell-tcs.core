---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Complete-TcsTelemetry

## SYNOPSIS
Completes a run started with Start-TcsTelemetry and sends its telemetry event.

## SYNTAX

```
Complete-TcsTelemetry [-Token] <PSObject> [[-ErrorRecord] <Object>] [-Failed]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Complete-TcsTelemetry function stops the timer for a token from Start-TcsTelemetry and
sends one event (success or failure, duration, and the exception type on failure).
Call it
at the end of the command, normally in the end block.

The run is reported as failed when -Failed or -ErrorRecord is given, or when
Invoke-TcsCommand -Token saw an error during the run.

A token is completed only once; later calls do nothing.
Tokens of nested runs
(IsOutermost = $false) send nothing.
Telemetry never breaks the caller: errors are written
to the verbose stream only, and nothing is written to the pipeline.

## EXAMPLES

### EXAMPLE 1
```
end {
    Complete-TcsTelemetry -Token $telemetry -Failed:($failures -gt 0)
}
```

Completes the run, as failed when the command counted failures itself.

### EXAMPLE 2
```
catch {
    Complete-TcsTelemetry -Token $telemetry -ErrorRecord $_
    throw
}
```

Reports the caught error's type and rethrows it.

## PARAMETERS

### -Token
The token returned by Start-TcsTelemetry.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ErrorRecord
The error that ended the run (an ErrorRecord or Exception).
The run is reported as failed
and only the exception type name is sent.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Failed
Reports the run as failed.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

### Tcs.TelemetryToken
### You can pipe a token to Complete-TcsTelemetry.
## OUTPUTS

### None
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

## RELATED LINKS

[Start-TcsTelemetry]()

[Invoke-TcsCommand]()

