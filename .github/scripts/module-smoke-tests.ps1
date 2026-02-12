param()

$moduleName = 'tcs.core'
$repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$moduleDirectory = Join-Path -Path $repoRoot -ChildPath 'modules/tcs.core'
$moduleManifest = Join-Path -Path $moduleDirectory -ChildPath 'tcs.core.psd1'

if (-not (Test-Path -Path $moduleManifest)) {
    throw "Module manifest not found at path: $moduleManifest"
}

try {
    Write-Host "Importing $moduleName from $moduleManifest" -ForegroundColor Cyan
    Import-Module -Name $moduleManifest -Force -ErrorAction Stop

    # ConvertTo-CamelCase
    $camel = ConvertTo-CamelCase -Value 'HelloWorld'
    if ($camel -ne 'helloWorld') {
        throw "ConvertTo-CamelCase returned '$camel' (expected 'helloWorld')."
    }
    $camelDelim = ConvertTo-CamelCase -Value 'hello_world'
    if ($camelDelim -ne 'helloWorld') {
        throw "ConvertTo-CamelCase delimiter returned '$camelDelim' (expected 'helloWorld')."
    }

    # New-DynamicParameter
    $dynamicParameter = New-DynamicParameter -Name 'TestParam' -ParameterType ([string]) -Mandatory
    if ($dynamicParameter.Name -ne 'TestParam' -or -not $dynamicParameter.Parameter) {
        throw 'New-DynamicParameter did not return the expected parameter definition.'
    }

    # ConvertTo-PascalCase
    $pascal = ConvertTo-PascalCase -Value 'hello_world'
    if ($pascal -ne 'HelloWorld') {
        throw "ConvertTo-PascalCase returned '$pascal' (expected 'HelloWorld')."
    }

    # ConvertTo-KebabCase
    $kebab = ConvertTo-KebabCase -Value 'HelloWorld'
    if ($kebab -ne 'hello-world') {
        throw "ConvertTo-KebabCase returned '$kebab' (expected 'hello-world')."
    }

    # ConvertTo-SnakeCase
    $snake = ConvertTo-SnakeCase -Value 'HelloWorld'
    if ($snake -ne 'hello_world') {
        throw "ConvertTo-SnakeCase returned '$snake' (expected 'hello_world')."
    }

    # ConvertTo-HashTable
    $obj = [PSCustomObject]@{ Name = 'Test'; Value = 42 }
    $ht = $obj | ConvertTo-HashTable
    if ($ht -isnot [hashtable] -or $ht.Name -ne 'Test') {
        throw 'ConvertTo-HashTable did not return expected hashtable.'
    }

    # Test-IsElevated
    $elevated = Test-IsElevated
    if ($elevated -isnot [bool]) {
        throw "Test-IsElevated returned type '$($elevated.GetType().Name)' (expected bool)."
    }

    # New-TemporaryDirectory
    $tmpDir = New-TemporaryDirectory -Prefix 'smoketest'
    if (-not (Test-Path $tmpDir.FullName)) {
        throw 'New-TemporaryDirectory did not create a directory.'
    }
    Remove-Item $tmpDir.FullName -Recurse -Force

    # Invoke-WithRetry
    $retryResult = Invoke-WithRetry -ScriptBlock { 'success' } -MaxRetries 1
    if ($retryResult -ne 'success') {
        throw "Invoke-WithRetry returned '$retryResult' (expected 'success')."
    }

    # Write-Log (file output)
    $logFile = Join-Path ([System.IO.Path]::GetTempPath()) 'tcs_smoke_test.log'
    Write-Log -Message 'smoke test' -Level Info -LogPath $logFile -NoConsole
    if (-not (Test-Path $logFile)) {
        throw 'Write-Log did not create log file.'
    }
    Remove-Item $logFile -Force

    # Protect/Unprotect-ConfigValue roundtrip
    $secret = 'TestSecret123'
    $encrypted = Protect-ConfigValue -Value $secret
    $decrypted = Unprotect-ConfigValue -EncryptedValue $encrypted
    if ($decrypted -ne $secret) {
        throw "Protect/Unprotect-ConfigValue roundtrip failed: got '$decrypted'."
    }

    # Verify exported function count
    $exported = (Get-Module $moduleName).ExportedFunctions.Keys
    $expectedCount = 17
    if ($exported.Count -ne $expectedCount) {
        throw "Expected $expectedCount exported functions, got $($exported.Count): $($exported -join ', ')"
    }

    Write-Host 'All smoke tests passed successfully.' -ForegroundColor Green
}
finally {
    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
}
