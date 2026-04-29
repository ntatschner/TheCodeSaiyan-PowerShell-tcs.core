# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
