# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-02-12

### Added
- `Write-Log` — structured log output with severity levels
- `Invoke-WithRetry` — retry wrapper with configurable attempts and delay
- `ConvertTo-HashTable` — recursive PSObject-to-hashtable converter
- `Test-IsElevated` — check if the current session is running elevated
- `New-TemporaryDirectory` — create a scoped temporary directory
- `Protect-ConfigValue` / `Unprotect-ConfigValue` — DPAPI-backed config value encryption
- `ConvertTo-PascalCase`, `ConvertTo-KebabCase`, `ConvertTo-SnakeCase` — string casing utilities

### Changed
- Improved `ConvertTo-CamelCase`, `Set-ModuleConfig`, `Get-ModuleConfig`, `Get-ModuleStatus`
- Improved `New-DynamicParameter`, `Get-ParameterValues`
- Security hardening for telemetry collection

### Fixed
- Various bug fixes across module loading and config handling

## [0.1.7] - 2024-07-01

### Added
- Initial PSGallery release
- Core module infrastructure: `Get-ModuleConfig`, `Get-ModuleStatus`, `Get-ParameterValues`
- Telemetry collection via `Invoke-TelemetryCollection`
- `New-DynamicParameter` — runtime dynamic parameter creation
- `ConvertTo-CamelCase` — string casing helper

[Unreleased]: https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/compare/v0.1.7...v0.2.0
[0.1.7]: https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/releases/tag/v0.1.7
