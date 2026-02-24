# GAM7

PowerShell utilities for Google Workspace mailbox management, backup, and migration using [GAM7 (GAMADV-XTD3)](https://github.com/GAM-team/GAM).

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

GAM7 is a PowerShell module that provides a cohesive set of functions for automating Google Workspace user and mailbox operations. It wraps [GAM7](https://github.com/GAM-team/GAM) commands with PowerShell-friendly interfaces, pipeline support, and secure backup capabilities.

## Dependencies

- **PowerShell 5.1+** (PowerShell 7+ recommended)
- **GAM7** (GAMADV-XTD3) - [Installation Guide](https://github.com/GAM-team/GAM/wiki)
- **Google Workspace** admin account with appropriate permissions

## INSTALL

### Option 1: Install from Source (Current)

```powershell
# Clone the repository
git clone https://github.com/electblake/PowerShell-GAM7.git
cd PowerShell-GAM7

# Import the module
Import-Module ./GAM7
```

### Option 2: Install from PowerShell Gallery (Coming Soon)

```powershell
Install-Module -Name GAM7
Import-Module GAM7
```

## Quick Start

### List all mailboxes

```powershell
# Get all mailboxes with storage and message counts
Get-Mailbox | Format-Table -AutoSize

# Get one mailbox
Get-Mailbox -Email stephen.tracy@northone.com

# Filter active mailboxes only
Get-Mailbox | Where-Object { -not $_.Suspended -and -not $_.Archived }
```

### Manage user accounts

```powershell
# Enable a user account
Enable-Mailbox -Email user@domain.com

# Disable a user account
Disable-Mailbox -Email user@domain.com

# Process multiple users via pipeline
Get-Mailbox | Where-Object { $_.LastLogin -eq 'Never' } | Disable-Mailbox
```

### Export mailboxes

```powershell
# Export all non-Spam/non-Trash messages for a user (matches Get-Mailbox counts)
Export-Mailbox -Email user@domain.com

# Export with search query
Export-Mailbox -Email user@domain.com -Query "from:example.com"

# Export multiple mailboxes
Get-Mailbox | Where-Object { -not $_.Suspended } | Export-Mailbox
```

### Search messages

```powershell
# Search one mailbox (Gmail query syntax)
Get-Mail -Email stephen.tracy@northone.com -Query "snowflake"

# Keyword-only query also works
Get-Mail -Email stephen.tracy@northone.com -Query "invoice" -MaxResults 200

# Pipe from Get-Mailbox
Get-Mailbox -Email stephen.tracy@northone.com | Get-Mail -Query "from:snowflake.com"

# Search then export using the same Email+Query filter
Get-Mail -Email stephen.tracy@northone.com -Query "snowflake" |
    Select-Object -Unique Email, Query |
    Export-Mailbox
```

### Backup GAM configuration

```powershell
# Generate encryption key (one time)
New-GamEncryptionKey

# Backup entire GAM config (encrypted)
Backup-GamConfig

# Restore GAM config
Restore-GamConfig -InputPath gam-config-backup.encrypted
```

### Interactive bulk operations

```powershell
# Launch interactive mailbox manager
Invoke-BulkMailboxAction

# With search query for exports
Invoke-BulkMailboxAction -Query "WorkSafeBC"
```

## Available Commands

| Command                    | Description                                           |
| -------------------------- | ----------------------------------------------------- |
| `Get-Mail`                 | Search Gmail messages in a mailbox by query           |
| `Get-Mailbox`              | List domain mailboxes with storage and message counts |
| `Enable-Mailbox`           | Enable and move user to Active Staff OU               |
| `Disable-Mailbox`          | Suspend and move user to Disabled Accounts OU         |
| `Remove-Mailbox`           | Delete user account (recoverable for 20 days)         |
| `Export-Mailbox`           | Export mailbox messages to .eml files                 |
| `Invoke-BulkMailboxAction` | Interactive bulk mailbox management                   |
| `Debug-GAM`                | Run diagnostic checks for GAM access                  |
| `New-GamEncryptionKey`     | Generate AES-256 encryption key                       |
| `Backup-GamConfig`         | Create encrypted backup of GAM config                 |
| `Restore-GamConfig`        | Restore GAM config from encrypted backup              |
| `Export-GamAuthSecure`     | Encrypt individual GAM config files                   |
| `Import-GamAuthSecure`     | Decrypt individual GAM config files                   |

## Getting Help

Each function includes comprehensive help documentation:

```powershell
# View help for any command
Get-Help Enable-Mailbox -Full

# View examples
Get-Help Export-Mailbox -Examples

# List all available commands
Get-Command -Module GAM7
```

## Examples

More end-to-end examples are included in `GAM7/Examples/`.

### Example 1: Disable inactive accounts

```powershell
Get-Mailbox | 
    Where-Object { $_.LastLogin -eq 'Never' } | 
    Disable-Mailbox
```

### Example 2: Export suspended accounts

```powershell
Get-Mailbox | 
    Where-Object { $_.Suspended } | 
    Export-Mailbox -Query "important"
```

### Example 3: Backup before migration

```powershell
# Create encryption key
New-GamEncryptionKey -OutputPath ~/secure/gam-key.key

# Backup GAM configuration
Backup-GamConfig -KeyFile ~/secure/gam-key.key -OutputPath ~/backups/gam-backup.encrypted

# Store key securely (e.g., password manager)
```

### Example 4: Restore on new machine

```powershell
# Copy key and backup to new machine
Restore-GamConfig -InputPath ~/backups/gam-backup.encrypted -KeyFile ~/secure/gam-key.key
```

## Configuration

### GAM Configuration

The module uses your existing GAM7 configuration. Ensure GAM is properly configured:

```bash
# Test GAM access
gam info domain
gam info customer

# Or use the module's diagnostic tool
Debug-GAM
```

### Environment Variables

The module respects these environment variables:

- `GAMCFGDIR` - GAM configuration directory (defaults to `~/.gam`)

## Architecture

The GAM7 module follows cohesive design patterns:

- **Pipeline-friendly** - Functions accept input from pipeline
- **Progress indicators** - Clear feedback for long-running operations
- **Consistent output** - Structured objects with Format-List
- **Non-terminating errors** - Uses warnings for expected conditions
- **Stateless functions** - No global state or tight coupling

See [GAM7/PATTERNS.md](GAM7/PATTERNS.md) for detailed design patterns.

## Development

### Running Tests

```powershell
# Validate manifest
Test-ModuleManifest -Path ./GAM7/GAM7.psd1

# Run ScriptAnalyzer (Microsoft guidance recommends Warning severity)
Invoke-ScriptAnalyzer -Path ./GAM7 -Recurse -Severity Warning

# Run tests
Invoke-Pester -Path ./tests -CI
```

### Building

```powershell
# Create a zip package in ./artifacts
Compress-Archive -Path ./GAM7 -DestinationPath ./artifacts/GAM7.zip -Force
```

### Contributing

Contributions are welcome! Please follow the cohesive patterns documented in [GAM7/PATTERNS.md](GAM7/PATTERNS.md).

## Documentation

- [Design Patterns](GAM7/PATTERNS.md) - Module design patterns and conventions
- [GAM Wiki](https://github.com/GAM-team/GAM/wiki) - GAM command reference and examples
- [Publishing Guide](PUBLISHING.md) - Local test publish and PowerShell Gallery release workflow

## Roadmap

- [ ] Publish initial `1.0.1` release to PowerShell Gallery
- [ ] Support for additional GAM features
- [ ] Cross-platform testing (Windows/macOS/Linux)

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START -->
**Author & Maintainer:**
- [@electblake](https://github.com/electblake)
<!-- ALL-CONTRIBUTORS-LIST:END -->

## Acknowledgments

This project builds upon:
- **[GAM7](https://github.com/GAM-team/GAM)** - Command-line management for Google Workspace (by Ross Scroggs, Jay Lee, and contributors)
- **[Google Workspace](https://workspace.google.com/)** - Cloud productivity and collaboration tools

## AI-Assisted Development

This entire codebase was developed using AI-assisted coding tools. All code, documentation, and tests were generated by AI agents under human direction and review.

### Development Tools & Stack

| Tool & Version                        | Purpose                                                          |
| ------------------------------------- | ---------------------------------------------------------------- |
| **GitHub Copilot** (Latest, Feb 2026) | Real-time code completion, function scaffolding                  |
| **Claude Sonnet** (4.5, 4.6)          | Architecture design, code review, refactoring, documentation     |
| **Claude Opus** (4.5, 4.6)            | Complex problem solving, test generation, pattern implementation |
| **OpenAI Codex** (5.2, 5.3)           | Core implementation, algorithm development                       |
| **Visual Studio Code**                | Editor                                                           |
| **PowerShell** (7.x)                  | Language (developed with cross-platform support)                 |
| **mise**                              | Dependency manager                                               |
| **Pester** (5.5.0)                    | Testing framework                                                |
| **GitHub Actions**                    | CI/CD with mise-action                                           |
