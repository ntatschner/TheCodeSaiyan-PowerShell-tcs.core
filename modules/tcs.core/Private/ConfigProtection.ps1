<#
.SYNOPSIS
    Internal encryption helpers used by Protect-ConfigValue and Unprotect-ConfigValue.

.DESCRIPTION
    - Windows: DPAPI through System.Security.Cryptography.ProtectedData.
    - Linux/macOS (or when a key is supplied): AES-256-CBC with a random IV, authenticated
      with HMAC-SHA256 (encrypt-then-MAC). Encryption and MAC keys are derived from a
      32-byte master key.

    Protected values are strings of the form 'tcs:v1:<method>:<base64>'.

.NOTES
    Private helpers for the tcs.core module. Written to run on Windows PowerShell 5.1
    (.NET Framework) and PowerShell 7+, so .NET Core-only APIs are avoided.
#>

$script:ProtectedValuePrefix = 'tcs:v1'
$script:DpapiEntropy = [System.Text.Encoding]::UTF8.GetBytes('tcs.core:v1')

function Initialize-DataProtection {
    [CmdletBinding()]
    [OutputType([void])]
    param()

    if ('System.Security.Cryptography.ProtectedData' -as [type]) {
        return
    }
    foreach ($assemblyName in @('System.Security', 'System.Security.Cryptography.ProtectedData')) {
        try {
            Add-Type -AssemblyName $assemblyName -ErrorAction Stop
            if ('System.Security.Cryptography.ProtectedData' -as [type]) {
                return
            }
        }
        catch {
            Write-Verbose "Could not load assembly '$assemblyName': $($_.Exception.Message)"
        }
    }
    throw 'The DPAPI ProtectedData type could not be loaded.'
}

function Get-ProtectionKeyPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope
    )

    if ($Scope -eq 'LocalMachine') {
        if (-not [string]::IsNullOrWhiteSpace($env:TCS_MACHINE_KEY_PATH)) {
            return $env:TCS_MACHINE_KEY_PATH
        }
        return '/etc/tcs.core/protection.key'
    }
    return (Join-Path -Path (Join-Path -Path (Get-ModuleConfigRoot) -ChildPath 'tcs.core') -ChildPath 'protection.key')
}

function Get-ProtectionKey {
    <#
    .SYNOPSIS
        Loads (and when allowed, creates) the 32-byte master key for the given scope on Linux/macOS.
    #>
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope,

        [switch]$Create
    )

    $keyPath = Get-ProtectionKeyPath -Scope $Scope

    if (-not (Test-Path -LiteralPath $keyPath)) {
        if (-not $Create) {
            throw "No $Scope protection key found at '$keyPath'. The value was protected on a different machine or by a different user."
        }
        $key = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($key) } finally { $rng.Dispose() }

        try {
            $keyDirectory = Split-Path -Path $keyPath -Parent
            if (-not (Test-Path -LiteralPath $keyDirectory)) {
                $null = New-Item -Path $keyDirectory -ItemType Directory -Force -ErrorAction Stop
            }
            $setPermissions = -not (Test-IsWindowsPlatform)
            if ($setPermissions -and $Scope -eq 'CurrentUser') {
                # Also when the folder already exists (it holds the settings files too)
                & chmod 700 $keyDirectory
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to set permissions on '$keyDirectory'."
                }
            }

            # Create the empty file and restrict it before any key material is written
            $null = New-Item -Path $keyPath -ItemType File -Force -ErrorAction Stop
            if ($setPermissions) {
                # LocalMachine semantics: any local user may decrypt, only root may change the key
                $fileMode = if ($Scope -eq 'CurrentUser') { '600' } else { '644' }
                & chmod $fileMode $keyPath
                if ($LASTEXITCODE -ne 0) {
                    Remove-Item -LiteralPath $keyPath -Force -ErrorAction SilentlyContinue
                    throw "Failed to set permissions on '$keyPath'."
                }
            }
            [System.IO.File]::WriteAllText($keyPath, [Convert]::ToBase64String($key))
        }
        catch {
            # Never leave an empty or partial key file behind
            if ((Test-Path -LiteralPath $keyPath) -and (Get-Item -LiteralPath $keyPath).Length -lt 44) {
                Remove-Item -LiteralPath $keyPath -Force -ErrorAction SilentlyContinue
            }
            if ($Scope -eq 'LocalMachine') {
                throw "Cannot create the LocalMachine protection key at '$keyPath'. Run Protect-ConfigValue -Scope LocalMachine once as root to create it, or set TCS_MACHINE_KEY_PATH to a writable location. $($_.Exception.Message)"
            }
            throw
        }
        return , $key
    }

    $key = [Convert]::FromBase64String(([System.IO.File]::ReadAllText($keyPath)).Trim())
    if ($key.Length -ne 32) {
        throw "The protection key at '$keyPath' is invalid (expected 32 bytes)."
    }
    return , $key
}

function Get-DerivedKey {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory)]
        [byte[]]$MasterKey,

        [Parameter(Mandatory)]
        [string]$Purpose
    )

    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (, $MasterKey)
    try {
        return , $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("tcs.core:$Purpose"))
    }
    finally {
        $hmac.Dispose()
    }
}

