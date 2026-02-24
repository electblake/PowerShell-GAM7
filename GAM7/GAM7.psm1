# GAM7 PowerShell Module
# Consolidates GAM7 utilities for Google Workspace management, backup, and migration

# Dot-source private helper functions
$PrivateFunctionPath = Join-Path $PSScriptRoot 'Private'
if (Test-Path $PrivateFunctionPath) {
  Get-ChildItem -Path $PrivateFunctionPath -Filter '*.ps1' -File | ForEach-Object {
    . $_.FullName
  }
}

# Dot-source all public functions
$PublicFunctionPath = Join-Path $PSScriptRoot 'Public'
$PublicFunctions = @(
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

foreach ($func in $PublicFunctions) {
  $funcPath = Join-Path $PublicFunctionPath "$func.ps1"
  if (Test-Path $funcPath) {
    . $funcPath
  }
}

# Export functions (also specified in manifest, but good practice to do here too)
Export-ModuleMember -Function $PublicFunctions
