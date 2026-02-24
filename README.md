# GAM7

PowerShell module for Google Workspace mailbox administration using GAM v7. Install from [PSGallery](https://www.powershellgallery.com/packages/GAM7).

## Requirements

- [GAM7 (GAMADV-XTD3)](https://github.com/GAM-team/GAM) installed and authenticated
- https://mise.jdx.dev/getting-started.html

## Install

```powershell
Install-Module -Name GAM7 -Scope CurrentUser
```

## Usage

```powershell
# Load 
Import-Module GAM7

# Basic Usage
Get-Command -Module GAM7
Get-Mailbox -Email user@domain.com
Export-Mailbox -Email user@domain.com -Query "from:example.com"

# Help
Get-Help Get-Mailbox -Full
Get-Help Export-Mailbox -Examples
```

## License

[LICENSE](LICENSE).
