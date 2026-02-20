function Get-Mailbox {
#Requires -Version 5.1
<#
.SYNOPSIS
    Lists domain user mailboxes with storage and message counts.
.DESCRIPTION
    Queries Google Workspace via GAM to produce a per-user mailbox summary
    including availability status, last login, storage usage, and message count.
.OUTPUTS
    PSCustomObject with Email, Suspended, Archived, LastLogin, MailboxMB, MailboxDisplay,
    Messages, and StorageDate properties.
.EXAMPLE
    Get-Mailbox | Sort-Object Email | Format-Table -AutoSize
.EXAMPLE
    Get-Mailbox | Where-Object { -not $_.Suspended -and -not $_.Archived } | Measure-Object MailboxMB -Sum
#>
[CmdletBinding()]
param()

$activity = 'Get-Mailbox'

Write-Progress -Activity $activity -Status 'Fetching domain users...' -PercentComplete 10
$users = & gam print users fields primaryEmail,suspended,archived,lastLoginTime | ConvertFrom-Csv

Write-Progress -Activity $activity -Status 'Fetching mailbox storage report (may take ~60s)...' -PercentComplete 30
$storageRaw = & gam report users parameters accounts:gmail_used_quota_in_mb | ConvertFrom-Csv
$latestDate = ($storageRaw | Sort-Object date -Descending | Select-Object -First 1).date
$storageDay = @($storageRaw | Where-Object { $_.date -eq $latestDate })

$mbLookup = @{}
foreach ($r in $storageDay) {
    $mbLookup[$r.email] = [double]$r.'accounts:gmail_used_quota_in_mb'
}

Write-Progress -Activity $activity -Status "Fetching Gmail profiles ($($users.Count) mailboxes)..." -PercentComplete 70
$profileRaw = & gam all users print gmailprofile | ConvertFrom-Csv

$msgLookup = @{}
foreach ($r in $profileRaw) {
    $msgLookup[$r.emailAddress] = [int]$r.messagesTotal
}

Write-Progress -Activity $activity -Status 'Building results...' -PercentComplete 95
foreach ($user in $users) {
    $mb = $mbLookup[$user.primaryEmail]
    [PSCustomObject]@{
        Email          = $user.primaryEmail
        Suspended      = $user.suspended -eq 'True'
        Archived       = $user.archived  -eq 'True'
        LastLogin      = if ($user.lastLoginTime -eq 'Never' -or
                             [string]::IsNullOrEmpty($user.lastLoginTime)) {
                             'Never'
                         } else {
                             ([datetime]$user.lastLoginTime).ToString('yyyy-MM-dd')
                         }
        MailboxMB      = $mb
        MailboxDisplay = if     ($mb -gt 1024) { '{0:N1} GB' -f ($mb / 1024) }
                         elseif ($mb -gt 0)    { '{0:N0} MB' -f $mb }
                         else                  { '-' }
        Messages       = $msgLookup[$user.primaryEmail]
        StorageDate    = $latestDate
    }
}

Write-Progress -Activity $activity -Completed
}
