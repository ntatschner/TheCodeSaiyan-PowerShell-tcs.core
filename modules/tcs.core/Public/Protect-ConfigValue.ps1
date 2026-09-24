<#
.SYNOPSIS
    Encrypts a string value for secure storage in configuration files.

.DESCRIPTION
    The Protect-ConfigValue function encrypts a plaintext string and returns a self-describing
    protected string ('tcs:v1:<method>:<data>') that Unprotect-ConfigValue can decrypt.

    Windows:
      Uses the Windows Data Protection API (DPAPI).
      - CurrentUser: only the same user on the same machine can decrypt.
      - LocalMachine: any user on the same machine can decrypt.

    Linux and macOS (DPAPI is not available):
      Uses AES-256-CBC with HMAC-SHA256 authentication and a random 32-byte key file.
      - CurrentUser: key stored in the user's config folder
        (~/.config/PowerShell/Config/tcs.core/protection.key, mode 600). Created on first use.
      - LocalMachine: key stored at /etc/tcs.core/protection.key (mode 644, override with
        the TCS_MACHINE_KEY_PATH environment variable). Must be created once by root.

    Any platform:
      Supply -Key to encrypt with your own 32-byte key, for example to share a protected
      value between machines or with a CI pipeline. The same key is required to decrypt.

.PARAMETER Value
    The plaintext string value to protect.

.PARAMETER Scope
    Who can decrypt the value: 'CurrentUser' (default) or 'LocalMachine'.

.PARAMETER Key
    A 32-byte key to encrypt with instead of the platform key store.

.INPUTS
    System.String
    You can pipe one or more plaintext strings to Protect-ConfigValue.

.OUTPUTS
    System.String
    Returns the protected string.

.EXAMPLE
    Protect-ConfigValue -Value "MySecretPassword"

    Encrypts the string so that only the current user on this machine can decrypt it.

.EXAMPLE
    "api-key-12345" | Protect-ConfigValue -Scope 'LocalMachine'

    Encrypts the string so that any user on this machine can decrypt it.

.EXAMPLE
    $key = [byte[]]::new(32); [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
    $protected = Protect-ConfigValue -Value "ConnectionString" -Key $key

    Encrypts the string with a caller-managed key that can be used on any machine.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

    Values produced by tcs.core 0.2.x (no 'tcs:v1' prefix) can still be read by
    Unprotect-ConfigValue; protect them again to move them to the new format.

.LINK
    Unprotect-ConfigValue
#>
function Protect-ConfigValue {
    [CmdletBinding(DefaultParameterSetName = 'Scope')]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$Value,

        [Parameter(ParameterSetName = 'Scope')]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope = 'CurrentUser',

        [Parameter(Mandatory = $true, ParameterSetName = 'Key')]
        [ValidateCount(32, 32)]
        [byte[]]$Key
    )

    process {
        $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        try {
            if ($PSCmdlet.ParameterSetName -eq 'Key') {
                $method = 'aes-key'
                $protectedBytes = Protect-BytesWithKey -Data $plainBytes -MasterKey $Key
            }
            elseif (Test-IsWindowsPlatform) {
                Initialize-DataProtection
                if ($Scope -eq 'LocalMachine') {
                    $method = 'dpapi-lm'
                    $dpapiScope = [System.Security.Cryptography.DataProtectionScope]::LocalMachine
                }
                else {
                    $method = 'dpapi-cu'
                    $dpapiScope = [System.Security.Cryptography.DataProtectionScope]::CurrentUser
                }
                $protectedBytes = [System.Security.Cryptography.ProtectedData]::Protect($plainBytes, $script:DpapiEntropy, $dpapiScope)
            }
            else {
                $method = if ($Scope -eq 'LocalMachine') { 'aes-lm' } else { 'aes-cu' }
                $masterKey = Get-ProtectionKey -Scope $Scope -Create
                $protectedBytes = Protect-BytesWithKey -Data $plainBytes -MasterKey $masterKey
            }
        }
        finally {
            [Array]::Clear($plainBytes, 0, $plainBytes.Length)
        }

        return '{0}:{1}:{2}' -f $script:ProtectedValuePrefix, $method, [Convert]::ToBase64String($protectedBytes)
    }
}
