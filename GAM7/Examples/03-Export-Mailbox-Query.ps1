<#
.SYNOPSIS
  Export mailbox messages matching a Gmail search query.
.DESCRIPTION
  Exports targeted messages for each active mailbox and writes .eml files under ./exports.
#>

Import-Module GAM7 -Force

$query = 'from:example.com newer_than:180d'

Get-Mailbox |
  Where-Object { -not $_.Suspended -and -not $_.Archived } |
  Export-Mailbox -Query $query -Verbose
