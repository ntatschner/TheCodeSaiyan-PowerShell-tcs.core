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

Describe 'Protect-ConfigValue' {
    It "Should return an encrypted string" {
        $plaintext = "MySecretValue"
        $encrypted = Protect-ConfigValue -Value $plaintext
        $encrypted | Should -Not -Be $plaintext
    }

    It "Should return a non-empty string" {
        $encrypted = Protect-ConfigValue -Value "TestValue"
        $encrypted | Should -Not -BeNullOrEmpty
    }
}

BeforeDiscovery {
    # -Skip conditions are evaluated during discovery, before any BeforeAll block runs
    $onWindows = $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows
    $isRoot = (-not $onWindows) -and ((& id -u) -eq '0')
}

Describe 'Protect-ConfigValue format and platforms' {
    BeforeAll {
        $key = New-Object byte[] 32
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
    }

    It 'Produces a versioned, self-describing value' {
        Protect-ConfigValue -Value 'abc' | Should -Match '^tcs:v1:(dpapi-cu|aes-cu):[A-Za-z0-9+/=]+$'
    }

    It 'Never contains the plaintext, in any encoding' {
        $protected = Protect-ConfigValue -Value 'PlainTextMarker'
        $protected | Should -Not -Match 'PlainTextMarker'
        $hexUtf16 = -join ([System.Text.Encoding]::Unicode.GetBytes('PlainTextMarker') | ForEach-Object { $_.ToString('x2') })
        $protected | Should -Not -Match $hexUtf16
    }

    It 'Produces a different value each time (random IV)' {
        Protect-ConfigValue -Value 'same' | Should -Not -Be (Protect-ConfigValue -Value 'same')
    }

    It 'Uses DPAPI on Windows' -Skip:(-not $onWindows) {
        Protect-ConfigValue -Value 'x' -Scope LocalMachine | Should -Match '^tcs:v1:dpapi-lm:'
    }

    It 'Creates the user key with owner-only permissions on Linux/macOS' -Skip:$onWindows {
        $null = Protect-ConfigValue -Value 'x'
        $keyPath = Join-Path $env:TCS_CONFIG_ROOT 'tcs.core/protection.key'
        Test-Path $keyPath | Should -BeTrue
        (& stat -c '%a' $keyPath 2>$null) + (& stat -f '%Lp' $keyPath 2>$null) | Should -Match '600'
    }

    It 'Fails clearly for LocalMachine scope when the machine key cannot be created' -Skip:($onWindows -or $isRoot) {
        $env:TCS_MACHINE_KEY_PATH = '/proc/tcs-not-writable/protection.key'
        try {
            { Protect-ConfigValue -Value 'x' -Scope LocalMachine } | Should -Throw '*LocalMachine*'
        }
        finally {
            $env:TCS_MACHINE_KEY_PATH = $null
        }
    }

    It 'Encrypts with a supplied key' {
        Protect-ConfigValue -Value 'x' -Key $key | Should -Match '^tcs:v1:aes-key:'
    }

    It 'Rejects keys that are not 32 bytes' {
        { Protect-ConfigValue -Value 'x' -Key (New-Object byte[] 16) } | Should -Throw
    }

    Context 'Key file permissions' -Skip:($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
        BeforeEach {
            $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath ('perm-' + [guid]::NewGuid().ToString('N'))
        }

        AfterAll {
            $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
        }

        It 'Restricts an existing key folder to the owner when creating the key' {
            $folder = Join-Path -Path $env:TCS_CONFIG_ROOT -ChildPath 'tcs.core'
            $null = New-Item -Path $folder -ItemType Directory -Force
            & chmod 755 $folder
            $null = Protect-ConfigValue -Value 'x'
            (Get-Item -LiteralPath $folder).UnixMode | Should -Be 'drwx------'
            (Get-Item -LiteralPath (Join-Path $folder 'protection.key')).UnixMode | Should -Be '-rw-------'
        }

        It 'Fails, and leaves no key file, when the folder permissions cannot be set' {
            Mock -ModuleName tcs.core chmod { $global:LASTEXITCODE = 1 }
            { Protect-ConfigValue -Value 'x' } | Should -Throw '*permissions*'
            Test-Path -LiteralPath (Join-Path $env:TCS_CONFIG_ROOT 'tcs.core/protection.key') | Should -BeFalse
        }

        It 'Fails, and leaves no key file, when the file permissions cannot be set' {
            Mock -ModuleName tcs.core chmod { $global:LASTEXITCODE = 0 } -ParameterFilter { $args[0] -eq '700' }
            Mock -ModuleName tcs.core chmod { $global:LASTEXITCODE = 1 } -ParameterFilter { $args[0] -eq '600' }
            { Protect-ConfigValue -Value 'x' } | Should -Throw '*permissions*'
            Test-Path -LiteralPath (Join-Path $env:TCS_CONFIG_ROOT 'tcs.core/protection.key') | Should -BeFalse
        }
    }
}
