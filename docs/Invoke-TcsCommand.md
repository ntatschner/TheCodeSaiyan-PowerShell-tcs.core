---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Invoke-TcsCommand

## SYNOPSIS
Runs the body of a tcs command and records anonymous telemetry for it.

## SYNTAX

### Command (Default)
```
Invoke-TcsCommand [-ScriptBlock] <ScriptBlock> [-CommandName <String>] [-ModuleName <String>]
 [-ModuleVersion <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Token
```
Invoke-TcsCommand [-ScriptBlock] <ScriptBlock> -Token <PSObject> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Invoke-TcsCommand function replaces the telemetry boilerplate in tcs module commands.
Wrap the body of a command in it:

  function Get-Widget {
      \[CmdletBinding()\]
      param(\[string\]$Name)
      Invoke-TcsCommand -ScriptBlock {
          Get-Item -Path $Name
      }
  }

The script block runs in the scope of the calling command (it is dot-sourced), so it
reads and sets the command's variables as if it were written inline, and $PSCmdlet,
$_ and ShouldProcess work as usual.
Two automatic variables are different inside the
script block: $PSBoundParameters and $MyInvocation describe the script block, not the
command.
Copy them to a variable before Invoke-TcsCommand if the body needs them.

What it does:
  - Writes exactly what the script block outputs, unchanged (collections are not
    unrolled or wrapped), and nothing else.
  - Reports the run as failed when the script block throws a terminating error or writes
    a non-terminating error (Write-Error or a cmdlet error) that reaches the error stream.
    Errors that are caught, or silenced with -ErrorAction SilentlyContinue/Ignore, do not
    count.
Errors written directly with $PSCmdlet.WriteError() bypass it; use the -Token
    form and Complete-TcsTelemetry -Failed for those.
  - Rethrows terminating errors unchanged, and passes non-terminating errors through.
  - Reports only the outermost run: when an exported command calls another exported
    command of the same module, the inner run sends nothing (it is skipped, not tagged).
  - Never fails or changes the command because of telemetry; telemetry problems are
    written to the verbose stream only.

Without -Token, one call is one run: it starts and completes the telemetry itself.
The
command, module and version are taken from the calling command.

With -Token (from Start-TcsTelemetry), it only records errors on that token.
Use this in
the process block of pipeline functions, and complete the token in the end block.
If the
script block throws, or the pipeline is stopped early (for example by Select-Object
-First), the token is completed here, because the end block will not run.

## EXAMPLES

### EXAMPLE 1
```
function Remove-Widget {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][string]$Name)
    $bound = $PSBoundParameters
    Invoke-TcsCommand -ScriptBlock {
        if ($PSCmdlet.ShouldProcess($Name, 'Remove widget')) {
            Invoke-RestMethod -Method Delete -Uri "https://api.example.com/widgets/$Name"
        }
        Write-Verbose "Parameters: $($bound.Keys -join ', ')"
    }
}
```

A simple function.
$PSBoundParameters is copied to $bound first because inside the script
block it describes the script block.

### EXAMPLE 2
```
function Get-Widget {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)][string]$Name)
    begin { $telemetry = Start-TcsTelemetry }
    process {
        Invoke-TcsCommand -Token $telemetry -ScriptBlock {
            Invoke-RestMethod -Uri "https://api.example.com/widgets/$Name"
        }
    }
    end { Complete-TcsTelemetry -Token $telemetry }
}
```

A pipeline function: one event for the whole pipeline run, failed if any item failed.

## PARAMETERS

### -ScriptBlock
The body of the command.

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

### -CommandName
The name reported for the command.
Defaults to the name of the calling command.

```yaml
Type: String
Parameter Sets: Command
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleName
The module the command belongs to.
Defaults to the module of the calling command.

```yaml
Type: String
Parameter Sets: Command
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleVersion
The module version.
Defaults to the version of the calling command's module.

```yaml
Type: String
Parameter Sets: Command
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Token
A token from Start-TcsTelemetry.
Errors are recorded on it and the token is completed
only if the script block throws or the pipeline is stopped.

```yaml
Type: PSObject
Parameter Sets: Token
Aliases:

Required: True
Position: Named
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

### System.Object
### The output of the script block.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

Invoke-TelemetryCollection is unchanged and still works for existing commands.

Lines that native programs in the script block write to stderr are passed on through the
error stream (without the wrapper, PowerShell 7 writes them straight to the console) and
never mark the run as failed.
On Windows PowerShell 5.1, a native program that writes to
stderr while $ErrorActionPreference is 'Stop' raises a NativeCommandError, as it does
whenever its errors are redirected; set $ErrorActionPreference = 'Continue' inside the
script block before such calls.

## RELATED LINKS

[Start-TcsTelemetry]()

[Complete-TcsTelemetry]()

