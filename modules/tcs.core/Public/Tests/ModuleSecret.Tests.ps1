[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
    Justification = 'Test values only.')]
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

Describe 'Set-ModuleSecret, Get-ModuleSecret and Remove-ModuleSecret' {
    BeforeAll {
        $secret = ConvertTo-SecureString -String 'token-123' -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential -ArgumentList 'user@example.com', (ConvertTo-SecureString -String 'p@ss' -AsPlainText -Force)
        $secretFolder = Join-Path -Path $env:TCS_CONFIG_ROOT -ChildPath 'tcs.secrets/Secrets'
    }

    It 'Saves a SecureString encrypted and returns it as a SecureString' {
        Set-ModuleSecret -ModuleName 'tcs.secrets' -Name 'ApiToken' -SecureString $secret
        $file = Join-Path $secretFolder 'ApiToken.json'
        Test-Path $file | Should -BeTrue
        Get-Content -Path $file -Raw | Should -Not -Match 'token-123'
        (Get-Content -Path $file -Raw | ConvertFrom-Json).Value | Should -Match '^tcs:v1:'

        $result = Get-ModuleSecret -ModuleName 'tcs.secrets' -Name 'ApiToken'
        $result | Should -BeOfType [System.Security.SecureString]
        (New-Object System.Net.NetworkCredential -ArgumentList '', $result).Password | Should -BeExactly 'token-123'
    }

    It 'Saves a credential and returns a PSCredential' {
        Set-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Login' -Credential $credential
        Get-Content -Path (Join-Path $secretFolder 'Login.json') -Raw | Should -Not -Match 'p@ss'
        $result = Get-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Login'
        $result | Should -BeOfType [System.Management.Automation.PSCredential]
        $result.UserName | Should -Be 'user@example.com'
        $result.GetNetworkCredential().Password | Should -BeExactly 'p@ss'
    }

    It 'Saves an empty secret and a credential without a password' {
        Set-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Empty' -SecureString (New-Object System.Security.SecureString)
        (Get-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Empty').Length | Should -Be 0
        $noPassword = New-Object System.Management.Automation.PSCredential -ArgumentList 'user', (New-Object System.Security.SecureString)
        Set-ModuleSecret -ModuleName 'tcs.secrets' -Name 'NoPassword' -Credential $noPassword
        $result = Get-ModuleSecret -ModuleName 'tcs.secrets' -Name 'NoPassword'
        $result.UserName | Should -Be 'user'
        $result.Password.Length | Should -Be 0
    }

    It 'Keeps secrets separate per module and per name' {
        Set-ModuleSecret -ModuleName 'tcs.other' -Name 'ApiToken' -SecureString (ConvertTo-SecureString -String 'other' -AsPlainText -Force)
        (Get-ModuleSecret -ModuleName 'tcs.secrets' -Name 'ApiToken' | ForEach-Object { (New-Object System.Net.NetworkCredential -ArgumentList '', $_).Password }) | Should -Be 'token-123'
        (Get-ModuleSecret -ModuleName 'tcs.other' -Name 'ApiToken' | ForEach-Object { (New-Object System.Net.NetworkCredential -ArgumentList '', $_).Password }) | Should -Be 'other'
    }

    It 'Replaces an existing secret' {
        Set-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Replace' -SecureString $secret
        Set-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Replace' -Credential $credential
        Get-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Replace' | Should -BeOfType [System.Management.Automation.PSCredential]
    }

    It 'Writes a non-terminating error for a missing secret' {
        Get-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Missing' -ErrorAction SilentlyContinue -ErrorVariable errs | Should -BeNullOrEmpty
        $errs[0].FullyQualifiedErrorId | Should -Match 'ModuleSecretNotFound'
    }

    It 'Writes a non-terminating error when the secret cannot be decrypted' {
        $null = New-Item -Path $secretFolder -ItemType Directory -Force
        '{ "Type": "SecureString", "Value": "tcs:v1:aes-key:AAAA" }' | Set-Content -Path (Join-Path $secretFolder 'Broken.json')
        Get-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Broken' -ErrorAction SilentlyContinue -ErrorVariable errs | Should -BeNullOrEmpty
        ($errs | Where-Object { $_.FullyQualifiedErrorId -match 'ModuleSecretUnreadable' }) | Should -Not -BeNullOrEmpty
    }

    It 'Removes a secret, honouring -WhatIf' {
        Set-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Temp' -SecureString $secret
        Remove-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Temp' -WhatIf
        Test-Path (Join-Path $secretFolder 'Temp.json') | Should -BeTrue
        Remove-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Temp'
        Test-Path (Join-Path $secretFolder 'Temp.json') | Should -BeFalse
        { Remove-ModuleSecret -ModuleName 'tcs.secrets' -Name 'Temp' -ErrorAction Stop } | Should -Throw
    }

    It 'Does not save anything with -WhatIf' {
        Set-ModuleSecret -ModuleName 'tcs.secrets' -Name 'WhatIf' -SecureString $secret -WhatIf
        Test-Path (Join-Path $secretFolder 'WhatIf.json') | Should -BeFalse
    }

    It 'Rejects names that are not a single safe folder or file name' -ForEach @(
        @{ Module = '../x'; Name = 'a' }, @{ Module = 'tcs.secrets'; Name = '../a' }, @{ Module = 'tcs.secrets'; Name = 'a/b' }
    ) {
        { Set-ModuleSecret -ModuleName $Module -Name $Name -SecureString $secret } | Should -Throw
        { Get-ModuleSecret -ModuleName $Module -Name $Name } | Should -Throw
        { Remove-ModuleSecret -ModuleName $Module -Name $Name } | Should -Throw
    }
}
