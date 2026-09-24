---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Set-ModuleSecret

## SYNOPSIS
Saves a secret or credential for a tcs module, encrypted for the current user.

## SYNTAX

### SecureString (Default)
```
Set-ModuleSecret [-ModuleName] <String> [-Name] <String> -SecureString <SecureString> [-Scope <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Credential
```
Set-ModuleSecret [-ModuleName] <String> [-Name] <String> -Credential <PSCredential> [-Scope <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-ModuleSecret function saves a SecureString (such as an API token) or a
PSCredential under a name, for one module.
The value is encrypted with
Protect-ConfigValue (DPAPI on Windows, AES-256 + HMAC on Linux/macOS) and stored in the
module's settings folder:

  \<ApplicationData\>/PowerShell/Config/\<ModuleName\>/Secrets/\<Name\>.json

An existing secret with the same name is replaced.
Read it back with Get-ModuleSecret,
which returns the same type that was saved.

## EXAMPLES

### EXAMPLE 1
```
Set-ModuleSecret -ModuleName 'tcs.jira' -Name 'ApiToken' -SecureString (Read-Host -AsSecureString -Prompt 'Token')
```

Saves an API token for tcs.jira.

### EXAMPLE 2
```
Set-ModuleSecret -ModuleName 'tcs.confluence' -Name 'Default' -Credential (Get-Credential)
```

Saves a user name and password for tcs.confluence.

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
The name of the secret, for example 'ApiToken'.
Letters, digits, '.', '_' and '-' only,
starting with a letter or digit.

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

### -SecureString
The secret to save.

```yaml
Type: SecureString
Parameter Sets: SecureString
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
The credential to save.
The user name is stored as it is; the password is encrypted.

```yaml
Type: PSCredential
Parameter Sets: Credential
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scope
Who can decrypt the secret: 'CurrentUser' (default) or 'LocalMachine'.
See
Protect-ConfigValue.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: CurrentUser
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
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

### None
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

## RELATED LINKS

[Get-ModuleSecret]()

[Remove-ModuleSecret]()

