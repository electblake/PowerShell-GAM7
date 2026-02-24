function Restore-GamConfig {
<#
.SYNOPSIS
    Restores a GAM7 config folder from an AES-encrypted backup artifact.
.DESCRIPTION
    Decrypts the backup artifact, decompresses the zip archive, and writes
    the config folder contents to the specified output directory.
.EXAMPLE
    Restore-GamConfig -KeyFile ./gam-encryption.key
.OUTPUTS
    Restored GAM config directory at the specified path.
#>
  [CmdletBinding()]
  param(
    [Parameter()]
    [string]$InputPath = (Join-Path (Get-Location) 'gam-config-backup.encrypted'),

    [Parameter()]
    [string]$KeyFile = (Join-Path (Get-Location) 'gam-encryption.key'),

    [Parameter()]
    [string]$OutputDir = (Join-Path (Get-Location) 'gam-restored'),

    [Parameter()]
    [switch]$RestoreToGamDir,

    [Parameter()]
    [switch]$Force
  )

  $activity = 'Restore-GamConfig'

  if (-not (Test-Path $KeyFile)) {
    Write-Warning "Encryption key not found: $KeyFile"
    return
  }

  Write-Progress -Activity $activity -Status 'Loading encryption key...' -PercentComplete 10

  $keyBase64 = [System.IO.File]::ReadAllText($KeyFile).Trim()
  [byte[]]$key = [Convert]::FromBase64String($keyBase64)

  if ($key.Length -notin @(16, 24, 32)) {
    Write-Warning "Invalid key length: $($key.Length) bytes. Must be 16, 24, or 32."
    return
  }

  if ($RestoreToGamDir) {
    $OutputDir = $env:GAMCFGDIR
    if (-not $OutputDir) {
      $OutputDir = Join-Path $HOME '.gam'
    }
    Write-Warning "Restoring directly to GAM config directory: $OutputDir"
  }

  Write-Verbose "$activity : $InputPath -> $OutputDir"

  if (-not (Test-Path $InputPath)) {
    Write-Warning "Backup file not found: $InputPath"
    return
  }

  if ((Test-Path $OutputDir) -and (Get-ChildItem $OutputDir -Force | Select-Object -First 1) -and -not $Force) {
    Write-Warning "Output directory is not empty: $OutputDir. Use -Force to overwrite."
    return
  }

  Write-Progress -Activity $activity -Status 'Decrypting backup...' -PercentComplete 30
  $encryptedBytes = [System.IO.File]::ReadAllBytes($InputPath)
  $zipBytes = Unprotect-GamData -CipherBytes $encryptedBytes -AesKey $key

  $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) "gam-restore-$(Get-Date -Format 'yyyyMMddHHmmss').zip"

  try {
    [System.IO.File]::WriteAllBytes($tempZip, $zipBytes)

    if (-not (Test-Path $OutputDir)) {
      New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }

    Write-Progress -Activity $activity -Status 'Extracting to output directory...' -PercentComplete 70
    Expand-Archive -Path $tempZip -DestinationPath $OutputDir -Force

    Write-Progress -Activity $activity -Completed

    $itemCount = (Get-ChildItem $OutputDir -Recurse -File).Count

    [PSCustomObject]@{
      InputPath  = $InputPath
      OutputDir  = $OutputDir
      FilesCount = $itemCount
      Restored   = 'Yes'
    } | Format-List
  }
  finally {
    if (Test-Path $tempZip) {
      Remove-Item $tempZip -Force
    }
  }
}
