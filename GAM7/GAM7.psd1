@{
  RootModule        = 'GAM7.psm1'
  ModuleVersion     = '1.0.2'
  GUID              = 'f4c8d2e1-6a3e-4b9f-c7d4-2e9f5a8b3c6d'
  Author            = 'electblake'
  CompanyName       = 'electblake'
  Copyright         = '(c) 2025 electblake. MIT License.'
  Description       = 'GAM7 utilities for Google Workspace mailbox management, backup, and migration. Provides functions for managing user accounts, exporting mailboxes, and securing/restoring GAM configuration.'
  PowerShellVersion = '5.1'
  CompatiblePSEditions = @('Desktop', 'Core')
    
  FunctionsToExport = @(
    'Backup-GamConfig',
    'Debug-GAM',
    'Disable-Mailbox',
    'Enable-Mailbox',
    'Export-GamAuthSecure',
    'Export-Mailbox',
    'Get-Mail',
    'Get-Mailbox',
    'Import-GamAuthSecure',
    'Invoke-BulkMailboxAction',
    'New-GamEncryptionKey',
    'Remove-Mailbox',
    'Restore-GamConfig'
  )

  CmdletsToExport = @()
  VariablesToExport = @()
  AliasesToExport = @()
    
  PrivateData       = @{
    PSData = @{
      Tags         = @(
        'GAM7',
        'GoogleWorkspace',
        'Gmail',
        'Backup',
        'Migration',
        'Mailbox',
        'PSEdition_Desktop',
        'PSEdition_Core',
        'Windows',
        'Linux',
        'MacOS'
      )
      ProjectUri   = 'https://github.com/electblake/PowerShell-GAM7'
      LicenseUri   = 'https://github.com/electblake/PowerShell-GAM7/blob/main/LICENSE'
      ReleaseNotes = '1.0.2 patch release: README documentation updates and PSGallery install/license clarification.'
    }
  }
}
