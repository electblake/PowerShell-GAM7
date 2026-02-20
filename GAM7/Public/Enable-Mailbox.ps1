function Enable-Mailbox {
<#
.SYNOPSIS
    Enables a Google Workspace user account.
.DESCRIPTION
    Unsuspends the user account and moves it to the '/Active Staff' organizational unit.
    Verifies that the mailbox is properly set up and warns if not.
.PARAMETER Email
    The email address of the user to enable.
.EXAMPLE
    Enable-Mailbox -Email user@domain.com
.EXAMPLE
    Get-Mailbox | Where-Object Suspended | Enable-Mailbox
.OUTPUTS
    PSCustomObject with Email, Unsuspended status, OUMoved status, and Mailbox status.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
  [string] $Email
)

process {
  $activity = 'Enable-Mailbox'
  Write-Host "$activity : $Email" -ForegroundColor Cyan

  Write-Progress -Activity $activity -Status 'Fetching user info...' -PercentComplete 20
  $user = & gam info user $Email formatjson | ConvertFrom-Json

  $unsuspended = $false
  if ($user.suspended) {
    Write-Progress -Activity $activity -Status 'Unsuspending account...' -PercentComplete 55
    & gam update user $Email suspended off | Out-Null
    $unsuspended = $true
  }

  $ouMoved = $false
  if (-not $user.orgUnitPath.StartsWith('/Active Staff')) {
    Write-Progress -Activity $activity -Status 'Moving to Active Staff OU...' -PercentComplete 80
    & gam update user $Email orgUnitPath '/Active Staff' | Out-Null
    $ouMoved = $true
  }

  Write-Progress -Activity $activity -Completed

  if (-not $user.isMailboxSetup) {
    Write-Warning "Mailbox for $Email is not set up."
  }

  [PSCustomObject]@{
    Email       = $Email
    Unsuspended = if ($unsuspended) { 'Yes' } else { 'Already active' }
    OUMoved     = if ($ouMoved)     { "Yes (-> /Active Staff)" } else { 'Already in Active Staff' }
    Mailbox     = if ($user.isMailboxSetup) { 'Set up' } else { 'NOT SET UP' }
  } | Format-List
}
}
