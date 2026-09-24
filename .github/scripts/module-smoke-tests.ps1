param()

$moduleName = 'tcs.core'
$repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$moduleDirectory = Join-Path -Path (Join-Path -Path $repoRoot -ChildPath 'modules') -ChildPath $moduleName
$moduleManifest = Join-Path -Path $moduleDirectory -ChildPath "$moduleName.psd1"

if (-not (Test-Path -Path $moduleManifest)) {
    throw "Module manifest not found at path: $moduleManifest"
}

# Keep the smoke test offline and away from the real user profile
$env:TCS_SKIP_UPDATE_CHECK = '1'
$env:TCS_TELEMETRY_OPTOUT = '1'
$env:TCS_CONFIG_ROOT = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "tcs-smoke-$([guid]::NewGuid().ToString('N'))"

try {
    Write-Host "Importing $moduleName from $moduleManifest" -ForegroundColor Cyan
    Import-Module -Name $moduleManifest -Force -ErrorAction Stop

    $camel = ConvertTo-CamelCase -Value 'HelloWorld'
    if ($camel -ne 'helloWorld') { throw "ConvertTo-CamelCase returned '$camel' (expected 'helloWorld')." }
    $camelDelim = ConvertTo-CamelCase -Value 'hello_world'
    if ($camelDelim -ne 'helloWorld') { throw "ConvertTo-CamelCase delimiter returned '$camelDelim' (expected 'helloWorld')." }

    $dynamicParameter = New-DynamicParameter -Name 'TestParam' -ParameterType ([string]) -Mandatory
    if ($dynamicParameter.Name -ne 'TestParam' -or -not $dynamicParameter.Parameter) { throw 'New-DynamicParameter did not return the expected parameter definition.' }

    $pascal = ConvertTo-PascalCase -Value 'hello_world'
    if ($pascal -ne 'HelloWorld') { throw "ConvertTo-PascalCase returned '$pascal' (expected 'HelloWorld')." }

    $kebab = ConvertTo-KebabCase -Value 'HelloWorld'
    if ($kebab -ne 'hello-world') { throw "ConvertTo-KebabCase returned '$kebab' (expected 'hello-world')." }

    $snake = ConvertTo-SnakeCase -Value 'HelloWorld'
    if ($snake -ne 'hello_world') { throw "ConvertTo-SnakeCase returned '$snake' (expected 'hello_world')." }

    $obj = [PSCustomObject]@{ Name = 'Test'; Value = 42 }
    $ht = $obj | ConvertTo-HashTable
    if ($ht -isnot [hashtable] -or $ht.Name -ne 'Test') { throw 'ConvertTo-HashTable did not return expected hashtable.' }

    $elevated = Test-IsElevated
    if ($elevated -isnot [bool]) { throw "Test-IsElevated returned type '$($elevated.GetType().Name)' (expected bool)." }

    $tmpDir = New-TemporaryDirectory -Prefix 'smoketest'
    if (-not (Test-Path $tmpDir.FullName)) { throw 'New-TemporaryDirectory did not create a directory.' }
    Remove-Item $tmpDir.FullName -Recurse -Force

    $retryResult = Invoke-WithRetry -ScriptBlock { 'success' } -MaxRetries 1
    if ($retryResult -ne 'success') { throw "Invoke-WithRetry returned '$retryResult' (expected 'success')." }

    $logFile = Join-Path ([System.IO.Path]::GetTempPath()) 'tcs_smoke_test.log'
    Write-Log -Message 'smoke test' -Level Info -LogPath $logFile -NoConsole
    if (-not (Test-Path $logFile)) { throw 'Write-Log did not create log file.' }
    Remove-Item $logFile -Force

    $secret = 'TestSecret123'
    $encrypted = Protect-ConfigValue -Value $secret
    if ($encrypted -notmatch '^tcs:v1:') { throw "Protect-ConfigValue returned an unexpected format: '$encrypted'." }
    $decrypted = Unprotect-ConfigValue -EncryptedValue $encrypted
    if ($decrypted -ne $secret) { throw "Protect/Unprotect-ConfigValue roundtrip failed: got '$decrypted'." }

    $config = Get-ModuleConfig -CommandPath (Join-Path $moduleDirectory "$moduleName.psm1")
    if ($config.ModuleName -ne $moduleName) { throw "Get-ModuleConfig returned module '$($config.ModuleName)'." }

    $status = Get-ModuleStatus -ModuleName $moduleName -ModulePath $moduleDirectory
    if ($status.Source -ne 'Skipped') { throw "Get-ModuleStatus should honour TCS_SKIP_UPDATE_CHECK (source '$($status.Source)')." }

    Invoke-TelemetryCollection -ModuleName $moduleName -ExecutionID ([guid]::NewGuid().ToString()) -Stage 'Module-Load'

    $exported = @((Get-Module $moduleName).ExportedFunctions.Keys)
    $expected = @((Import-PowerShellDataFile -Path $moduleManifest).FunctionsToExport)
    $missing = $expected | Where-Object { $_ -notin $exported }
    if ($missing -or $exported.Count -ne $expected.Count) {
        throw "Exported functions do not match the manifest. Expected $($expected.Count), got $($exported.Count): $($exported -join ', ')"
    }

    Write-Host 'All smoke tests passed successfully.' -ForegroundColor Green
}
finally {
    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $env:TCS_CONFIG_ROOT -Recurse -Force -ErrorAction SilentlyContinue
}
