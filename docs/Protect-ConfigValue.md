---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# Protect-ConfigValue

## SYNOPSIS
Encrypts a string value for secure config storage using DPAPI.

## SYNTAX

```
Protect-ConfigValue [-Value] <String> [[-Scope] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Protect-ConfigValue function encrypts a plaintext string for secure storage in
configuration files.
It uses Windows Data Protection API (DPAPI) to encrypt the value.
In 'CurrentUser' scope (default), the encrypted string can only be decrypted by the
same user on the same machine.
In 'LocalMachine' scope, a machine-derived key is used
so any user on the same machine can decrypt the value.

## EXAMPLES

### EXAMPLE 1
```
Protect-ConfigValue -Value "MySecretPassword"
Encrypts the string using the current user's DPAPI context. Only the same user on the
same machine can decrypt it.
```

### EXAMPLE 2
```
"api-key-12345" | Protect-ConfigValue -Scope 'LocalMachine'
Encrypts the string using a machine-derived key. Any user on the same machine can
decrypt it using Unprotect-ConfigValue with the LocalMachine scope.
```

### EXAMPLE 3
```
$encrypted = Protect-ConfigValue -Value "ConnectionString" -Scope 'CurrentUser'
Stores the encrypted value in a variable for later use in configuration files.
```

## PARAMETERS

### -Value
The plaintext string value to protect.
This value will be encrypted and returned as
an encrypted standard string.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: True
Position: 1Default
Default value: None
Default value: None
Accept pipeline input: False
input:False
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
Accept wildcard characters: False
```

### -Scope
The DPAPI scope to use for encryption.
Valid values are 'CurrentUser' (default) and
'LocalMachine'.
CurrentUser scope ties decryption to the current user account.
LocalMachine scope uses a machine-derived key allowing any user on the same machine
to decrypt the value.

```yaml
Type:String
Parameter Sets:   (All)
Aliases:
Required: False
Position: 2Default
Default value: None
Default value: CurrentUser
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

### System.String
### You can pipe one or more plaintext strings to Protect-ConfigValue.
## OUTPUTS

### System.String
### Returns the encrypted string representation of the input value.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

CurrentUser scope uses DPAPI user context and is only decryptable by the same user
on the same machine.
LocalMachine scope uses a SHA256 key derived from the machine
name and can be decrypted by any user on the same machine.

This function is part of the tcs.core module and is designed to work in tandem with
Unprotect-ConfigValue for secure configuration value storage.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

