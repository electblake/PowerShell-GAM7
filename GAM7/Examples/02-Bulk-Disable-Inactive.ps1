<#
.SYNOPSIS
  Disable inactive mailboxes in bulk.
.DESCRIPTION
  Finds users who have never logged in and disables them.
  Review the filter carefully before running in production.
#>

Import-Module GAM7 -Force

Get-Mailbox |
  Where-Object { $_.LastLogin -eq 'Never' -and -not $_.Suspended } |
  Disable-Mailbox -Verbose
