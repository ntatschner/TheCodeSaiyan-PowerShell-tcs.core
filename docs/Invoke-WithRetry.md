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
Invoke-WithRetry [-ScriptBlock] <ScriptBlock> [[-MaxRetries] <Int32>] [[-DelaySeconds] <Double>]
 [[-BackoffMultiplier] <Double>] [[-MaxDelaySeconds] <Double>] [[-RetryableExceptions] <Type[]>]
 [[-OnRetry] <ScriptBlock>] [[-RetryOnStatusCode] <Int32[]>] [[-ShouldRetry] <ScriptBlock>]
 [[-JitterPercent] <Int32>] [-RetryOnNonTerminatingError] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Invoke-WithRetry function wraps a script block in retry logic, automatically
re-executing it when exceptions occur.
It supports configurable retry counts,
delays with optional exponential backoff and jitter, filtering by exception type, by
HTTP status code or by a script block, and an optional callback on each retry.
If all
retries are exhausted, the last exception is rethrown.

HTTP-aware: when a failed request's response has a Retry-After header (a number of
seconds or an HTTP date), the wait is at least that long, up to MaxDelaySeconds.

Only terminating errors (exceptions) cause a retry.
Non-terminating errors, such as a
cmdlet that cannot find an item, do not, unless the command in the script block uses
-ErrorAction Stop or -RetryOnNonTerminatingError is used.

The output of the successful attempt is written exactly as the script block wrote it:
a collection written as a single object (for example , @(1)) stays a collection.

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
Exception types match subclasses too, so \[System.Net.WebException\] also matches its derived types.

### EXAMPLE 4
```
Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri $uri } -RetryOnStatusCode 429, 502, 503, 504 -DelaySeconds 1 -BackoffMultiplier 2 -JitterPercent 20
```

Retries throttled and unavailable responses (honouring Retry-After) with exponential
backoff and jitter; other HTTP errors such as 404 are thrown at once.

### EXAMPLE 5
```
Invoke-WithRetry -ScriptBlock { Get-Item -Path $path } -RetryOnNonTerminatingError -MaxRetries 5 -DelaySeconds 1
```

Retries until the item exists, although Get-Item writes a non-terminating error.

### EXAMPLE 6
```
$retryTransient = { param($errorRecord, $attempt) $errorRecord.Exception.Message -match 'timed out' }
Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri $uri } -ShouldRetry $retryTransient
```

Retries only errors whose message says the request timed out.

## PARAMETERS

### -ScriptBlock
The script block to execute.
If execution throws an exception, the function will
retry according to the configured retry parameters.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxRetries
The maximum number of retry attempts after the initial failure.
Defaults to 3.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -DelaySeconds
The delay in seconds before the first retry.
Fractions are allowed (e.g.
0.5).
Defaults to 2.

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 2
Accept pipeline input: False
Accept wildcard characters: False
```

### -BackoffMultiplier
A multiplier applied to the delay on each successive retry.
Set to a value greater
than 1 for exponential backoff (e.g., 2 doubles the delay each retry).
Defaults to 1
(constant delay).

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxDelaySeconds
The longest delay allowed between retries when backoff is used.
Defaults to 300.

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 300
Accept pipeline input: False
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
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnRetry
An optional script block invoked on each retry attempt.
It receives the current
exception as the first argument and the attempt number as the second argument.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RetryOnStatusCode
HTTP status codes to retry, for example 429, 502, 503 and 504.
An HTTP error with any
other status code (such as 400 or 404) is thrown at once.
Errors without an HTTP
response (DNS, connection or timeout failures) are still retried.
Works with the errors
of Invoke-RestMethod and Invoke-WebRequest on Windows PowerShell 5.1 and PowerShell 7.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShouldRetry
An optional script block that decides whether an error is retried.
It receives the
ErrorRecord as the first argument and the attempt number as the second, and the error is
retried only when it returns $true.
It is called after the RetryableExceptions and
RetryOnStatusCode checks, which must also allow the retry.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -JitterPercent
Adds a random extra delay of up to this percentage of each delay (0-100), so that many
clients do not retry at the same moment.
Defaults to 0 (no jitter).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -RetryOnNonTerminatingError
Treats a non-terminating error written by the script block (for example by Write-Error,
or a cmdlet without -ErrorAction Stop) as a failure, so it is retried.
Errors of failed
attempts are not shown; if every attempt fails, the last error is thrown as a
terminating error.
Without this switch, non-terminating errors are passed through and do
not cause a retry; add -ErrorAction Stop to the commands in the script block instead.

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

### System.Object
### Returns the output of the successfully executed ScriptBlock. Output of failed attempts
### is discarded.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

This function is part of the tcs.core module and provides robust retry logic
suitable for network operations, transient fault handling, and resilient scripting.

With -RetryOnNonTerminatingError, lines that native programs write to stderr are passed on
through the error stream and never fail an attempt.
On Windows PowerShell 5.1, a native
program that writes to stderr while $ErrorActionPreference is 'Stop' raises a
NativeCommandError, as it does whenever its errors are redirected; set
$ErrorActionPreference = 'Continue' inside the script block before such calls.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

