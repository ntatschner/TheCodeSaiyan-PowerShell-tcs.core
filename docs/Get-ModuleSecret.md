---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Get-ModuleSecret

## SYNOPSIS
Reads a secret or credential saved with Set-ModuleSecret.

## SYNTAX

```
Get-ModuleSecret [-ModuleName] <String> [-Name] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Get-ModuleSecret function decrypts a secret saved for a module with Set-ModuleSecret
and returns it as the type that was saved: a SecureString, or a PSCredential.
The value
is never returned in plain text.

If no secret with that name is saved, or it cannot be decrypted (for example it was
saved by another user or on another machine), a non-terminating error is written.
Use
-ErrorAction SilentlyContinue to get nothing instead.

## EXAMPLES

### EXAMPLE 1
```
$token = Get-ModuleSecret -ModuleName 'tcs.jira' -Name 'ApiToken'
```

Returns the saved token as a SecureString.

### EXAMPLE 2
```
$credential = Get-ModuleSecret -ModuleName 'tcs.confluence' -Name 'Default' -ErrorAction SilentlyContinue
if (-not $credential) { $credential = Get-Credential }
```

Uses the saved credential, or asks for one when none is saved.

## PARAMETERS

### -ModuleName
The module the secret belongs to, for example 'tcs.jira'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name the secret was saved under.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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

### System.Security.SecureString
### System.Management.Automation.PSCredential
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

## RELATED LINKS

[Set-ModuleSecret]()

[Remove-ModuleSecret]()

