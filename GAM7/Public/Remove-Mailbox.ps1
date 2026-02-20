function Remove-Mailbox {
<#
.SYNOPSIS
    Deletes a Google Workspace user account.
.DESCRIPTION
    Deletes the specified user account from Google Workspace. The account can be
    recovered for 20 days after deletion using GAM restore commands.
.PARAMETER Email
    The email address of the user to delete.
.EXAMPLE
    Remove-Mailbox -Email user@domain.com
.EXAMPLE
    Get-Mailbox | Where-Object Suspended | Remove-Mailbox
.OUTPUTS
    PSCustomObject with Email, OrgUnit, and Deleted status.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
  [string] $Email
)

process {
  $activity = 'Remove-Mailbox'
  Write-Host "$activity : $Email" -ForegroundColor Cyan

  Write-Progress -Activity $activity -Status 'Fetching user info...' -PercentComplete 20
  $user = & gam info user $Email formatjson | ConvertFrom-Json

  Write-Progress -Activity $activity -Status 'Deleting account...' -PercentComplete 60
  & gam delete user $Email | Out-Null

  Write-Progress -Activity $activity -Completed

  [PSCustomObject]@{
    Email   = $Email
    OrgUnit = $user.orgUnitPath
    Deleted = 'Yes (recoverable for 20 days)'
  } | Format-List
}
}
