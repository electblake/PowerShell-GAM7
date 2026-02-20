function New-GamEncryptionKey {
  <#
.SYNOPSIS
    Generates a 32-byte AES-256 encryption key for GAM auth encryption.
.DESCRIPTION
    Creates a cryptographically secure 256-bit encryption key for use with
    Export-GamAuthSecure and Backup-GamConfig functions.
.PARAMETER OutputPath
    Path where the encryption key will be stored. Defaults to 'gam-encryption.key' in current directory.
.PARAMETER Force
    Overwrite existing key file if present.
.EXAMPLE
    New-GamEncryptionKey
.EXAMPLE
    New-GamEncryptionKey -OutputPath ~/secure/my-key.key -Force
.OUTPUTS
    PSCustomObject with OutputPath and a security warning.
#>
  [CmdletBinding()]
  param(
    [Parameter()]
    [string]$OutputPath = (Join-Path (Get-Location) 'gam-encryption.key'),

    [Parameter()]
    [switch]$Force
  )

  process {
    $activity = 'New-GamEncryptionKey'
    Write-Host "$activity : $OutputPath" -ForegroundColor Cyan

    if ((Test-Path $OutputPath) -and -not $Force) {
      Write-Warning "Key file already exists at $OutputPath. Use -Force to overwrite."
      return
    }

    Write-Progress -Activity $activity -Status 'Generating encryption key...' -PercentComplete 30

    $keyBytes = [byte[]]::new(32)
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($keyBytes)
    $rng.Dispose()

    Write-Progress -Activity $activity -Status 'Writing key to file...' -PercentComplete 70
    [System.IO.File]::WriteAllText($OutputPath, [Convert]::ToBase64String($keyBytes))

    Write-Progress -Activity $activity -Completed

    Write-Warning "Store this key securely. Without it, encrypted data cannot be recovered."

    [PSCustomObject]@{
      OutputPath = $OutputPath
      KeySize    = '256-bit (32 bytes)'
      Created    = 'Yes'
    } | Format-List
  }
}
