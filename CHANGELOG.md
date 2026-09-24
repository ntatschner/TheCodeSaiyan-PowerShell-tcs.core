# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-09-24

Additive release: every 0.3.0 command and parameter still works.

### Added
- `Invoke-TcsCommand`, `Start-TcsTelemetry` and `Complete-TcsTelemetry`: a telemetry wrapper
  for tcs commands that replaces the Start/End boilerplate. Only the outermost command of a
  module is reported (nested commands of the same module are skipped); a run is failed when
  the body throws or writes a non-terminating error; terminating errors are rethrown
  unchanged; output is passed through unchanged; telemetry never breaks the command.
- `Invoke-WithRetry -RetryOnStatusCode`, `-ShouldRetry`, `-JitterPercent` and
  `-RetryOnNonTerminatingError`. `Retry-After` (seconds or an HTTP date) is honoured on
  Windows PowerShell 5.1 and PowerShell 7, up to `MaxDelaySeconds`.
- `Get-HttpErrorDetail`, `New-BasicAuthHeader` and `ConvertTo-QueryString`.
- `Set-ModuleSecret`, `Get-ModuleSecret` and `Remove-ModuleSecret`: encrypted secrets and
  credentials saved per module and name.
- `Set-ModuleConfig -Setting` for any setting, typed against the defaults.
- `ConvertTo-PascalCase` / `ConvertTo-CamelCase -PreserveAcronyms`.
- en-US copy of `about_tcs.core` (identical to en-GB).
- CI job that imports every consumer module (tcs.azure, tcs.jira, tcs.confluence,
  tcs.intune.packaging, tcs.utils) against this tcs.core and runs its smoke tests.

### Changed
- `Write-Log -Level Error` now uses `Write-Error` and `-Level Warning` uses `Write-Warning`
  instead of coloured `Write-Host` text. They can now be captured and suppressed, and
  `-ErrorAction Stop` (or `$ErrorActionPreference = 'Stop'`) makes an Error line throw. The
  file is written first, so the line is still logged.
- The telemetry API key is stored encrypted (`Protect-ConfigValue`) by `Set-ModuleConfig`
  and shown as `********` by `Get-ModuleConfig` and `Set-ModuleConfig -PassThru`. Plain-text
  keys saved by 0.3.0 still work and are encrypted the next time the settings are saved.
  `Get-ModuleConfig` now returns a copy of the session settings.
- `Set-ModuleConfig -ModuleName`, `Get-ModuleStatus -ModuleName` and the new secret commands
  only accept a single safe folder name (letters, digits, `.`, `_`, `-`).
- String casing splits words at a digit followed by a capital (`Version2Update` ->
  `version2_update`, `user2FA` -> `User2Fa`) and at case changes of letters outside A-Z.
- `Unprotect-ConfigValue` detects the scope of legacy 0.2.x values from the value; `-Scope`
  is ignored.

### Deprecated
Each writes a warning once per session and keeps working; removal is planned for 1.0.
- `Invoke-TelemetryCollection -ModulePath`, `-Minimal` and `-Stage 'In-Progress'`.
- `Get-ParameterValues` (use `$PSBoundParameters`).
- `ConvertTo-HashTable` (use `ConvertFrom-Json -AsHashtable` on PowerShell 7).

### Fixed
- `Invoke-TelemetryCollection` ignored a module's `Telemetry = $false` (and `TelemetryUri`)
  when the module had not called `Get-ModuleConfig` in the session.
- `Set-ModuleConfig -Reset` ignored the module's own `Config/Module.Defaults.json`.
- `Set-ModuleConfig -ModuleName '../..'` could write outside the settings folder.
- One invalid setting (for example `UpdateCheckIntervalHours: -5`) made the import skip the
  update check and warn that all defaults were used; now only that setting falls back.
- `Invoke-WithRetry` unrolled collections (`, @(1)` came back as an `Int32`).
- `Unprotect-ConfigValue` gave a misleading "legacy 0.2.x format" warning for plain text; it
  now gives a clear "not protected" error. Legacy LocalMachine values are also tried with
  `[Environment]::MachineName` (`$env:COMPUTERNAME` is empty on Linux/macOS).
- The protection key folder was not restricted to mode 700 when it already existed, and a
  failed `chmod` on the folder was not detected.
- Non-ASCII script files are saved as UTF-8 with BOM for Windows PowerShell 5.1.

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
