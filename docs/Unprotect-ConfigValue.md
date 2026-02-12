---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version: https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
schema: 2.0.0
---

# Unprotect-ConfigValue

## SYNOPSIS
Decrypts a value previously protected by Protect-ConfigValue.

## SYNTAX

```
Unprotect-ConfigValue [-EncryptedValue] <String> [[-Scope] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
The Unprotect-ConfigValue function decrypts an encrypted string that was produced by
Protect-ConfigValue.
The Scope parameter must match the scope used during encryption.
In 'CurrentUser' scope (default), DPAPI user context is used.
In 'LocalMachine' scope,
a machine-derived key is used for decryption.

## EXAMPLES

### EXAMPLE 1
```
Unprotect-ConfigValue -EncryptedValue $encrypted
Decrypts the value using the current user's DPAPI context.
```

### EXAMPLE 2
```
$encrypted | Unprotect-ConfigValue -Scope 'LocalMachine'
Decrypts a value that was encrypted with LocalMachine scope using the machine-derived key.
```

### EXAMPLE 3
```
$plaintext = Unprotect-ConfigValue -EncryptedValue $encrypted -Scope 'CurrentUser'
Decrypts the value and stores the plaintext result in a variable.
```

## PARAMETERS

### -EncryptedValue
The encrypted string to decrypt.
This should be a value previously produced by
Protect-ConfigValue.

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
The DPAPI scope that was used during encryption.
Valid values are 'CurrentUser' (default)
and 'LocalMachine'.
This must match the scope used when the value was originally protected.

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
### You can pipe one or more encrypted strings to Unprotect-ConfigValue.
## OUTPUTS

### System.String
### Returns the decrypted plaintext string.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan
Version: 0.2.0

The Scope must match the scope used during encryption with Protect-ConfigValue.
If the wrong scope, user, or machine is used, decryption will fail and an error
will be written.

This function is part of the tcs.core module and is designed to work in tandem with
Protect-ConfigValue for secure configuration value storage.

## RELATED LINKS

[https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/](https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/)

