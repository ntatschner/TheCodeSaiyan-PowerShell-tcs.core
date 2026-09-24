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

Describe 'ConvertTo-PascalCase' {
    It "Should convert underscore separated" {
        ConvertTo-PascalCase -Value "hello_world" | Should -Be "HelloWorld"
    }

    It "Should convert hyphen separated" {
        ConvertTo-PascalCase -Value "hello-world" | Should -Be "HelloWorld"
    }

    It "Should convert space separated" {
        ConvertTo-PascalCase -Value "hello world" | Should -Be "HelloWorld"
    }

    It "Should convert camelCase" {
        ConvertTo-PascalCase -Value "helloWorld" | Should -Be "HelloWorld"
    }

    It "Should handle empty string" {
        ConvertTo-PascalCase -Value "" | Should -Be ""
    }

    It "Should support pipeline" {
        "test_value" | ConvertTo-PascalCase | Should -Be "TestValue"
    }
}

Describe 'String casing word boundaries' {
    It '<Value> -> Pascal <Pascal>, camel <Camel>, snake <Snake>, kebab <Kebab>' -ForEach @(
        @{ Value = 'user2FA'; Pascal = 'User2Fa'; Camel = 'user2Fa'; Snake = 'user2_fa'; Kebab = 'user2-fa' }
        @{ Value = 'Version2Update'; Pascal = 'Version2Update'; Camel = 'version2Update'; Snake = 'version2_update'; Kebab = 'version2-update' }
        @{ Value = 'utf8Encoding'; Pascal = 'Utf8Encoding'; Camel = 'utf8Encoding'; Snake = 'utf8_encoding'; Kebab = 'utf8-encoding' }
        @{ Value = 'HTML5Parser'; Pascal = 'Html5Parser'; Camel = 'html5Parser'; Snake = 'html5_parser'; Kebab = 'html5-parser' }
        @{ Value = ([string][char]0x00E4 + 'rger' + [char]0x00DC + 'ber'); Pascal = ([string][char]0x00C4 + 'rger' + [char]0x00DC + 'ber'); Camel = ([string][char]0x00E4 + 'rger' + [char]0x00DC + 'ber'); Snake = ([string][char]0x00E4 + 'rger_' + [char]0x00FC + 'ber'); Kebab = ([string][char]0x00E4 + 'rger-' + [char]0x00FC + 'ber') }
        @{ Value = 'caf' + [char]0x00E9 + 'Cr' + [char]0x00E8 + 'meBr' + [char]0x00FB + 'l' + [char]0x00E9 + 'e'; Pascal = 'Caf' + [char]0x00E9 + 'Cr' + [char]0x00E8 + 'meBr' + [char]0x00FB + 'l' + [char]0x00E9 + 'e'; Camel = 'caf' + [char]0x00E9 + 'Cr' + [char]0x00E8 + 'meBr' + [char]0x00FB + 'l' + [char]0x00E9 + 'e'; Snake = 'caf' + [char]0x00E9 + '_cr' + [char]0x00E8 + 'me_br' + [char]0x00FB + 'l' + [char]0x00E9 + 'e'; Kebab = 'caf' + [char]0x00E9 + '-cr' + [char]0x00E8 + 'me-br' + [char]0x00FB + 'l' + [char]0x00E9 + 'e' }
        @{ Value = 'XMLHttpRequest'; Pascal = 'XmlHttpRequest'; Camel = 'xmlHttpRequest'; Snake = 'xml_http_request'; Kebab = 'xml-http-request' }
    ) {
        ConvertTo-PascalCase -Value $Value | Should -BeExactly $Pascal
        ConvertTo-CamelCase -Value $Value | Should -BeExactly $Camel
        ConvertTo-SnakeCase -Value $Value | Should -BeExactly $Snake
        ConvertTo-KebabCase -Value $Value | Should -BeExactly $Kebab
    }

    It 'Keeps acronyms with -PreserveAcronyms' {
        ConvertTo-PascalCase -Value 'user2FA' -PreserveAcronyms | Should -BeExactly 'User2FA'
        ConvertTo-PascalCase -Value 'XMLHttpRequest' -PreserveAcronyms | Should -BeExactly 'XMLHttpRequest'
        ConvertTo-PascalCase -Value 'parse_XML_file' -PreserveAcronyms | Should -BeExactly 'ParseXMLFile'
        ConvertTo-PascalCase -Value 'HTML5 parser' -PreserveAcronyms | Should -BeExactly 'HTML5Parser'
        ConvertTo-PascalCase -Value 'a_b' -PreserveAcronyms | Should -BeExactly 'AB'
        ConvertTo-CamelCase -Value 'XMLHttpRequest' -PreserveAcronyms | Should -BeExactly 'xmlHttpRequest'
        ConvertTo-CamelCase -Value 'parse_XML_file' -PreserveAcronyms | Should -BeExactly 'parseXMLFile'
        ConvertTo-CamelCase -Value 'user 2FA code' -PreserveAcronyms | Should -BeExactly 'user2FACode'
    }

    It 'Does not change acronyms without -PreserveAcronyms' {
        ConvertTo-PascalCase -Value 'parse_XML_file' | Should -BeExactly 'ParseXmlFile'
    }
}
