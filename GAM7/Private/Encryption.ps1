function Protect-GamData {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [byte[]]$PlainBytes,

    [Parameter(Mandatory)]
    [byte[]]$AesKey
  )

  $header = [System.Text.Encoding]::ASCII.GetBytes('GAM7ENC1')
  $aes = [System.Security.Cryptography.Aes]::Create()

  try {
    $aes.Key = $AesKey
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.GenerateIV()

    $encryptor = $aes.CreateEncryptor()
    try {
      $cipherBytes = $encryptor.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Length)
    }
    finally {
      $encryptor.Dispose()
    }

    $payload = [byte[]]::new($header.Length + $aes.IV.Length + $cipherBytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($aes.IV, 0, $payload, $header.Length, $aes.IV.Length)
    [Array]::Copy($cipherBytes, 0, $payload, $header.Length + $aes.IV.Length, $cipherBytes.Length)
    return $payload
  }
  finally {
    $aes.Dispose()
  }
}

function Unprotect-GamData {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [byte[]]$CipherBytes,

    [Parameter(Mandatory)]
    [byte[]]$AesKey
  )

  $header = [System.Text.Encoding]::ASCII.GetBytes('GAM7ENC1')
  $hasHeader = $CipherBytes.Length -gt 24

  if ($hasHeader) {
    for ($i = 0; $i -lt $header.Length; $i++) {
      if ($CipherBytes[$i] -ne $header[$i]) {
        $hasHeader = $false
        break
      }
    }
  }

  if ($hasHeader) {
    $iv = [byte[]]::new(16)
    [Array]::Copy($CipherBytes, $header.Length, $iv, 0, $iv.Length)

    $cipherLength = $CipherBytes.Length - $header.Length - $iv.Length
    $actualCipher = [byte[]]::new($cipherLength)
    [Array]::Copy($CipherBytes, $header.Length + $iv.Length, $actualCipher, 0, $cipherLength)

    $aes = [System.Security.Cryptography.Aes]::Create()
    try {
      $aes.Key = $AesKey
      $aes.IV = $iv
      $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
      $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

      $decryptor = $aes.CreateDecryptor()
      try {
        return $decryptor.TransformFinalBlock($actualCipher, 0, $actualCipher.Length)
      }
      finally {
        $decryptor.Dispose()
      }
    }
    finally {
      $aes.Dispose()
    }
  }

  # Legacy format fallback (ConvertFrom-SecureString output text).
  $legacyEncodings = @(
    [System.Text.Encoding]::UTF8,
    [System.Text.Encoding]::Unicode
  )

  foreach ($encoding in $legacyEncodings) {
    $encrypted = $encoding.GetString($CipherBytes).Trim()
    if (-not $encrypted) {
      continue
    }

    try {
      $secure = ConvertTo-SecureString -String $encrypted -Key $AesKey
      $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
      try {
        $b64 = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
      }
      finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
      }

      return [Convert]::FromBase64String($b64)
    }
    catch {
      continue
    }
  }

  throw 'Unable to decrypt payload. The file format is not recognized or the key is invalid.'
}
