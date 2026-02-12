<#
.SYNOPSIS
    Encrypts a string value for secure config storage using DPAPI.

.DESCRIPTION
    The Protect-ConfigValue function encrypts a plaintext string for secure storage in
    configuration files. It uses Windows Data Protection API (DPAPI) to encrypt the value.
    In 'CurrentUser' scope (default), the encrypted string can only be decrypted by the
    same user on the same machine. In 'LocalMachine' scope, a machine-derived key is used
    so any user on the same machine can decrypt the value.

.PARAMETER Value
    The plaintext string value to protect. This value will be encrypted and returned as
    an encrypted standard string.

.PARAMETER Scope
    The DPAPI scope to use for encryption. Valid values are 'CurrentUser' (default) and
    'LocalMachine'. CurrentUser scope ties decryption to the current user account.
    LocalMachine scope uses a machine-derived key allowing any user on the same machine
    to decrypt the value.

.INPUTS
    System.String
    You can pipe one or more plaintext strings to Protect-ConfigValue.

.OUTPUTS
    System.String
    Returns the encrypted string representation of the input value.

.EXAMPLE
    Protect-ConfigValue -Value "MySecretPassword"
    Encrypts the string using the current user's DPAPI context. Only the same user on the
    same machine can decrypt it.

.EXAMPLE
    "api-key-12345" | Protect-ConfigValue -Scope 'LocalMachine'
    Encrypts the string using a machine-derived key. Any user on the same machine can
    decrypt it using Unprotect-ConfigValue with the LocalMachine scope.

.EXAMPLE
    $encrypted = Protect-ConfigValue -Value "ConnectionString" -Scope 'CurrentUser'
    Stores the encrypted value in a variable for later use in configuration files.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

    CurrentUser scope uses DPAPI user context and is only decryptable by the same user
    on the same machine. LocalMachine scope uses a SHA256 key derived from the machine
    name and can be decrypted by any user on the same machine.

    This function is part of the tcs.core module and is designed to work in tandem with
    Unprotect-ConfigValue for secure configuration value storage.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function Protect-ConfigValue {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'Intentional: this function encrypts plaintext config values for secure storage via DPAPI.')]
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Value,

        [Parameter()]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope = 'CurrentUser'
    )

    process {
        $secureString = ConvertTo-SecureString -String $Value -AsPlainText -Force

        if ($Scope -eq 'LocalMachine') {
            $keyBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($env:COMPUTERNAME + 'tcs.core')
            )
            $encryptedString = ConvertFrom-SecureString -SecureString $secureString -Key $keyBytes
        }
        else {
            $encryptedString = ConvertFrom-SecureString -SecureString $secureString
        }

        return $encryptedString
    }
}
