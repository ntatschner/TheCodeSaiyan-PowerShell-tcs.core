---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# Write-Log

## SYNOPSIS
Writes a structured log message to the console and/or a log file.

## SYNTAX

```
Write-Log [-Message] <String> [-Level <String>] [-LogPath <String>] [-Component <String>] [-NoConsole]
 [-DateFormat <String>] [-UseUtc] [-PassThru] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Write-Log function provides structured logging with severity levels, timestamps,
and optional component prefixes.
Messages can be written to the console, to a log file,
or both.
The function supports pipeline input for batch logging
and uses appropriate PowerShell output streams for Debug and Verbose levels.

## EXAMPLES

### EXAMPLE 1
```
Write-Log -Message "Application started successfully."
```

Writes an Info-level message to the console with a timestamp.

### EXAMPLE 2
```
Write-Log -Message "Connection failed" -Level Error -Component "Network" -LogPath "C:\Logs\app.log"
```

Writes an Error-level message with a component prefix to the error stream and to the
specified log file.

### EXAMPLE 3
```
"Step 1 complete", "Step 2 complete" | Write-Log -Level Info -LogPath "C:\Logs\steps.log" -NoConsole
```

Pipes multiple messages to be logged silently to a file without console output.

## PARAMETERS

### -Message
The log message to write.
Accepts pipeline input, allowing multiple messages to be
logged in sequence.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Level
The severity level of the log message.
Valid values are 'Info', 'Warning', 'Error',
'Debug', and 'Verbose'.
Defaults to 'Info'.
Info is written to the host in colour; the
other levels use their PowerShell streams: Warning uses Write-Warning, Error uses
Write-Error (a non-terminating error, so -ErrorAction and $ErrorActionPreference apply),
Debug uses Write-Debug and Verbose uses Write-Verbose.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Info
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogPath
An optional file path to append the formatted log message to.
If the file or its parent
directory does not exist, they will be created automatically.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Component
An optional component or module name prefix included in the formatted log message.
When specified, the message is formatted as \[$timestamp\]\[$Level\]\[$Component\] $Message.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoConsole
When specified, suppresses console output and only writes to the log file.
Requires
LogPath to be specified for any output to occur.

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

### -DateFormat
The timestamp format string used for log entries.
Defaults to 'yyyy-MM-dd HH:mm:ss'.
Accepts any valid .NET DateTime format string.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Yyyy-MM-dd HH:mm:ss
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseUtc
Writes timestamps in UTC instead of local time.

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

### -PassThru
Returns the formatted log line.

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

### System.String
### You can pipe one or more strings to Write-Log.
## OUTPUTS

### None, or System.String when PassThru is specified.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

File writes append with shared read/write access, so several processes can log to the
same file.
Files are written as UTF-8 without a byte order mark.
The file is written
before the console output.

Since tcs.core 0.4.0, Warning and Error levels use the warning and error streams instead
of coloured host text, so they can be captured, redirected and suppressed.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

