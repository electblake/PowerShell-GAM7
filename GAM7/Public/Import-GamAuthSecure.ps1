function Import-GamAuthSecure {
<#
.SYNOPSIS
    Decrypts AES-encrypted SecureString files back into individual GAM7 config and auth files.
.DESCRIPTION
    Decrypts encrypted GAM config files using AES-256 decryption with a provided key.
    Restores sensitive files from encrypted backups for use with GAM.
.EXAMPLE
    Import-GamAuthSecure -KeyFile ./gam-encryption.key
.OUTPUTS
    Decrypted files in the specified output directory (default: ./gam-restored)
#>
  [CmdletBinding()]
  param(
    [Parameter()]
    [string]$InputDir = (Join-Path (Get-Location) 'gam-secure-export'),

    [Parameter()]
    [string]$KeyFile = (Join-Path (Get-Location) 'gam-encryption.key'),

    [Parameter()]
    [string]$OutputDir = (Join-Path (Get-Location) 'gam-restored'),

    [Parameter()]
    [switch]$RestoreToGamDir,

    [Parameter()]
    [switch]$Force
  )

  $activity = 'Import-GamAuthSecure'

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

  Write-Host "$activity : $InputDir -> $OutputDir" -ForegroundColor Cyan

  if (-not (Test-Path $InputDir)) {
    Write-Warning "Input directory not found: $InputDir"
    return
  }

  if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
  }

  Write-Progress -Activity $activity -Status 'Decrypting files...' -PercentComplete 30

  $decryptFile = {
    param([string]$SourcePath, [string]$DestPath, [byte[]]$AesKey)
    $encrypted = [System.IO.File]::ReadAllText($SourcePath).Trim()
    $secure = ConvertTo-SecureString -String $encrypted -Key $AesKey
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
      $b64 = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
      [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    $rawBytes = [Convert]::FromBase64String($b64)
    [System.IO.File]::WriteAllBytes($DestPath, $rawBytes)
  }

  $restored = 0
  $encryptedFiles = Get-ChildItem -Path $InputDir -Filter '*.encrypted' -Recurse

  foreach ($ef in $encryptedFiles) {
    $relativePath = $ef.FullName.Substring($InputDir.TrimEnd([IO.Path]::DirectorySeparatorChar).Length + 1)
    $originalName = $relativePath -replace '\.encrypted$', ''
    $destPath = Join-Path $OutputDir $originalName

    $destDir = Split-Path $destPath -Parent
    if (-not (Test-Path $destDir)) {
      New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if ((Test-Path $destPath) -and -not $Force) {
      Write-Warning "Skipping (exists): $destPath. Use -Force to overwrite."
      continue
    }

    & $decryptFile $ef.FullName $destPath $key
    $restored++
  }

  Write-Progress -Activity $activity -Completed

  [PSCustomObject]@{
    InputDir   = $InputDir
    OutputDir  = $OutputDir
    FilesCount = $restored
    Restored   = 'Yes'
  } | Format-List
}
