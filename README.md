# TheCodeSaiyan PowerShell tcs.core Module

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/tcs.core.svg?style=flat-square&label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/tcs.core)
[![GitHub Release](https://img.shields.io/github/release/ntatschner/TheCodeSaiyan-PowerShell-tcs.core.svg?style=flat-square&label=GitHub%20Release)](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/ci-validate.yml?branch=main&style=flat-square&label=Build)](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/actions/workflows/ci-validate.yml)
[![Docs](https://img.shields.io/github/actions/workflow/status/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/generate-docs.yml?branch=main&style=flat-square&label=Docs)](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/actions/workflows/generate-docs.yml)
[![Publish](https://img.shields.io/github/actions/workflow/status/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/publish-to-psgallery.yml?branch=main&style=flat-square&label=Publish)](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/actions/workflows/publish-to-psgallery.yml)

The shared base module for the TheCodeSaiyan PowerShell suite (tcs.azure, tcs.confluence, tcs.jira, tcs.intune.packaging, tcs.utils): configuration, update checks, telemetry, secret protection, logging, retries and utility functions.

## 🚀 Features

- **Configuration management**: per-user JSON settings for every tcs module, with defaults
- **Update notifications**: PowerShell Gallery version check, cached for a day
- **Telemetry**: anonymous, opt-out usage telemetry for the tcs suite
- **Secret protection**: encrypt config values with DPAPI (Windows) or AES-256 + HMAC (Linux/macOS)
- **Logging and retries**: `Write-Log` and `Invoke-WithRetry`
- **Utilities**: dynamic parameters, string casing, hashtable conversion, temp folders, elevation check
- **Cross-platform**: Windows PowerShell 5.1 and PowerShell 7 on Windows, Linux and macOS

## 📦 Installation

### From PowerShell Gallery (Recommended)

```powershell
# Install for current user
Install-Module -Name tcs.core -Scope CurrentUser

# Install for all users (requires elevation)
Install-Module -Name tcs.core -Scope AllUsers
```

### From GitHub Source

```powershell
git clone https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core.git
Import-Module ./TheCodeSaiyan-PowerShell-tcs.core/modules/tcs.core/tcs.core.psd1
```

## 🔧 Functions

| Function | Purpose |
| --- | --- |
| `Get-ModuleConfig` | Returns the settings for the tcs module that owns the calling script |
| `Set-ModuleConfig` | Changes a module's settings (`-WhatIf` supported) |
| `Get-ModuleStatus` | Checks the PowerShell Gallery for a newer version (cached, never throws) |
| `Invoke-TelemetryCollection` | Records anonymous usage telemetry for a command or module load |
| `Get-ParameterValues` | Returns `$PSBoundParameters` without common parameters or nulls |
| `Protect-ConfigValue` / `Unprotect-ConfigValue` | Encrypt and decrypt config values |
| `Write-Log` | Timestamped, levelled console and file logging |
| `Invoke-WithRetry` | Runs a script block with retries and exponential backoff |
| `New-DynamicParameter` | Builds a `RuntimeDefinedParameter` for `DynamicParam` blocks |
| `ConvertTo-CamelCase` / `PascalCase` / `KebabCase` / `SnakeCase` | String casing |
| `ConvertTo-HashTable` | Converts objects (e.g. from `ConvertFrom-Json`) to hashtables |
| `New-TemporaryDirectory` | Creates a uniquely named temporary folder |
| `Test-IsElevated` | Checks for Administrator (Windows) or root (Linux/macOS) |

### Examples

```powershell
# String casing
ConvertTo-CamelCase -Value 'XMLHttpRequest'      # xmlHttpRequest
'hello world' | ConvertTo-KebabCase              # hello-world

# Retry with exponential backoff: waits 1s, 2s, 4s between attempts
Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri $uri } -MaxRetries 3 -DelaySeconds 1 -BackoffMultiplier 2

# Protect a secret for the current user
$protected = Protect-ConfigValue -Value 'P@ssw0rd'
Unprotect-ConfigValue -EncryptedValue $protected

# Logging
Write-Log -Message 'Deployment started' -Level Info -Component 'Deploy' -LogPath ./deploy.log
```

## ⚙️ Configuration

Each tcs module has a settings file at
`<ApplicationData>/PowerShell/Config/<ModuleName>/Module.Config.json`
(`%APPDATA%` on Windows, `~/.config` on Linux/macOS). It is created with the defaults the first
time the module loads. Change it with `Set-ModuleConfig`:

```powershell
Set-ModuleConfig -ModuleName tcs.core -UpdateWarning $false     # no update warnings
Set-ModuleConfig -ModuleName tcs.jira -Telemetry $false         # no telemetry for tcs.jira
Set-ModuleConfig -ModuleName tcs.core -Reset                    # back to defaults
```

| Setting | Default | Meaning |
| --- | --- | --- |
| `UpdateWarning` | `true` | Warn on import when a newer version is in the PowerShell Gallery |
| `UpdateCheckIntervalHours` | `24` | How often the gallery is checked |
| `Telemetry` | `true` | Send anonymous usage telemetry |
| `TelemetryUri` | empty | Telemetry ingestion endpoint (HTTPS). Nothing is sent while empty |
| `TelemetryApiKey` | empty | Key sent in the `X-API-Key` header |

Environment variables:

| Variable | Effect |
| --- | --- |
| `TCS_TELEMETRY_OPTOUT=1` | Turns telemetry off for every tcs module |
| `TCS_SKIP_UPDATE_CHECK=1` | Turns the gallery update check off (useful in CI) |
| `TCS_CONFIG_ROOT` | Moves the settings folder |
| `TCS_TELEMETRY_URI` / `TCS_TELEMETRY_APIKEY` | Override the telemetry endpoint and key |
| `TCS_MACHINE_KEY_PATH` | Linux/macOS: location of the LocalMachine protection key |

## 🔐 Protecting secrets

| Platform | CurrentUser (default) | LocalMachine |
| --- | --- | --- |
| Windows | DPAPI, user scope | DPAPI, machine scope |
| Linux/macOS | AES-256 + HMAC-SHA256, key in `~/.config/PowerShell/Config/tcs.core/protection.key` (mode 600, created automatically) | Same, key in `/etc/tcs.core/protection.key` (mode 644, created by root on first use) |

Use `-Key` with a 32-byte key to protect values that must be decrypted on other machines.
Values protected by tcs.core 0.2.x can still be decrypted; protect them again to upgrade them.

## 📖 Documentation

Get detailed help for any function:

```powershell
# View complete help
Get-Help ConvertTo-CamelCase -Full

# View examples only
Get-Help New-DynamicParameter -Examples

# View online help (when available)
Get-Help Set-ModuleConfig -Online
```

## 🛠️ Development

### Prerequisites

- PowerShell 5.1 or later (7.2+ recommended for development)
- PSScriptAnalyzer (for code quality)
- Pester (for testing)

### Building and Testing

Use the included build script for development tasks:

```powershell
# Validate the module
.\Build.ps1 -Task Validate

# Run all tests
.\Build.ps1 -Task Test

# Update version
.\Build.ps1 -Task UpdateVersion -Version "0.3.1"

# Prepare for release
.\Build.ps1 -Task PrepareRelease -Version "0.3.1"

# Clean build artifacts
.\Build.ps1 -Task Clean
```

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the coding standards, test requirements and release
process. Report security issues as described in [SECURITY.md](SECURITY.md).

## 🔄 CI/CD Pipeline

This project uses GitHub Actions for automated testing and publishing:

- **Pull Request Validation**: Runs on every PR to validate code quality and functionality
- **Automated Publishing**: Publishes to PowerShell Gallery when version tags are pushed
- **Release Creation**: Automatically creates GitHub releases with release notes

### Publishing a New Version

1. Update the version in `modules/tcs.core/tcs.core.psd1`
2. Update `CHANGELOG.md`, then open a pull request and merge it to `main`
3. CI creates the version tag automatically, and the tag publishes to the PowerShell Gallery

See [.github/PUBLISHING.md](.github/PUBLISHING.md) for detailed instructions.

## 📝 Version History

See [CHANGELOG.md](CHANGELOG.md).

## 🔒 Privacy and telemetry

tcs modules send anonymous usage telemetry to help find failing commands. Telemetry is on by
default and a notice is shown the first time a module is loaded. Nothing is sent until a
telemetry endpoint is configured.

Each event contains: time (UTC), module and command name, module version, duration, success,
the exception **type** on failure, PowerShell version and edition, OS family, PowerShell host
name, and a random installation ID created on first use.

It **never** contains: user names, machine names, file paths, hardware serial numbers, IP-based
identifiers, command arguments or error messages.

Turn it off with `Set-ModuleConfig -ModuleName <module> -Telemetry $false`, or for all tcs
modules with the environment variable `TCS_TELEMETRY_OPTOUT=1`.

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Nigel Tatschner** - TheCodeSaiyan
- GitHub: [@ntatschner](https://github.com/ntatschner)
- PowerShell Gallery: [TheCodeSaiyan](https://www.powershellgallery.com/profiles/TheCodeSaiyan)

## 🙏 Acknowledgments

- PowerShell Community for best practices and guidance
- Contributors and users who provide feedback and suggestions
- Microsoft PowerShell team for the excellent platform

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/issues)
- 💡 **Feature Requests**: [GitHub Issues](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/issues)
- 📖 **Documentation**: [Wiki](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/wiki)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/discussions)
