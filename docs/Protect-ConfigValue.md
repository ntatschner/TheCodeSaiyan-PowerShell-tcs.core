---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Protect-ConfigValue

## SYNOPSIS
Encrypts a string value for secure storage in configuration files.

## SYNTAX

### Scope (Default)
```
Protect-ConfigValue [-Value] <String> [-Scope <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### Key
```
Protect-ConfigValue [-Value] <String> -Key <Byte[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Protect-ConfigValue function encrypts a plaintext string and returns a self-describing
protected string ('tcs:v1:\<method\>:\<data\>') that Unprotect-ConfigValue can decrypt.

Windows:
  Uses the Windows Data Protection API (DPAPI).
  - CurrentUser: only the same user on the same machine can decrypt.
  - LocalMachine: any user on the same machine can decrypt.

Linux and macOS (DPAPI is not available):
  Uses AES-256-CBC with HMAC-SHA256 authentication and a random 32-byte key file.
  - CurrentUser: key stored in the user's config folder
    (~/.config/PowerShell/Config/tcs.core/protection.key, mode 600).
Created on first use.
  - LocalMachine: key stored at /etc/tcs.core/protection.key (mode 644, override with
    the TCS_MACHINE_KEY_PATH environment variable).
Must be created once by root.

Any platform:
  Supply -Key to encrypt with your own 32-byte key, for example to share a protected
  value between machines or with a CI pipeline.
The same key is required to decrypt.

## EXAMPLES

### EXAMPLE 1
```
Protect-ConfigValue -Value "MySecretPassword"
```

Encrypts the string so that only the current user on this machine can decrypt it.

### EXAMPLE 2
```
"api-key-12345" | Protect-ConfigValue -Scope 'LocalMachine'
```

Encrypts the string so that any user on this machine can decrypt it.

### EXAMPLE 3
```
$key = [byte[]]::new(32); [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
$protected = Protect-ConfigValue -Value "ConnectionString" -Key $key
```

Encrypts the string with a caller-managed key that can be used on any machine.

## PARAMETERS

### -Value
The plaintext string value to protect.

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
Who can decrypt the value: 'CurrentUser' (default) or 'LocalMachine'.

```yaml
Type: String
Parameter Sets: Scope
Aliases:

Required: False
Position: Named
Default value: CurrentUser
Accept pipeline input: False
Accept wildcard characters: False
```

### -Key
A 32-byte key to encrypt with instead of the platform key store.

```yaml
Type: Byte[]
Parameter Sets: Key
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

### System.String
### You can pipe one or more plaintext strings to Protect-ConfigValue.
## OUTPUTS

### System.String
### Returns the protected string.
## NOTES
Author: Nigel Tatschner
Company: TheCodeSaiyan

Values produced by tcs.core 0.2.x (no 'tcs:v1' prefix) can still be read by
Unprotect-ConfigValue; protect them again to move them to the new format.

## RELATED LINKS

[Unprotect-ConfigValue]()

