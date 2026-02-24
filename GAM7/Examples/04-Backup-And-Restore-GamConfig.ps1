<#
.SYNOPSIS
  Backup and restore GAM configuration using module encryption utilities.
.DESCRIPTION
  Creates an AES key, writes an encrypted backup artifact, then restores to a test folder.
#>

Import-Module GAM7 -Force

$keyPath = Join-Path $PWD 'gam-encryption.key'
$backupPath = Join-Path $PWD 'gam-config-backup.encrypted'
$restorePath = Join-Path $PWD 'gam-config-restore-test'

New-GamEncryptionKey -OutputPath $keyPath -Force -Verbose
Backup-GamConfig -KeyFile $keyPath -OutputPath $backupPath -Force -Verbose
Restore-GamConfig -KeyFile $keyPath -InputPath $backupPath -OutputDir $restorePath -Force -Verbose
