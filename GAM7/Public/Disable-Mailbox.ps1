function Disable-Mailbox {
<#
.SYNOPSIS
    Disables a Google Workspace user account.
.DESCRIPTION
    Suspends the user account and moves it to the '/Disabled Accounts' organizational unit.
    The account remains in the system but the user cannot access their mailbox or services.
.PARAMETER Email
    The email address of the user to disable.
.EXAMPLE
    Disable-Mailbox -Email user@domain.com
.EXAMPLE
    Get-Mailbox | Where-Object { $_.LastLogin -eq 'Never' } | Disable-Mailbox
.OUTPUTS
    PSCustomObject with Email, Suspended status, and OUMoved status.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
  [string] $Email
)

process {
  $activity = 'Disable-Mailbox'
  Write-Verbose "$activity : $Email"

  Write-Progress -Activity $activity -Status 'Fetching user info...' -PercentComplete 20
  $user = & gam info user $Email formatjson | ConvertFrom-Json

  $suspended = $false
  if (-not $user.suspended) {
    Write-Progress -Activity $activity -Status 'Suspending account...' -PercentComplete 55
    & gam update user $Email suspended on | Out-Null
    $suspended = $true
  }

  $ouMoved = $false
  if (-not $user.orgUnitPath.StartsWith('/Disabled Accounts')) {
    Write-Progress -Activity $activity -Status 'Moving to Disabled Accounts OU...' -PercentComplete 80
    & gam update user $Email orgUnitPath '/Disabled Accounts' | Out-Null
    $ouMoved = $true
  }

  Write-Progress -Activity $activity -Completed

  [PSCustomObject]@{
    Email     = $Email
    Suspended = if ($suspended) { 'Yes' } else { 'Already suspended' }
    OUMoved   = if ($ouMoved) { 'Yes (-> /Disabled Accounts)' } else { 'Already in Disabled Accounts' }
  } | Format-List
}}
