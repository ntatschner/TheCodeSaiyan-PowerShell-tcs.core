# TheCodeSaiyan PowerShell tcs.core Module

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/tcs.core.svg?style=flat-square&label=PowerShell%20Gallery)](https://www.powershellgallery.com/packages/tcs.core)
[![GitHub Release](https://img.shields.io/github/release/ntatschner/TheCodeSaiyan-PowerShell-tcs.core.svg?style=flat-square&label=GitHub%20Release)](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/ci-validate.yml?branch=main&style=flat-square&label=Build)](https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/actions)

A core utility module providing essential functions for the TheCodeSaiyan PowerShell module suite. This module includes configuration management, dynamic parameter creation, telemetry collection, and utility functions.

## 🚀 Features

- **Configuration Management**: Automated module configuration handling with JSON persistence
- **Dynamic Parameters**: Simplified creation of dynamic parameters for advanced PowerShell functions
- **Telemetry Collection**: Privacy-focused usage analytics and error reporting
- **Utility Functions**: String manipulation and formatting helpers
- **Comprehensive Help**: Full documentation for all functions with examples
- **CI/CD Integration**: Automated testing and publishing to PowerShell Gallery

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
# Clone the repository
git clone https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core.git

# Import the module
Import-Module .\TheCodeSaiyan-PowerShell-tcs.core\module\tcs.core\tcs.core.psd1
```

## 🔧 Functions

### Public Functions

#### `ConvertTo-CamelCase`
Converts strings to camelCase format for consistent naming conventions.

```powershell
ConvertTo-CamelCase -Value "HelloWorld"
# Returns: "helloWorld"

"XMLHttpRequest" | ConvertTo-CamelCase
# Returns: "xMLHttpRequest"
```

#### `New-DynamicParameter`
Simplifies the creation of dynamic parameters in PowerShell functions.

```powershell
# Create a mandatory string parameter
$dynParam = New-DynamicParameter -Name "ServerName" -ParameterType ([string]) -Mandatory

# Create a parameter with validation
$dynParam = New-DynamicParameter -Name "Environment" -ParameterType ([string]) -ValidateSet @("Dev", "Test", "Prod")

# Create a parameter with custom validation
$script = { $_ -match '^[A-Z]{2,3}$' }
$dynParam = New-DynamicParameter -Name "CountryCode" -ParameterType ([string]) -ValidateScript $script
```

#### `Set-ModuleConfig`  
Manages module configuration settings with automatic JSON persistence.

```powershell
# Enable update warnings
Set-ModuleConfig -UpdateWarning "True" -ModuleName "tcs.core"

# Configure telemetry and paths
Set-ModuleConfig -BasicTelemetry -ModuleName "MyModule" -ModulePath "C:\Modules\MyModule"
```

### Private Functions

- **`Get-ModuleConfig`**: Retrieves module configuration with automatic discovery
- **`Get-ModuleStatus`**: Checks for module updates from PowerShell Gallery
- **`Get-ParameterValues`**: Filters and processes PSBoundParameters
- **`Invoke-TelemetryCollection`**: Collects anonymized usage analytics

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

- PowerShell 5.1 or later
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
.\Build.ps1 -Task UpdateVersion -Version "0.1.8"

# Prepare for release
.\Build.ps1 -Task PrepareRelease -Version "0.1.8"

# Clean build artifacts
.\Build.ps1 -Task Clean
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`.\Build.ps1 -Task Test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 🔄 CI/CD Pipeline

This project uses GitHub Actions for automated testing and publishing:

- **Pull Request Validation**: Runs on every PR to validate code quality and functionality
- **Automated Publishing**: Publishes to PowerShell Gallery when version tags are pushed
- **Release Creation**: Automatically creates GitHub releases with release notes

### Publishing a New Version

1. Update the version in `module/tcs.core/tcs.core.psd1`
2. Commit your changes: `git commit -am "Release v0.1.8"`
3. Create and push a version tag: `git tag v0.1.8 && git push origin v0.1.8`
4. GitHub Actions will automatically validate and publish to PowerShell Gallery

See [.github/PUBLISHING.md](.github/PUBLISHING.md) for detailed instructions.

## 📝 Version History

### v0.1.7 (Current)
- ✅ Added comprehensive help documentation for all functions
- ✅ Updated module manifest with explicit exports
- ✅ Enhanced parameter validation and type safety
- ✅ Added CI/CD pipeline with GitHub Actions
- ✅ Improved code quality with PSScriptAnalyzer compliance

### Previous Versions
- **v0.1.6**: Added ConvertTo-CamelCase function
- **v0.1.5**: Enhanced telemetry collection
- **v0.1.0**: Initial release with core functionality

## 🔒 Privacy and Security

This module includes optional telemetry collection that:
- ✅ Collects only anonymized usage data
- ✅ Never collects personally identifiable information
- ✅ Can be disabled via module configuration
- ✅ Uses secure HTTPS transmission
- ✅ Helps improve module functionality and reliability

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

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