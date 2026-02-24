function Get-Mailbox {
#Requires -Version 5.1
<#
.SYNOPSIS
    Lists domain user mailboxes with storage and message counts.
.DESCRIPTION
    Queries Google Workspace via GAM to produce a per-user mailbox summary
    including availability status, last login, storage usage, and message count.
.PARAMETER Email
    Optional mailbox email address (or addresses). When provided, only those mailboxes
    are returned.
.OUTPUTS
    PSCustomObject with Email, Suspended, Archived, LastLogin, MailboxMB, MailboxDisplay,
    Messages, and StorageDate properties.
.EXAMPLE
    Get-Mailbox | Sort-Object Email | Format-Table -AutoSize
.EXAMPLE
    Get-Mailbox | Where-Object { -not $_.Suspended -and -not $_.Archived } | Measure-Object MailboxMB -Sum
.EXAMPLE
    Get-Mailbox -Email stephen.tracy@northone.com
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string[]] $Email
)

$activity = 'Get-Mailbox'
$requestedEmails = @($Email | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim().ToLowerInvariant() } | Sort-Object -Unique)
$filteringByEmail = $requestedEmails.Count -gt 0

$newMailboxRecord = {
    param(
        [object] $User,
        [object] $MailboxMB,
        [object] $Messages,
        [string] $StorageDate
    )

    $mb = if ($null -ne $MailboxMB -and $MailboxMB -ne '') { [double]$MailboxMB } else { 0 }
    [PSCustomObject]@{
        Email          = $User.primaryEmail
        Suspended      = $User.suspended -eq 'True'
        Archived       = $User.archived  -eq 'True'
        LastLogin      = if ($User.lastLoginTime -eq 'Never' -or
                             [string]::IsNullOrEmpty($User.lastLoginTime)) {
                             'Never'
                         } else {
                             ([datetime]$User.lastLoginTime).ToString('yyyy-MM-dd')
                         }
        MailboxMB      = $mb
        MailboxDisplay = if     ($mb -gt 1024) { '{0:N1} GB' -f ($mb / 1024) }
                         elseif ($mb -gt 0)    { '{0:N0} MB' -f $mb }
                         else                  { '-' }
        Messages       = $Messages
        StorageDate    = if ([string]::IsNullOrWhiteSpace($StorageDate)) { '-' } else { $StorageDate }
    }
}

if ($filteringByEmail) {
    Write-Progress -Activity $activity -Status "Fetching selected users ($($requestedEmails.Count))..." -PercentComplete 10
    $users = @()
    for ($i = 0; $i -lt $requestedEmails.Count; $i++) {
        $target = $requestedEmails[$i]
        $pct = 10 + [int](15 * (($i + 1) / [Math]::Max($requestedEmails.Count, 1)))
        Write-Progress -Activity $activity -Status "Fetching selected users ($($i + 1)/$($requestedEmails.Count))..." -PercentComplete $pct

        $rows = @(& gam print users query "email:$target" fields primaryEmail,suspended,archived,lastLoginTime 2>$null | ConvertFrom-Csv)
        if ($rows.Count -eq 0) {
            Write-Warning "User not found: $target"
            continue
        }

        $match = @($rows | Where-Object { $_.primaryEmail -ieq $target })
        if ($match.Count -gt 0) {
            $users += $match[0]
        } else {
            $users += $rows[0]
        }
    }
} else {
    Write-Progress -Activity $activity -Status 'Fetching domain users...' -PercentComplete 10
    $users = @(& gam print users fields primaryEmail,suspended,archived,lastLoginTime 2>$null | ConvertFrom-Csv)
}

if ($users.Count -eq 0) {
    Write-Warning 'No matching users found.'
    Write-Progress -Activity $activity -Completed
    return
}

