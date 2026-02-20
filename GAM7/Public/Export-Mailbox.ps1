function Export-Mailbox {
<#
.SYNOPSIS
    Exports Gmail messages to .eml files.
.DESCRIPTION
    Exports messages from a Google Workspace user's mailbox to individual .eml files.
    Supports filtering by search query. Automatically renames files by receipt date for
    natural sorting. Skips suspended and archived accounts.
.PARAMETER Email
    The email address of the mailbox to export.
.PARAMETER Suspended
    Whether the account is suspended (used for pipeline filtering).
.PARAMETER Archived
    Whether the account is archived (used for pipeline filtering).
.PARAMETER Query
    Optional Gmail search query to filter messages (e.g., "from:example.com" or "WorkSafeBC").
.EXAMPLE
    Export-Mailbox -Email user@domain.com
.EXAMPLE
    Export-Mailbox -Email user@domain.com -Query "WorkSafeBC"
.EXAMPLE
    Get-Mailbox | Where-Object { -not $_.Suspended } | Export-Mailbox
.OUTPUTS
    PSCustomObject with Email, Query, OutputDir, Exported count, Renamed count, and Unrenamed count.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string] $Email,
    [Parameter(ValueFromPipelineByPropertyName)]
    [bool] $Suspended,
    [Parameter(ValueFromPipelineByPropertyName)]
    [bool] $Archived,
    [Parameter()]
    [string] $Query
)

process {
    $activity     = 'Export-Mailbox'

    if ($Suspended) {
        Write-Warning "Skipping $Email — account is suspended"
        return
    }
    if ($Archived) {
        Write-Warning "Skipping $Email — account is archived"
        return
    }
    $folderSuffix = if ($Query) { $Query } else { 'all' }
    $OutDir       = "./exports/$Email+$folderSuffix"

    Write-Host "$activity : $Email" -ForegroundColor Cyan
    Write-Host "Query     : $(if ($Query) { $Query } else { '(all messages)' })" -ForegroundColor Cyan
    Write-Host "Output    : $OutDir" -ForegroundColor Cyan

    Write-Progress -Activity $activity -Status 'Creating export directory...' -PercentComplete 5
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

    Write-Progress -Activity $activity -Status 'Exporting messages via GAM...' -PercentComplete 10

    # GAM outputs per-message progress to stdout — let it flow through as the primary progress indicator
    if ($Query) {
        & gam user $Email export messages query $Query max_to_export 0 targetfolder $OutDir overwrite
    } else {
        & gam user $Email export messages matchlabel allmail max_to_export 0 targetfolder $OutDir overwrite
    }

    # Rename exported files: yyyy-MM-dd_HHmmss_Msg-{id}.eml so they sort naturally by date
    Write-Progress -Activity $activity -Status 'Renaming files by receipt date...' -PercentComplete 90

    $files   = @(Get-ChildItem -Path $OutDir -Filter '*.eml' | Where-Object { $_.Name -notmatch '^\d{4}-\d{2}-\d{2}_' })
    $total   = $files.Count
    $renamed = 0
    $skipped = 0
    $i       = 0

    foreach ($file in $files) {
        $i++
        Write-Progress -Activity $activity -Status "Renaming $($file.Name)" `
            -PercentComplete (90 + [int](9 * $i / [Math]::Max($total, 1)))

        $dateLine = Get-Content -Path $file.FullName -TotalCount 100 |
            Where-Object { $_ -match '^Date:\s' } |
            Select-Object -First 1

        if ($dateLine -match '^Date:\s*(.+)') {
            try {
                $date    = [datetime]::Parse($matches[1].Trim())
                $newName = '{0}_{1}' -f $date.ToString('yyyy-MM-dd_HHmmss'), $file.Name
                Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
                $renamed++
            } catch {
                $skipped++
            }
        } else {
            $skipped++
        }
    }

    Write-Progress -Activity $activity -Completed

    $exportedFiles = @(Get-ChildItem -Path $OutDir -Filter '*.eml')

    [PSCustomObject]@{
        Email     = $Email
        Query     = if ($Query) { $Query } else { '(all)' }
        OutputDir = $OutDir
        Exported  = $exportedFiles.Count
        Renamed   = $renamed
        Unrenamed = $skipped
    } | Format-List
}
}
