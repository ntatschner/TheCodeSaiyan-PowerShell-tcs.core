<#
.SYNOPSIS
    Decrypts a value previously protected by Protect-ConfigValue.

.DESCRIPTION
    The Unprotect-ConfigValue function decrypts an encrypted string that was produced by
    Protect-ConfigValue. The Scope parameter must match the scope used during encryption.
    In 'CurrentUser' scope (default), DPAPI user context is used. In 'LocalMachine' scope,
    a machine-derived key is used for decryption.

.PARAMETER EncryptedValue
    The encrypted string to decrypt. This should be a value previously produced by
    Protect-ConfigValue.

.PARAMETER Scope
    The DPAPI scope that was used during encryption. Valid values are 'CurrentUser' (default)
    and 'LocalMachine'. This must match the scope used when the value was originally protected.

.INPUTS
    System.String
    You can pipe one or more encrypted strings to Unprotect-ConfigValue.

.OUTPUTS
    System.String
    Returns the decrypted plaintext string.

.EXAMPLE
    Unprotect-ConfigValue -EncryptedValue $encrypted
    Decrypts the value using the current user's DPAPI context.

.EXAMPLE
    $encrypted | Unprotect-ConfigValue -Scope 'LocalMachine'
    Decrypts a value that was encrypted with LocalMachine scope using the machine-derived key.

.EXAMPLE
    $plaintext = Unprotect-ConfigValue -EncryptedValue $encrypted -Scope 'CurrentUser'
    Decrypts the value and stores the plaintext result in a variable.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

    The Scope must match the scope used during encryption with Protect-ConfigValue.
    If the wrong scope, user, or machine is used, decryption will fail and an error
    will be written.

    This function is part of the tcs.core module and is designed to work in tandem with
    Protect-ConfigValue for secure configuration value storage.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function Unprotect-ConfigValue {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$EncryptedValue,

        [Parameter()]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope = 'CurrentUser'
    )

    process {
        try {
            if ($Scope -eq 'LocalMachine') {
                $keyBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                    [System.Text.Encoding]::UTF8.GetBytes($env:COMPUTERNAME + 'tcs.core')
                )
                $secureString = ConvertTo-SecureString -String $EncryptedValue -Key $keyBytes
            }
            else {
                $secureString = ConvertTo-SecureString -String $EncryptedValue
            }

            $plaintext = [System.Net.NetworkCredential]::new('', $secureString).Password
            return $plaintext
        }
        catch {
            Write-Error "Failed to decrypt the provided value. Ensure the correct Scope ('$Scope') is used and that decryption is performed by the appropriate user on the correct machine. Error: $_"
        }
    }
}
