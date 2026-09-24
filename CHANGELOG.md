# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - Unreleased

### Breaking changes
- `Protect-ConfigValue` now returns `tcs:v1:<method>:<data>`. Windows uses real DPAPI
  (CurrentUser and LocalMachine); Linux/macOS use AES-256-CBC + HMAC-SHA256 with a key file.
  Previously Linux/macOS output was unencrypted, and LocalMachine used a key derived from the
  computer name (a fixed key on Linux). Old values can still be decrypted.
- `Set-ModuleConfig` has a new parameter set: `-ModuleName` (or `-ModuleConfigFilePath`),
  `-UpdateWarning`, `-UpdateCheckIntervalHours`, `-Telemetry`, `-TelemetryUri`,
  `-TelemetryApiKey`, `-Reset`, `-PassThru`. `-BasicTelemetry`, `-ModulePath` and
  `-ModuleConfigPath` were removed.
- `Invoke-TelemetryCollection` sends to the tcs-telemetry API (POST, JSON, `X-API-Key`).
  `-URI` is optional; `-ModulePath` and `-Minimal` are accepted but ignored. Hardware serials,
  paths and error messages are no longer collected.
- `Invoke-WithRetry` waits `DelaySeconds` before the first retry (it waited
  `DelaySeconds * BackoffMultiplier`). `DelaySeconds` accepts fractions.
- `Get-ModuleStatus` writes a warning instead of host text, returns `CheckedAt` and `Source`,
  and caches results.
- Settings are stored as real booleans/numbers; old `"True"` strings are still read.

### Added
- `Get-ModuleConfig`, `Get-ModuleStatus`, `Get-ParameterValues` and
  `Invoke-TelemetryCollection` are exported again (other tcs modules depend on them).
- Update check runs at most once per `UpdateCheckIntervalHours` (default 24), with results
  and failures cached. `TCS_SKIP_UPDATE_CHECK=1` turns it off.
- Telemetry settings (`Telemetry`, `TelemetryUri`, `TelemetryApiKey`), a first-run notice and
  `TCS_TELEMETRY_OPTOUT=1`.
- `Protect-ConfigValue -Key`, `Unprotect-ConfigValue -Key` and `-AsSecureString`.
- `Write-Log -PassThru` and `-UseUtc`; safe concurrent appends; UTF-8 without BOM.
- `ConvertTo-HashTable -Ordered`, dictionary input, and recursion into nested arrays.
- `Invoke-WithRetry -MaxDelaySeconds` and parameter validation.
- `New-TemporaryDirectory` and `Set-ModuleConfig` support `-WhatIf`/`-Confirm`.
- `TCS_CONFIG_ROOT` to relocate settings.
- Pester tests for every function, module-wide tests (exports, help, PSScriptAnalyzer),
  CI on Windows PowerShell 5.1 and PowerShell 7 on Windows, Linux and macOS.
- `.editorconfig`, `.gitattributes`, `.gitignore`, `CONTRIBUTING.md`, `SECURITY.md`,
  issue/PR templates, `CODEOWNERS` and Dependabot for GitHub Actions.

### Fixed
- An error was printed on every import when the PowerShell Gallery could not be reached.
- Importing the module rewrote the settings file every time.
- `Get-ModuleConfig` returned a stray `FileInfo` object on first run and could not be called
  without `-CommandPath`.
- `ConvertTo-CamelCase` failed for single-word input such as `XML`.
- String casing functions were affected by the current culture (e.g. Turkish).
- `Invoke-WithRetry` lost the original error record when retries were exhausted.
- `Build.ps1 -Task Test`/`Validate` never ran PSScriptAnalyzer or Pester.
- The per-file PSScriptAnalyzer Pester blocks generated no tests.
- README examples that did not work, and the licence name (GPL-3.0, not MIT).

## [0.2.0] - 2024

### Added
- `Write-Log` — structured logging with file and console output
- `Invoke-WithRetry` — retry logic with configurable backoff
- `ConvertTo-HashTable` — PSCustomObject to hashtable conversion
- `Test-IsElevated` — elevation/admin check
- `New-TemporaryDirectory` — scoped temp directory creation
- `Protect-ConfigValue` / `Unprotect-ConfigValue` — DPAPI config value encryption
- `ConvertTo-PascalCase`, `ConvertTo-KebabCase`, `ConvertTo-SnakeCase` — string casing utilities

### Improved
- `ConvertTo-CamelCase` — delimiter-aware splitting
- `Set-ModuleConfig`, `Get-ModuleConfig`, `Get-ModuleStatus`
- `New-DynamicParameter`, `Get-ParameterValues`
- Security hardening for telemetry collection

### Fixed
- Various bug fixes

## [0.1.7] - 2024

### Initial PSGallery release
- `ConvertTo-CamelCase`
- `New-DynamicParameter`
- `Get-ModuleConfig`, `Get-ModuleStatus`
- `Invoke-TelemetryCollection`
- `Get-ParameterValues`
