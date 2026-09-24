[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
    Justification = 'Builds a value in the legacy 0.2.x format to test backward compatibility.')]
param()

BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.core.psd1') -Force
}

AfterAll {
    Remove-Module -Name tcs.core -Force -ErrorAction SilentlyContinue
}

Describe 'Unprotect-ConfigValue' {
    It "Should decrypt to original value" {
        $original = "RoundTripTestValue"
        $encrypted = Protect-ConfigValue -Value $original
        $decrypted = Unprotect-ConfigValue -EncryptedValue $encrypted
        $decrypted | Should -Be $original
    }

    It "Should return a string" {
        $encrypted = Protect-ConfigValue -Value "TypeCheckValue"
        $result = Unprotect-ConfigValue -EncryptedValue $encrypted
        $result | Should -BeOfType [string]
    }
}

Describe 'Unprotect-ConfigValue format and platforms' {
    BeforeAll {
        $key = New-Object byte[] 32
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
    }

    It 'Round-trips unicode text' {
        $text = 'pässwörd-✓-日本'
        Unprotect-ConfigValue -EncryptedValue (Protect-ConfigValue -Value $text) | Should -BeExactly $text
    }

    It 'Round-trips with a supplied key' {
        Unprotect-ConfigValue -EncryptedValue (Protect-ConfigValue -Value 'k' -Key $key) -Key $key | Should -BeExactly 'k'
    }

    It 'Requires the key for key-protected values' {
        $protected = Protect-ConfigValue -Value 'k' -Key $key
        Unprotect-ConfigValue -EncryptedValue $protected -ErrorAction SilentlyContinue -ErrorVariable errs | Should -BeNullOrEmpty
        $errs[0].ToString() | Should -Match '-Key'
    }

    It 'Fails with the wrong key' {
        $other = New-Object byte[] 32
        $protected = Protect-ConfigValue -Value 'k' -Key $key
        { Unprotect-ConfigValue -EncryptedValue $protected -Key $other -ErrorAction Stop } | Should -Throw
    }

    It 'Detects tampering' {
        $protected = Protect-ConfigValue -Value 'k' -Key $key
        $bytes = [Convert]::FromBase64String($protected.Split(':')[3])
        $bytes[20] = $bytes[20] -bxor 1
        $tampered = 'tcs:v1:aes-key:' + [Convert]::ToBase64String($bytes)
        { Unprotect-ConfigValue -EncryptedValue $tampered -Key $key -ErrorAction Stop } | Should -Throw
    }

    It 'Returns a SecureString with -AsSecureString' {
        $secure = Unprotect-ConfigValue -EncryptedValue (Protect-ConfigValue -Value 's') -AsSecureString
        $secure | Should -BeOfType [System.Security.SecureString]
        [System.Net.NetworkCredential]::new('', $secure).Password | Should -BeExactly 's'
    }

    It 'Still reads values written by tcs.core 0.2.x, with a warning' {
        $legacyKey = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($env:COMPUTERNAME + 'tcs.core'))
        $legacy = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String 'old' -AsPlainText -Force) -Key $legacyKey
        Unprotect-ConfigValue -EncryptedValue $legacy -Scope LocalMachine -WarningVariable warnings -WarningAction SilentlyContinue | Should -BeExactly 'old'
        $warnings.Count | Should -Be 1
    }

    It 'Gives a clear error, and no legacy warning, for a value that was never protected' -ForEach @(
        @{ Value = 'hello' }, @{ Value = 'tcs:v2:x' }, @{ Value = 'abc' }
    ) {
        $warnings = $null
        $errs = $null
        Unprotect-ConfigValue -EncryptedValue $Value -WarningVariable warnings -WarningAction SilentlyContinue -ErrorVariable errs -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        $warnings.Count | Should -Be 0
        $errs[0].ToString() | Should -Match 'not protected'
    }

    It 'Reads a legacy LocalMachine value whatever -Scope is given' {
        $legacyKey = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes([string]$env:COMPUTERNAME + 'tcs.core'))
        $legacy = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String 'old' -AsPlainText -Force) -Key $legacyKey
        Unprotect-ConfigValue -EncryptedValue $legacy -WarningAction SilentlyContinue | Should -BeExactly 'old'
    }

    It 'Reads a legacy LocalMachine value keyed with the machine name' {
        $legacyKey = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes([Environment]::MachineName + 'tcs.core'))
        $legacy = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String 'machine' -AsPlainText -Force) -Key $legacyKey
        Unprotect-ConfigValue -EncryptedValue $legacy -Scope LocalMachine -WarningAction SilentlyContinue | Should -BeExactly 'machine'
    }

    It 'Reads a legacy LocalMachine value written where COMPUTERNAME was empty' {
        $legacyKey = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('tcs.core'))
        $legacy = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String 'empty' -AsPlainText -Force) -Key $legacyKey
        Unprotect-ConfigValue -EncryptedValue $legacy -Scope LocalMachine -WarningAction SilentlyContinue | Should -BeExactly 'empty'
    }

    It 'Reads a legacy CurrentUser value' {
        $legacy = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String 'user value' -AsPlainText -Force)
        Unprotect-ConfigValue -EncryptedValue $legacy -WarningAction SilentlyContinue | Should -BeExactly 'user value'
    }
}
