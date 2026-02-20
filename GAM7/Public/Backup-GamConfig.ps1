function Backup-GamConfig {
<#
.SYNOPSIS
    Backs up the entire GAM7 config folder as a single AES-encrypted artifact.
.DESCRIPTION
    Compresses the GAM config directory into a zip archive, then encrypts
    the archive bytes as a SecureString using the provided AES key.
    Produces a single .encrypted file.
.EXAMPLE
    Backup-GamConfig -KeyFile ./gam-encryption.key
.EXAMPLE
    Backup-GamConfig -GamConfigDir ~/.gam -OutputPath ~/backups/gam-backup.encrypted
.OUTPUTS
    File: gam-config-backup.encrypted (or custom name via -OutputPath)
#>
  [CmdletBinding()]
  param(
    [Parameter()]
    [string]$GamConfigDir,

    [Parameter()]
    [string]$KeyFile = (Join-Path (Get-Location) 'gam-encryption.key'),

    [Parameter()]
    [string]$OutputPath = (Join-Path (Get-Location) 'gam-config-backup.encrypted'),

    [Parameter()]
    [switch]$Force
  )

  $activity = 'Backup-GamConfig'
    
  if (-not $GamConfigDir) {
    $GamConfigDir = $env:GAMCFGDIR
    if (-not $GamConfigDir) {
      $GamConfigDir = Join-Path $HOME '.gam'
    }
  }

  Write-Host "$activity : $GamConfigDir" -ForegroundColor Cyan

  if (-not (Test-Path $GamConfigDir)) {
    Write-Warning "GAM config directory not found: $GamConfigDir"
    return
  }

  if (-not (Test-Path $KeyFile)) {
    Write-Warning "Encryption key not found: $KeyFile. Run New-GamEncryptionKey first."
    return
  }

  Write-Progress -Activity $activity -Status 'Loading encryption key...' -PercentComplete 10
    
  $keyBase64 = [System.IO.File]::ReadAllText($KeyFile).Trim()
  [byte[]]$key = [Convert]::FromBase64String($keyBase64)

  if ($key.Length -notin @(16, 24, 32)) {
    Write-Warning "Invalid key length: $($key.Length) bytes. Must be 16, 24, or 32."
    return
  }

  if ((Test-Path $OutputPath) -and -not $Force) {
    Write-Warning "Output file already exists: $OutputPath. Use -Force to overwrite."
    return
  }

  $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) "gam-backup-$(Get-Date -Format 'yyyyMMddHHmmss').zip"

  try {
    Write-Progress -Activity $activity -Status 'Compressing GAM config folder...' -PercentComplete 30
    Compress-Archive -Path (Join-Path $GamConfigDir '*') -DestinationPath $tempZip -CompressionLevel Optimal -Force

    Write-Progress -Activity $activity -Status 'Encrypting backup...' -PercentComplete 60
    $zipBytes = [System.IO.File]::ReadAllBytes($tempZip)
    $b64 = [Convert]::ToBase64String($zipBytes)
    $secure = ConvertTo-SecureString -String $b64 -AsPlainText -Force
    $encrypted = ConvertFrom-SecureString -SecureString $secure -Key $key

    Write-Progress -Activity $activity -Status 'Writing encrypted backup...' -PercentComplete 85
    $outputDir = Split-Path $OutputPath -Parent
    if ($outputDir -and -not (Test-Path $outputDir)) {
      New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($OutputPath, $encrypted)

    Write-Progress -Activity $activity -Completed

    $sizeMB = [math]::Round((Get-Item $OutputPath).Length / 1MB, 2)

    [PSCustomObject]@{
      SourceDir  = $GamConfigDir
      OutputPath = $OutputPath
      SizeMB     = $sizeMB
      Encrypted  = 'Yes'
    } | Format-List
  }
  finally {
    if (Test-Path $tempZip) {
      Remove-Item $tempZip -Force
    }
  }
}
