<#
.SYNOPSIS
  Generate a mailbox usage report for active users.
.DESCRIPTION
  Lists active, non-archived users and exports summary data to CSV.
#>

Import-Module GAM7 -Force

$reportPath = Join-Path $PWD 'mailbox-report.csv'

Get-Mailbox |
  Where-Object { -not $_.Suspended -and -not $_.Archived } |
  Sort-Object MailboxMB -Descending |
  Export-Csv -Path $reportPath -NoTypeInformation

Write-Output "Report written to: $reportPath"
