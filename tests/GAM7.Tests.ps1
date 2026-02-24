# GAM7 Module Tests

# Requires Pester 5.x
#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
  # Import module from source
  $ModulePath = Join-Path $PSScriptRoot '..' 'GAM7' 'GAM7.psd1'
  Import-Module $ModulePath -Force
}

Describe 'GAM7 Module' {
  Context 'Module Import' {
    It 'Should import without errors' {
      { Import-Module $ModulePath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    It 'Should export 13 functions' {
      $commands = Get-Command -Module GAM7
      $commands.Count | Should -Be 13
    }

    It 'Should have valid manifest' {
      { Test-ModuleManifest -Path $ModulePath -ErrorAction Stop } | Should -Not -Throw
    }
  }

  Context 'Function Availability' {
    It 'Should export Backup-GamConfig' {
      Get-Command -Name 'Backup-GamConfig' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Debug-GAM' {
      Get-Command -Name 'Debug-GAM' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Disable-Mailbox' {
      Get-Command -Name 'Disable-Mailbox' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Enable-Mailbox' {
      Get-Command -Name 'Enable-Mailbox' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Export-GamAuthSecure' {
      Get-Command -Name 'Export-GamAuthSecure' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Export-Mailbox' {
      Get-Command -Name 'Export-Mailbox' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Get-Mail' {
      Get-Command -Name 'Get-Mail' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Get-Mailbox' {
      Get-Command -Name 'Get-Mailbox' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Import-GamAuthSecure' {
      Get-Command -Name 'Import-GamAuthSecure' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Invoke-BulkMailboxAction' {
      Get-Command -Name 'Invoke-BulkMailboxAction' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export New-GamEncryptionKey' {
      Get-Command -Name 'New-GamEncryptionKey' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Remove-Mailbox' {
      Get-Command -Name 'Remove-Mailbox' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It 'Should export Restore-GamConfig' {
      Get-Command -Name 'Restore-GamConfig' -Module GAM7 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
  }

  Context 'Help Documentation' {
    It 'All functions should have comment-based help in source files' {
      $functions = Get-Command -Module GAM7
      $publicPath = Resolve-Path (Join-Path $PSScriptRoot '..' 'GAM7' 'Public')
      
      foreach ($function in $functions) {
        $funcFile = Join-Path $publicPath "$($function.Name).ps1"
        $content = Get-Content $funcFile -Raw
        
        # Check for comment-based help markers
        $content | Should -Match '\.SYNOPSIS' -Because "Function $($function.Name) should have SYNOPSIS"
        $content | Should -Match '\.DESCRIPTION' -Because "Function $($function.Name) should have DESCRIPTION"
        $content | Should -Match '\.EXAMPLE' -Because "Function $($function.Name) should have at least one EXAMPLE"
      }
    }
  }

  Context 'Function Syntax' {
    It 'Enable-Mailbox should support pipeline input' {
      $help = Get-Help Enable-Mailbox -Full
      $emailParam = $help.parameters.parameter | Where-Object { $_.name -eq 'Email' }
      $emailParam.pipelineInput | Should -Match 'true'
    }

    It 'Disable-Mailbox should support pipeline input' {
      $help = Get-Help Disable-Mailbox -Full
      $emailParam = $help.parameters.parameter | Where-Object { $_.name -eq 'Email' }
      $emailParam.pipelineInput | Should -Match 'true'
    }

    It 'Export-Mailbox should support pipeline input' {
      $help = Get-Help Export-Mailbox -Full
      $emailParam = $help.parameters.parameter | Where-Object { $_.name -eq 'Email' }
      $emailParam.pipelineInput | Should -Match 'true'
    }

    It 'Export-Mailbox Query should support pipeline input by property name' {
      $help = Get-Help Export-Mailbox -Full
      $queryParam = $help.parameters.parameter | Where-Object { $_.name -eq 'Query' }
      $queryParam.pipelineInput | Should -Match 'ByPropertyName'
    }

    It 'Get-Mail should support pipeline input' {
      $help = Get-Help Get-Mail -Full
      $emailParam = $help.parameters.parameter | Where-Object { $_.name -eq 'Email' }
      $emailParam.pipelineInput | Should -Match 'true'
    }
  }

  Context 'Encryption Key Generation' {
    It 'New-GamEncryptionKey should create a key file in temporary location' {
      $tempDir = $TestDrive  # Use Pester's built-in TestDrive for automatic cleanup
      $tempKey = Join-Path $tempDir 'test-key.key'
      
      # Run the function 
      $result = New-GamEncryptionKey -OutputPath $tempKey
      
      # Verify the file was created and contains data
      Test-Path $tempKey | Should -Be $true
      (Get-Item $tempKey).Length | Should -BeGreaterThan 0
      
      # Cleanup is handled automatically by Pester when test completes
      # $TestDrive is removed after each Describe block
    }
  }
}

Describe 'GAM7 Module Structure' {
  Context 'File Organization' {
    It 'Should have GAM7.psd1 manifest' {
      Test-Path (Join-Path $PSScriptRoot '..' 'GAM7' 'GAM7.psd1') | Should -Be $true
    }

    It 'Should have GAM7.psm1 root module' {
      Test-Path (Join-Path $PSScriptRoot '..' 'GAM7' 'GAM7.psm1') | Should -Be $true
    }

    It 'Should have Public folder' {
      Test-Path (Join-Path $PSScriptRoot '..' 'GAM7' 'Public') | Should -Be $true
    }

    It 'Should have 13 function files in Public' {
      $publicFunctions = Get-ChildItem (Join-Path $PSScriptRoot '..' 'GAM7' 'Public') -Filter '*.ps1'
      $publicFunctions.Count | Should -Be 13
    }
  }

  Context 'Function Files' {
    It 'Each exported function should have a corresponding .ps1 file' {
      $functions = Get-Command -Module GAM7
      foreach ($func in $functions) {
        $funcPath = Join-Path $PSScriptRoot '..' 'GAM7' 'Public' "$($func.Name).ps1"
        Test-Path $funcPath | Should -Be $true -Because "Function $($func.Name) should have a file"
      }
    }
  }
}

Describe 'GAM7 Integration Prerequisites' {
  Context 'GAM Installation' {
    It 'Should have GAM command available (or skip if not installed)' {
      if (Get-Command gam -ErrorAction SilentlyContinue) {
        Get-Command gam | Should -Not -BeNullOrEmpty
      }
      else {
        Set-ItResult -Skipped -Because 'GAM is not installed'
      }
    }
  }
}