if ($filteringByEmail) {
    Write-Progress -Activity $activity -Status "Fetching storage reports for $($users.Count) mailbox(es)..." -PercentComplete 30
    $mbLookup = @{}
    $storageDateLookup = @{}
    for ($i = 0; $i -lt $users.Count; $i++) {
        $user = $users[$i]
        $pct = 30 + [int](30 * (($i + 1) / [Math]::Max($users.Count, 1)))
        Write-Progress -Activity $activity -Status "Fetching storage reports ($($i + 1)/$($users.Count))..." -PercentComplete $pct

        $rows = @(& gam report users user $user.primaryEmail parameters accounts:gmail_used_quota_in_mb 2>$null | ConvertFrom-Csv)
        if ($rows.Count -eq 0) {
            continue
        }

        $latest = $rows | Sort-Object date -Descending | Select-Object -First 1
        if ($null -ne $latest) {
            $mbLookup[$user.primaryEmail] = [double]$latest.'accounts:gmail_used_quota_in_mb'
            $storageDateLookup[$user.primaryEmail] = [string]$latest.date
        }
    }

    Write-Progress -Activity $activity -Status "Fetching Gmail profiles for $($users.Count) mailbox(es)..." -PercentComplete 60
    $msgLookup = @{}
    for ($i = 0; $i -lt $users.Count; $i++) {
        $user = $users[$i]
        $pct = 60 + [int](30 * (($i + 1) / [Math]::Max($users.Count, 1)))
        Write-Progress -Activity $activity -Status "Fetching Gmail profiles ($($i + 1)/$($users.Count))..." -PercentComplete $pct
        $profileRows = @(& gam user $user.primaryEmail print gmailprofile 2>$null | ConvertFrom-Csv)
        if ($profileRows.Count -gt 0) {
            $msgLookup[$user.primaryEmail] = [int]$profileRows[0].messagesTotal
        }
    }

    Write-Progress -Activity $activity -Status 'Building results...' -PercentComplete 95
    for ($i = 0; $i -lt $users.Count; $i++) {
        $user = $users[$i]
        if ((($i + 1) % 200 -eq 0) -or ($i + 1 -eq $users.Count)) {
            $percent = 95 + [int](4 * (($i + 1) / [Math]::Max($users.Count, 1)))
            Write-Progress -Activity $activity -Status "Building results ($($i + 1)/$($users.Count))..." -PercentComplete $percent
        }
        & $newMailboxRecord -User $user -MailboxMB $mbLookup[$user.primaryEmail] -Messages $msgLookup[$user.primaryEmail] -StorageDate $storageDateLookup[$user.primaryEmail]
    }
    Write-Progress -Activity $activity -Completed
    return
}

# All-mailbox mode
Write-Progress -Activity $activity -Status 'Fetching mailbox storage report (may take ~60s)...' -PercentComplete 30
$storageRaw = & gam report users parameters accounts:gmail_used_quota_in_mb 2>$null | ConvertFrom-Csv
$latestDate = ($storageRaw | Sort-Object date -Descending | Select-Object -First 1).date
$storageDay = @($storageRaw | Where-Object { $_.date -eq $latestDate })

$mbLookup = @{}
foreach ($r in $storageDay) {
    $mbLookup[$r.email] = [double]$r.'accounts:gmail_used_quota_in_mb'
}

Write-Progress -Activity $activity -Status "Fetching Gmail profiles for $($users.Count) mailboxes (batched via GAM)..." -PercentComplete 70
$profileStart = 70
$profileEnd = 90
$profileRaw = @()
$stderrLines = @()
$currentProfiles = 0
$totalProfiles = [Math]::Max($users.Count, 1)

$profileStdOut = Join-Path ([System.IO.Path]::GetTempPath()) ("gam-gmailprofile-{0}.csv" -f [guid]::NewGuid())
$profileStdErr = Join-Path ([System.IO.Path]::GetTempPath()) ("gam-gmailprofile-{0}.log" -f [guid]::NewGuid())