function Protect-BytesWithKey {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory)]
        [byte[]]$Data,

        [Parameter(Mandatory)]
        [byte[]]$MasterKey
    )

    $encKey = Get-DerivedKey -MasterKey $MasterKey -Purpose 'enc'
    $macKey = Get-DerivedKey -MasterKey $MasterKey -Purpose 'mac'

    $aes = [System.Security.Cryptography.Aes]::Create()
    try {
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        $aes.Key = $encKey
        $aes.GenerateIV()
        $encryptor = $aes.CreateEncryptor()
        try {
            $cipherText = $encryptor.TransformFinalBlock($Data, 0, $Data.Length)
        }
        finally {
            $encryptor.Dispose()
        }
        $payload = New-Object byte[] ($aes.IV.Length + $cipherText.Length)
        [Array]::Copy($aes.IV, 0, $payload, 0, $aes.IV.Length)
        [Array]::Copy($cipherText, 0, $payload, $aes.IV.Length, $cipherText.Length)
    }
    finally {
        $aes.Dispose()
    }

    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (, $macKey)
    try {
        $tag = $hmac.ComputeHash($payload)
    }
    finally {
        $hmac.Dispose()
    }

    $result = New-Object byte[] ($payload.Length + $tag.Length)
    [Array]::Copy($payload, 0, $result, 0, $payload.Length)
    [Array]::Copy($tag, 0, $result, $payload.Length, $tag.Length)
    return , $result
}

function Unprotect-BytesWithKey {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory)]
        [byte[]]$Data,

        [Parameter(Mandatory)]
        [byte[]]$MasterKey
    )

    $tagLength = 32
    $ivLength = 16
    if ($Data.Length -lt ($ivLength + 16 + $tagLength)) {
        throw 'The protected value is truncated or corrupt.'
    }

    $encKey = Get-DerivedKey -MasterKey $MasterKey -Purpose 'enc'
    $macKey = Get-DerivedKey -MasterKey $MasterKey -Purpose 'mac'

    $payloadLength = $Data.Length - $tagLength
    $payload = New-Object byte[] $payloadLength
    [Array]::Copy($Data, 0, $payload, 0, $payloadLength)

    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (, $macKey)
    try {
        $expectedTag = $hmac.ComputeHash($payload)
    }
    finally {
        $hmac.Dispose()
    }

    # Constant-time comparison (CryptographicOperations is not available on .NET Framework)
    $difference = 0
    for ($i = 0; $i -lt $tagLength; $i++) {
        $difference = $difference -bor ($expectedTag[$i] -bxor $Data[$payloadLength + $i])
    }
    if ($difference -ne 0) {
        throw 'The protected value failed its integrity check. It was protected with a different key or has been modified.'
    }

    $iv = New-Object byte[] $ivLength
    [Array]::Copy($payload, 0, $iv, 0, $ivLength)

    $aes = [System.Security.Cryptography.Aes]::Create()
    try {
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        $aes.Key = $encKey
        $aes.IV = $iv
        $decryptor = $aes.CreateDecryptor()
        try {
            return , $decryptor.TransformFinalBlock($payload, $ivLength, $payloadLength - $ivLength)
        }
        finally {
            $decryptor.Dispose()
        }
    }
    finally {
        $aes.Dispose()
    }
}

# ConvertFrom-SecureString -Key output starts with this marker (tcs.core 0.2.x LocalMachine values)
$script:LegacyKeyedValueMarker = '76492d1116743f0423413b16050a5345'
# Header of a DPAPI blob in hex (tcs.core 0.2.x CurrentUser values on Windows)
$script:LegacyDpapiValueMarker = '01000000d08c9ddf0115d1118c7a00c04fc297eb'

function ConvertFrom-LegacyProtectedValue {
    <#
    .SYNOPSIS
        Decrypts a value protected by tcs.core 0.2.x (ConvertFrom-SecureString output) to a
        SecureString, and throws a clear error for anything that is not in that format.
    #>
    [CmdletBinding()]
    [OutputType([System.Security.SecureString])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    $isKeyed = $Value.StartsWith($script:LegacyKeyedValueMarker, [System.StringComparison]::OrdinalIgnoreCase)
    $isUserValue = $false
    if (-not $isKeyed -and $Value -match '^[0-9a-fA-F]+$') {
        if (Test-IsWindowsPlatform) {
            $isUserValue = $Value.StartsWith($script:LegacyDpapiValueMarker, [System.StringComparison]::OrdinalIgnoreCase)
        }
        else {
            # PowerShell 7 on Linux/macOS wrote the UTF-16 text as hex: 4 hex digits per character
            $isUserValue = ($Value.Length % 4) -eq 0
        }
    }
    if (-not ($isKeyed -or $isUserValue)) {
        throw "The value is not protected: it is neither a Protect-ConfigValue value ('$($script:ProtectedValuePrefix):...') nor a value protected by tcs.core 0.2.x."
    }

    Write-Warning 'This value uses the legacy tcs.core 0.2.x format. Protect it again with Protect-ConfigValue to use the stronger format.'

    if (-not $isKeyed) {
        return (ConvertTo-SecureString -String $Value -ErrorAction Stop)
    }

    # 0.2.x derived the LocalMachine key from $env:COMPUTERNAME, which is empty on Linux/macOS
    $computerNames = New-Object System.Collections.Generic.List[string]
    foreach ($name in @($env:COMPUTERNAME, [Environment]::MachineName, '')) {
        $candidate = [string]$name
        if (-not $computerNames.Contains($candidate)) {
            $computerNames.Add($candidate)
        }
    }
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        foreach ($computerName in $computerNames) {
            $legacyKey = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($computerName + 'tcs.core'))
            try {
                return (ConvertTo-SecureString -String $Value -Key $legacyKey -ErrorAction Stop)
            }
            catch {
                Write-Verbose "The legacy value could not be decrypted with the key for computer name '$computerName'."
            }
        }
    }
    finally {
        $sha256.Dispose()
    }
    throw 'The legacy LocalMachine value could not be decrypted on this machine.'
}
