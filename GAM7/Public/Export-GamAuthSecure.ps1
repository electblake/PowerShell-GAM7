function Export-GamAuthSecure {
  <#
.SYNOPSIS
    Encrypts individual GAM7 config and auth files into AES-encrypted SecureString files.
.DESCRIPTION
    Encrypts specified GAM config files using AES-256 encryption with a provided key.
    Creates encrypted copies of sensitive files for secure backup and transfer.
.EXAMPLE
    Export-GamAuthSecure -KeyFile ./gam-encryption.key
.OUTPUTS
    .encrypted files in the specified output directory (default: ./gam-secure-export)
#>
  [CmdletBinding()]
  param(
    [Parameter()]
    [string]$GamConfigDir,

    [Parameter()]
    [string]$KeyFile = (Join-Path (Get-Location) 'gam-encryption.key'),

    [Parameter()]
    [string]$OutputDir = (Join-Path (Get-Location) 'gam-secure-export'),

    [Parameter()]
    [switch]$Force
  )

  $activity = 'Export-GamAuthSecure'

  if (-not $GamConfigDir) {
    $GamConfigDir = $env:GAMCFGDIR
    if (-not $GamConfigDir) {
      $GamConfigDir = Join-Path $HOME '.gam'
    }
  }

  Write-Host "$activity : $GamConfigDir -> $OutputDir" -ForegroundColor Cyan

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

  $coreFiles = @(
    'gam.cfg',
    'client_secrets.json',
    'oauth2.txt',
    'oauth2service.json',
    'extra_args.txt'
  )

  if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
  }

  Write-Progress -Activity $activity -Status 'Encrypting core files...' -PercentComplete 30

  $encryptFile = {
    param([string]$SourcePath, [string]$DestPath, [byte[]]$AesKey)
    $rawBytes = [System.IO.File]::ReadAllBytes($SourcePath)
    $b64 = [Convert]::ToBase64String($rawBytes)
    $secure = ConvertTo-SecureString -String $b64 -AsPlainText -Force
    $encrypted = ConvertFrom-SecureString -SecureString $secure -Key $AesKey
    [System.IO.File]::WriteAllText($DestPath, $encrypted)
  }

  $exported = 0

  foreach ($file in $coreFiles) {
    $srcPath = Join-Path $GamConfigDir $file
    if (Test-Path $srcPath) {
      $destPath = Join-Path $OutputDir "$file.encrypted"
      if ((Test-Path $destPath) -and -not $Force) {
        Write-Warning "Skipping (exists): $destPath. Use -Force to overwrite."
        continue
      }
      & $encryptFile $srcPath $destPath $key
      $exported++
    }
    else {
      Write-Verbose "Not found, skipping: $srcPath"
    }
  }

  Write-Progress -Activity $activity -Status 'Scanning for section subdirectories...' -PercentComplete 70

  $gamCfgPath = Join-Path $GamConfigDir 'gam.cfg'
  if (Test-Path $gamCfgPath) {
    $cfgContent = Get-Content $gamCfgPath -Raw
    $sectionDirs = [regex]::Matches($cfgContent, '(?mi)^\s*config_dir\s*=\s*(.+)$') |
    ForEach-Object { $_.Groups[1].Value.Trim() } |
    Where-Object { $_ -and $_ -ne $GamConfigDir -and $_ -notmatch '^[/\\~]' } |
    Sort-Object -Unique

    foreach ($subDir in $sectionDirs) {
      $subDirFull = Join-Path $GamConfigDir $subDir
      if (Test-Path $subDirFull) {
        $subOutDir = Join-Path $OutputDir $subDir
        if (-not (Test-Path $subOutDir)) {
          New-Item -ItemType Directory -Path $subOutDir -Force | Out-Null
        }

        $subFiles = @('client_secrets.json', 'oauth2.txt', 'oauth2service.json')
        foreach ($sf in $subFiles) {
          $sfPath = Join-Path $subDirFull $sf
          if (Test-Path $sfPath) {
            $destPath = Join-Path $subOutDir "$sf.encrypted"
            if ((Test-Path $destPath) -and -not $Force) {
              Write-Warning "Skipping (exists): $destPath. Use -Force to overwrite."
              continue
            }
            & $encryptFile $sfPath $destPath $key
            $exported++
          }
        }
      }
    }
  }

  Write-Progress -Activity $activity -Completed

  [PSCustomObject]@{
    SourceDir  = $GamConfigDir
    OutputDir  = $OutputDir
    FilesCount = $exported
    Encrypted  = 'Yes'
  } | Format-List
}
