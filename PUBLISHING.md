# Publish GAM7 to PowerShell Gallery (Official Single Flow)

This project uses one publishing flow only: the Microsoft-recommended PowerShellGet flow.

## 1) Prepare release metadata

Update these before publishing:

- `GAM7/GAM7.psd1`: `ModuleVersion` and `PrivateData.PSData.ReleaseNotes`
- `CHANGELOG.md`

## 2) Run required quality checks

```powershell
Test-ModuleManifest -Path ./GAM7/GAM7.psd1
Invoke-ScriptAnalyzer -Path ./GAM7 -Recurse -Severity Warning
Invoke-Pester -Path ./tests -CI
```

## 3) Test publish to a local repository (required)

```powershell
$repoName = 'GAM7Local'
$repoPath = Join-Path $PWD '.local-gallery'

New-Item -ItemType Directory -Path $repoPath -Force | Out-Null

if (Get-PSRepository -Name $repoName -ErrorAction SilentlyContinue) {
  Unregister-PSRepository -Name $repoName
}

Register-PSRepository -Name $repoName `
  -SourceLocation $repoPath `
  -PublishLocation $repoPath `
  -InstallationPolicy Trusted

Publish-Module -Path ./GAM7 -Repository $repoName -NuGetApiKey 'local-test-key' -Verbose
Install-Module -Name GAM7 -Repository $repoName -Scope CurrentUser -Force
```

## 4) Publish to PowerShell Gallery

```powershell
$apiKey = '<PSGallery API key>'
Publish-Module -Path ./GAM7 -NuGetApiKey $apiKey -Verbose
```

## 5) Post-publish owner responsibility

Monitor the PowerShell Gallery owner contact channel and respond to user feedback.

## References (Microsoft Learn)

- Publishing guidelines and recommended workflow:
  https://learn.microsoft.com/powershell/gallery/concepts/publishing-guidelines
- Create and publish a package:
  https://learn.microsoft.com/powershell/gallery/how-to/publishing-packages/publishing-a-package
- Local repository setup with `Register-PSRepository`:
  https://learn.microsoft.com/powershell/module/powershellget/register-psrepository
