---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Unprotect-ConfigValue

## SYNOPSIS
Decrypts a value previously protected by Protect-ConfigValue.

## SYNTAX

```
Unprotect-ConfigValue [-EncryptedValue] <String> [-Scope <String>] [-Key <Byte[]>] [-AsSecureString]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Unprotect-ConfigValue function decrypts a protected string produced by
Protect-ConfigValue.
The protection method is read from the value itself, so Scope does
not need to be given for values created by tcs.core 0.3.0 or later.

Values created by tcs.core 0.2.x (without the 'tcs:v1' prefix) are still supported, with
a warning that recommends protecting the value again.
Their format shows which scope was
used, so Scope does not need to match.
LocalMachine values are tried with the computer
name from COMPUTERNAME and \[Environment\]::MachineName, and with an empty name (what
0.2.x used on Linux and macOS, where COMPUTERNAME is not set).

A value that is neither format (for example plain text that was never protected) gives
a clear error and no warning.

## EXAMPLES

### EXAMPLE 1
```
Unprotect-ConfigValue -EncryptedValue $protected
```

Decrypts a value protected with Protect-ConfigValue.

### EXAMPLE 2
```
$protected | Unprotect-ConfigValue -AsSecureString
```

Decrypts the value and returns it as a SecureString.

### EXAMPLE 3
```
Unprotect-ConfigValue -EncryptedValue $protected -Key $key
```

Decrypts a value that was protected with a caller-managed key.

## PARAMETERS

### -EncryptedValue
The protected string to decrypt.

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

### -Scope
Kept for compatibility.
The scope of legacy (0.2.x) values is now detected from the
value, so this parameter is ignored.

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

### -Key
The 32-byte key used with Protect-ConfigValue -Key.

```yaml
Type: Byte[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsSecureString
Returns the decrypted value as a SecureString instead of plain text.

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
### You can pipe one or more protected strings to Unprotect-ConfigValue.
## OUTPUTS

### System.String
### System.Security.SecureString (with -AsSecureString)
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

Decryption fails with an error if the value was protected by another user, on another
machine, with a different key, or if it has been modified.

## RELATED LINKS

[Protect-ConfigValue]()

