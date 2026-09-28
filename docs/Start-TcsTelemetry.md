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
command ends: in a catch block with -ErrorRecord when the command fails, and in a finally
(or end) block otherwise.
Complete-TcsTelemetry does nothing for a token that is already
complete, so completing it in both places is safe.

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
    param([string]$Name)
    $telemetry = Start-TcsTelemetry
    try {
        Get-Item -Path $Name -ErrorAction Stop
    }
    catch {
        Complete-TcsTelemetry -Token $telemetry -ErrorRecord $_
        throw
    }
    finally {
        Complete-TcsTelemetry -Token $telemetry
    }
}
```

A command without pipeline blocks: the run is completed as failed in catch, and as
successful in finally otherwise.

### EXAMPLE 2
```
function Set-Widget {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)][string]$Name)
    begin {
        $telemetry = Start-TcsTelemetry
        $lastError = $null
    }
    process {
        $completed = $false
        try {
            Set-Thing -Name $Name -ErrorAction Stop
            $completed = $true
        }
        catch {
            $lastError = $_
            throw
        }
        finally {
            if (-not $completed) {
                Complete-TcsTelemetry -Token $telemetry -ErrorRecord $lastError
            }
        }
    }
    end {
        Complete-TcsTelemetry -Token $telemetry -ErrorRecord $lastError
    }
}
```

A pipeline function: one event is sent for the whole pipeline run.
The end block does not
run when a later command stops the pipeline (for example Select-Object -First), or after
$PSCmdlet.ThrowTerminatingError or $PSCmdlet.WriteError with -ErrorAction Stop, which also
skip catch.
The finally block completes the run in those cases.
Set $lastError before
calling $PSCmdlet.ThrowTerminatingError so the run is reported as failed.

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

