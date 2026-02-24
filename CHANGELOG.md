# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Interactive TUI for mailbox management
- Export to additional formats (PST, MBOX)
- Advanced search/filter capabilities
- Bulk operations from CSV input

## [1.0.0] - TBD

### Added
- Initial release of GAM7 PowerShell module
- Gmail mailbox management commands:
  - `Enable-Mailbox` - Unsuspend user and restore mailbox access
  - `Disable-Mailbox` - Suspend user and disable mailbox
  - `Remove-Mailbox` - Delete user (recoverable for 20 days)
  - `Export-Mailbox` - Export Gmail messages to .eml files
  - `Get-Mailbox` - List all mailboxes with statistics
  - `Invoke-BulkMailboxAction` - Interactive bulk operations
- GAM configuration backup/security commands:
  - `Backup-GamConfig` - Encrypted backup of GAM config
  - `Restore-GamConfig` - Restore encrypted GAM config backup
  - `Export-GamAuthSecure` - Encrypt individual GAM files
  - `Import-GamAuthSecure` - Decrypt individual GAM files
  - `New-GamEncryptionKey` - Generate AES-256 encryption key
- Diagnostic commands:
  - `Debug-GAM` - Run comprehensive GAM diagnostics
- AES-256 encryption for sensitive GAM configuration files
- Pipeline support for all mailbox commands
- Comprehensive comment-based help documentation
- Pester 5.x test suite
- Build script for validation and packaging
- GitHub Actions CI/CD workflows

### Changed
- N/A (initial release)

### Deprecated
- N/A (initial release)

### Removed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Security
- Secure encryption of GAM OAuth tokens and configuration
- Password-protected backup archives

---

## Release Types

- **Major** (x.0.0): Breaking changes, major new features
- **Minor** (0.x.0): New features, backward compatible
- **Patch** (0.0.x): Bug fixes, minor improvements

[Unreleased]: https://github.com/electblake/gmail_sunset_searcher/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/electblake/gmail_sunset_searcher/releases/tag/v1.0.0
