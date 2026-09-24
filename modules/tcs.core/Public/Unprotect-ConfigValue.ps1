<#
.SYNOPSIS
    Decrypts a value previously protected by Protect-ConfigValue.

.DESCRIPTION
    The Unprotect-ConfigValue function decrypts a protected string produced by
    Protect-ConfigValue. The protection method is read from the value itself, so Scope does
    not need to be given for values created by tcs.core 0.3.0 or later.

    Values created by tcs.core 0.2.x (without the 'tcs:v1' prefix) are still supported, with
    a warning that recommends protecting the value again. Their format shows which scope was
    used, so Scope does not need to match. LocalMachine values are tried with the computer
    name from COMPUTERNAME and [Environment]::MachineName, and with an empty name (what
    0.2.x used on Linux and macOS, where COMPUTERNAME is not set).

    A value that is neither format (for example plain text that was never protected) gives
    a clear error and no warning.

.PARAMETER EncryptedValue
    The protected string to decrypt.

.PARAMETER Scope
    Kept for compatibility. The scope of legacy (0.2.x) values is now detected from the
    value, so this parameter is ignored.

.PARAMETER Key
    The 32-byte key used with Protect-ConfigValue -Key.

.PARAMETER AsSecureString
    Returns the decrypted value as a SecureString instead of plain text.

.INPUTS
    System.String
    You can pipe one or more protected strings to Unprotect-ConfigValue.

.OUTPUTS
    System.String
    System.Security.SecureString (with -AsSecureString)

.EXAMPLE
    Unprotect-ConfigValue -EncryptedValue $protected

    Decrypts a value protected with Protect-ConfigValue.

.EXAMPLE
    $protected | Unprotect-ConfigValue -AsSecureString

    Decrypts the value and returns it as a SecureString.

.EXAMPLE
    Unprotect-ConfigValue -EncryptedValue $protected -Key $key

    Decrypts a value that was protected with a caller-managed key.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

    Decryption fails with an error if the value was protected by another user, on another
    machine, with a different key, or if it has been modified.

.LINK
    Protect-ConfigValue
#>
function Unprotect-ConfigValue {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'Only used for -AsSecureString, to return the decrypted value as a SecureString.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Scope',
        Justification = 'Kept for compatibility; the scope of legacy values is detected from the value.')]
    [CmdletBinding()]
    [OutputType([System.String], [System.Security.SecureString])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$EncryptedValue,

        [Parameter()]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope = 'CurrentUser',

        [Parameter()]
        [ValidateCount(32, 32)]
        [byte[]]$Key,

        [Parameter()]
        [switch]$AsSecureString
    )

    process {
        try {
            $parts = $EncryptedValue.Split(':')
            if ($parts.Count -eq 4 -and ('{0}:{1}' -f $parts[0], $parts[1]) -eq $script:ProtectedValuePrefix) {
                $method = $parts[2]
                $protectedBytes = [Convert]::FromBase64String($parts[3])

                switch ($method) {
                    'aes-key' {
                        if (-not $Key) {
                            throw 'This value was protected with a caller-supplied key. Pass the same key with -Key.'
                        }
                        $plainBytes = Unprotect-BytesWithKey -Data $protectedBytes -MasterKey $Key
                    }
                    { $_ -in 'dpapi-cu', 'dpapi-lm' } {
                        if (-not (Test-IsWindowsPlatform)) {
                            throw 'This value was protected with Windows DPAPI and can only be decrypted on Windows.'
                        }
                        Initialize-DataProtection
                        $dpapiScope = if ($method -eq 'dpapi-lm') {
                            [System.Security.Cryptography.DataProtectionScope]::LocalMachine
                        }
                        else {
                            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
                        }
                        $plainBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($protectedBytes, $script:DpapiEntropy, $dpapiScope)
                    }
                    { $_ -in 'aes-cu', 'aes-lm' } {
                        $keyScope = if ($method -eq 'aes-lm') { 'LocalMachine' } else { 'CurrentUser' }
                        $masterKey = Get-ProtectionKey -Scope $keyScope
                        $plainBytes = Unprotect-BytesWithKey -Data $protectedBytes -MasterKey $masterKey
                    }
                    default {
                        throw "Unknown protection method '$method'."
                    }
                }

                $plaintext = [System.Text.Encoding]::UTF8.GetString($plainBytes)
                [Array]::Clear($plainBytes, 0, $plainBytes.Length)
            }
            else {
                $secureString = ConvertFrom-LegacyProtectedValue -Value $EncryptedValue
                if ($AsSecureString) {
                    return $secureString
                }
                return [System.Net.NetworkCredential]::new('', $secureString).Password
            }

            if ($AsSecureString) {
                return (ConvertTo-SecureString -String $plaintext -AsPlainText -Force)
            }
            return $plaintext
        }
        catch {
            Write-Error -Message "Failed to decrypt the provided value. $($_.Exception.Message)" -Exception $_.Exception
        }
    }
}
