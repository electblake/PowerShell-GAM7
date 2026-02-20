@{
  RootModule        = 'GAM7.psm1'
  ModuleVersion     = '1.0.0'
  GUID              = 'f4c8d2e1-6a3e-4b9f-c7d4-2e9f5a8b3c6d'
  Author            = 'electblake'
  Description       = 'GAM7 utilities for Google Workspace mailbox management, backup, and migration. Provides functions for managing user accounts, exporting mailboxes, and securing/restoring GAM configuration.'
  PowerShellVersion = '5.1'
    
  FunctionsToExport = @(
    'Backup-GamConfig',
    'Debug-GAM',
    'Disable-Mailbox',
    'Enable-Mailbox',
    'Export-GamAuthSecure',
    'Export-Mailbox',
    'Get-Mailbox',
    'Import-GamAuthSecure',
    'Invoke-BulkMailboxAction',
    'New-GamEncryptionKey',
    'Remove-Mailbox',
    'Restore-GamConfig'
  )
    
  PrivateData       = @{
    PSData = @{
      Tags         = @('GAM7', 'GoogleWorkspace', 'Gmail', 'Backup', 'Migration', 'Mailbox')
      ProjectUri   = 'https://github.com/electblake/gmail_sunset_searcher'
      ReleaseNotes = 'Initial release. Consolidates mailbox management and backup utilities into a single cohesive module.'
    }
  }
}
