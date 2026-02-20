# GAM7 PowerShell Module
# Consolidates GAM7 utilities for Google Workspace management, backup, and migration

# Dot-source all public functions
$PublicFunctionPath = Join-Path $PSScriptRoot 'Public'
$PublicFunctions = @(
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

foreach ($func in $PublicFunctions) {
  $funcPath = Join-Path $PublicFunctionPath "$func.ps1"
  if (Test-Path $funcPath) {
    . $funcPath
  }
}

# Export functions (also specified in manifest, but good practice to do here too)
Export-ModuleMember -Function $PublicFunctions
