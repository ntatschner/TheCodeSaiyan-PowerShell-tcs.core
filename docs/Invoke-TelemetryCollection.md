---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Invoke-TelemetryCollection

## SYNOPSIS
Records anonymous usage telemetry for a command or module load.

## SYNTAX

```
Invoke-TelemetryCollection [[-ModuleName] <String>] [[-ModuleVersion] <String>] [[-CommandName] <String>]
 [-ExecutionID] <String> [-Stage] <String> [[-Failed] <Boolean>] [[-Exception] <Object>] [-ClearTimer]
 [[-URI] <String>] [[-ApiKey] <String>] [[-Tags] <Hashtable>] [[-ModulePath] <String>] [-Minimal]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Invoke-TelemetryCollection function times a command and sends one anonymous event to
the tcs-telemetry ingestion API (POST, JSON, X-API-Key header) when the command ends or a
module loads.
Sending is asynchronous and never blocks or fails the caller.

Data sent:
  timestamp (UTC), command_name, module_name, version, duration_ms, success,
  error_type (exception type name only, never the message), ps_version, os_platform,
  host_name (a random installation ID, not the machine name) and tags
  (stage, ps_edition, ps_host, plus any -Tags given).
No user name, machine name, path, hardware identifier or error text is sent.

Nothing is sent when:
  - the TCS_TELEMETRY_OPTOUT environment variable is 1, true or yes;
  - the module's Telemetry setting is $false (Set-ModuleConfig -Telemetry $false).
The
    setting is read from the module's settings file even if the module has not called
    Get-ModuleConfig in this session;
  - no endpoint is configured (-URI, TCS_TELEMETRY_URI, or the TelemetryUri setting);
  - the endpoint is not HTTPS (http://localhost is allowed for testing).

Stages:
  Start        starts the timer for ExecutionID (nothing is sent)
  In-Progress  no action; deprecated (warns once per session), removal planned in 1.0
  End          stops the timer and sends the event
  Module-Load  sends an event with a duration of 0

## EXAMPLES

### EXAMPLE 1
```
$id = [guid]::NewGuid().ToString()
Invoke-TelemetryCollection -ModuleName 'tcs.jira' -ModuleVersion '0.1.0' -CommandName 'Get-JiraTicket' -ExecutionID $id -Stage Start
try {
    # command body
    Invoke-TelemetryCollection -ModuleName 'tcs.jira' -ModuleVersion '0.1.0' -CommandName 'Get-JiraTicket' -ExecutionID $id -Stage End
}
catch {
    Invoke-TelemetryCollection -ModuleName 'tcs.jira' -ModuleVersion '0.1.0' -CommandName 'Get-JiraTicket' -ExecutionID $id -Stage End -Failed $true -Exception $_
    throw
}
```

Times a command and reports success or failure.

## PARAMETERS

### -ModuleName
The name of the module sending telemetry.
Its settings (from Get-ModuleConfig) decide
whether telemetry is on and which endpoint is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: UnknownModule
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleVersion
The version of the module.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Unknown
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandName
The name of the command being run.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: UnknownCommand
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExecutionID
A unique ID that links the Start and End stages of one command run.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Stage
Start, In-Progress, End or Module-Load.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Failed
Whether the command failed.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Exception
The error (ErrorRecord, Exception or string).
Only its type name is sent.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClearTimer
On Start, restarts the timer even if one is already running for ExecutionID.

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

### -URI
Overrides the ingestion endpoint, e.g.
https://telemetry.example.com/ingest/powershell.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiKey
Overrides the API key sent in the X-API-Key header.
A value protected with
Protect-ConfigValue is decrypted before it is sent.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tags
Extra low-cardinality tags to send with the event.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModulePath
Deprecated and ignored (warns once per session); removal planned in tcs.core 1.0.
Paths
are no longer sent because they can contain user names.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Minimal
Deprecated and ignored (warns once per session); removal planned in tcs.core 1.0.
All
telemetry is now minimal.

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

### None
### This function does not accept pipeline input.
## OUTPUTS

### None
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

New commands should use Invoke-TcsCommand, or Start-TcsTelemetry and
Complete-TcsTelemetry, instead of calling this function directly.

## RELATED LINKS

[Invoke-TcsCommand]()

