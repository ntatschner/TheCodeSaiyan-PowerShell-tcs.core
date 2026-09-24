---
external help file: tcs.core-help.xml
Module Name: tcs.core
online version:
schema: 2.0.0
---

# Remove-ModuleSecret

## SYNOPSIS
Deletes a secret or credential saved with Set-ModuleSecret.

## SYNTAX

```
Remove-ModuleSecret [-ModuleName] <String> [-Name] <String> [-ProgressAction <ActionPreference>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Remove-ModuleSecret function deletes the file that holds a secret saved for a module
with Set-ModuleSecret.
If no secret with that name is saved, a non-terminating error is
written.

## EXAMPLES

### EXAMPLE 1
```
Remove-ModuleSecret -ModuleName 'tcs.jira' -Name 'ApiToken'
```

Deletes the saved token.

### EXAMPLE 2
```
Remove-ModuleSecret -ModuleName 'tcs.jira' -Name 'ApiToken' -WhatIf
```

Shows what would be deleted.

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

[Set-ModuleSecret]()

[Get-ModuleSecret]()