try {
    $gamPath = (Get-Command gam -ErrorAction Stop).Source
    $proc = Start-Process -FilePath $gamPath `
        -ArgumentList @('all', 'users', 'print', 'gmailprofile') `
        -PassThru `
        -RedirectStandardOutput $profileStdOut `
        -RedirectStandardError $profileStdErr

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while (-not $proc.HasExited) {
        $tail = @(Get-Content -Path $profileStdErr -Tail 25 -ErrorAction SilentlyContinue)
        $line = $tail |
            Select-String -Pattern '^Getting Gmail Profile for .+\((\d+)\/(\d+)\)$' |
            Select-Object -Last 1

        if ($line) {
            $m = [regex]::Match($line.Line, '\((\d+)\/(\d+)\)$')
            if ($m.Success) {
                $currentProfiles = [int]$m.Groups[1].Value
                $totalProfiles = [Math]::Max([int]$m.Groups[2].Value, 1)
            }
        }

        $percent = $profileStart + [int](($profileEnd - $profileStart) * ($currentProfiles / [double]$totalProfiles))
        $elapsed = '{0:mm\:ss}' -f $sw.Elapsed
        Write-Progress -Activity $activity `
            -Status "Fetching Gmail profiles for $($users.Count) mailboxes (batched via GAM)... elapsed $elapsed" `
            -PercentComplete $percent

        Start-Sleep -Milliseconds 300
        $proc.Refresh()
    }

    $stderrLines = @(Get-Content -Path $profileStdErr -ErrorAction SilentlyContinue)
    foreach ($line in $stderrLines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^User:\s+.+,\s+Gmail Service/App not enabled') {
            Write-Verbose $trimmed
        }
    }

    $stdoutLines = @(Get-Content -Path $profileStdOut -ErrorAction SilentlyContinue)
    if ($stdoutLines.Count -gt 0) {
        $profileRaw = $stdoutLines | ConvertFrom-Csv
    }

    if (($proc.ExitCode -ne 0) -and ($profileRaw.Count -eq 0)) {
        Write-Warning "GAM returned exit code $($proc.ExitCode) while fetching Gmail profiles."
    }
} finally {
    Remove-Item -Path $profileStdOut, $profileStdErr -Force -ErrorAction SilentlyContinue
}

$currentProfiles = if ($currentProfiles -gt 0) { $currentProfiles } else { $profileRaw.Count }
Write-Progress -Activity $activity `
    -Status "Fetched Gmail profiles for $($users.Count) mailboxes (received $($profileRaw.Count))..." `
    -PercentComplete $profileEnd
Write-Verbose "Fetched Gmail profiles for $($profileRaw.Count) of $($users.Count) users."

$msgLookup = @{}
for ($i = 0; $i -lt $profileRaw.Count; $i++) {
    $r = $profileRaw[$i]
    if ((($i + 1) % 100 -eq 0) -or ($i + 1 -eq $profileRaw.Count)) {
        $percent = $profileEnd + [int](5 * (($i + 1) / [Math]::Max($profileRaw.Count, 1)))
        Write-Progress -Activity $activity -Status "Indexing message counts ($($i + 1)/$($profileRaw.Count))..." -PercentComplete $percent
    }
    $msgLookup[$r.emailAddress] = [int]$r.messagesTotal
}

Write-Progress -Activity $activity -Status 'Building results...' -PercentComplete 95
for ($j = 0; $j -lt $users.Count; $j++) {
    $user = $users[$j]
    if ((($j + 1) % 200 -eq 0) -or ($j + 1 -eq $users.Count)) {
        $percent = 95 + [int](4 * (($j + 1) / [Math]::Max($users.Count, 1)))
        Write-Progress -Activity $activity -Status "Building results ($($j + 1)/$($users.Count))..." -PercentComplete $percent
    }
    & $newMailboxRecord -User $user -MailboxMB $mbLookup[$user.primaryEmail] -Messages $msgLookup[$user.primaryEmail] -StorageDate $latestDate
}

Write-Progress -Activity $activity -Completed
}
