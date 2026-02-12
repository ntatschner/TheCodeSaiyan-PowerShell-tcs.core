---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# Invoke-WithRetry

## SYNOPSIS
Executes a script block with automatic retry logic on failure.

## SYNTAX

```
Invoke-WithRetry [-ScriptBlock] <ScriptBlock> [[-MaxRetries] <Int32>] [[-DelaySeconds] <Int32>]
 [[-BackoffMultiplier] <Double>] [[-RetryableExceptions] <Type[]>] [[-OnRetry] <ScriptBlock>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Invoke-WithRetry function wraps a script block in retry logic, automatically
re-executing it when exceptions occur.
It supports configurable retry counts,
delays with optional exponential backoff, filtering by exception type, and an
optional callback on each retry.
If all retries are exhausted, the last exception
is rethrown.

## EXAMPLES

### EXAMPLE 1
```
Invoke-WithRetry -ScriptBlock { Get-Content "\\server\share\file.txt" } -MaxRetries 5 -DelaySeconds 3
```

Attempts to read a file up to 5 times with a 3-second delay between retries.

### EXAMPLE 2
```
Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri $uri } -MaxRetries 4 -DelaySeconds 1 -BackoffMultiplier 2
```

Calls a REST endpoint with exponential backoff: 1s, 2s, 4s, 8s delays between retries.

### EXAMPLE 3
```
$onRetry = { param($ex, $attempt) Write-Warning "Retry $attempt : $($ex.Message)" }
Invoke-WithRetry -ScriptBlock { Connect-Database } -MaxRetries 3 -RetryableExceptions @([System.Net.Sockets.SocketException]) -OnRetry $onRetry
```

Retries only on SocketException, invoking a warning callback on each retry.

## PARAMETERS

### -ScriptBlock
The script block to execute.
If execution throws an exception, the function will
retry according to the configured retry parameters.

```yaml
Type:ScriptBlock
Parameter Sets:   (All)
Aliases:
Required: True
Position: 1Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -MaxRetries
The maximum number of retry attempts after the initial failure.
Defaults to 3.

```yaml
Type:
Int32
Parameter Sets:   (All)
Aliases:
Required: False
Position: 2Default
Default value: None
Default value: 3
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -DelaySeconds
The base delay in seconds between retry attempts.
Defaults to 2.

```yaml
Type:
Int32
Parameter Sets:   (All)
Aliases:
Required: False
Position: 3Default
Default value: None
Default value: 2
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -BackoffMultiplier
A multiplier applied to the delay on each successive retry.
Set to a value greater
than 1 for exponential backoff (e.g., 2 doubles the delay each retry).
Defaults to 1
(constant delay).

```yaml
Type:Double
Parameter Sets:   (All)
Aliases:
Required: False
Position: 4Default
Default value: None
Default value: 1
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -RetryableExceptions
An optional array of .NET exception types to retry on.
When specified, only exceptions
matching one of these types will trigger a retry.
If omitted, all exceptions trigger
a retry.

```yaml
Type: Type[]
Parameter Sets:   (All)
Aliases:
Required: False
Position: 5Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: False
Accept wildcard characters: False
Accept wildcard characters: False
```

### -OnRetry
An optional script block invoked on each retry attempt.
It receives the current
exception as the first argument and the attempt number as the second argument.

```yaml
Type:ScriptBlock
Parameter Sets:   (All)
Aliases:
Required: False
Position: 6Default
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

### System.Object
### Returns the output of the successfully executed ScriptBlock.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

This function is part of the tcs.core module and provides robust retry logic
suitable for network operations, transient fault handling, and resilient scripting.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

