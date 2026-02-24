function Get-Mail {
#Requires -Version 5.1
<#
.SYNOPSIS
    Searches Gmail messages for one mailbox.
.DESCRIPTION
    Queries messages in a mailbox using Gmail search syntax and returns message metadata
    in a PowerShell-friendly object format.
.PARAMETER Email
    Mailbox email address to search.
.PARAMETER Query
    Optional Gmail search query.
    Examples: "snowflake", "from:example.com", "subject:\"invoice\" newer_than:30d"
    Default: -in:spam -in:trash
.PARAMETER MaxResults
    Maximum number of messages to return.
.EXAMPLE
    Get-Mail -Email stephen.tracy@northone.com -Query "snowflake"
.EXAMPLE
    Get-Mailbox -Email stephen.tracy@northone.com | Get-Mail -Query "from:snowflake.com" -MaxResults 200
.OUTPUTS
    PSCustomObject with Email, Query, Id, ThreadId, Date, Subject, From, To, MessageId.
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
    [string] $Query,
    [Parameter()]
    [ValidateRange(1, 1000000)]
    [int] $MaxResults = 100
)

process {
    $activity = 'Get-Mail'

    if ($Suspended) {
        Write-Warning "Skipping $Email - account is suspended"
        return
    }
    if ($Archived) {
        Write-Warning "Skipping $Email - account is archived"
        return
    }

    $effectiveQuery = if ([string]::IsNullOrWhiteSpace($Query)) { '-in:spam -in:trash' } else { $Query.Trim() }

    Write-Verbose "$activity : $Email"
    Write-Verbose "Query     : $effectiveQuery"
    Write-Verbose "Max       : $MaxResults"

    Write-Progress -Activity $activity -Status "Searching messages for $Email..." -PercentComplete 20
    $rows = @(& gam user $Email print messages query $effectiveQuery max_to_print $MaxResults 2>$null | ConvertFrom-Csv)

    Write-Progress -Activity $activity -Status "Formatting results ($($rows.Count) messages)..." -PercentComplete 90
    foreach ($row in $rows) {
        [PSCustomObject]@{
            Email     = $row.User
            Query     = $effectiveQuery
            Id        = $row.id
            ThreadId  = $row.threadId
            Date      = $row.Date
            Subject   = $row.Subject
            From      = $row.From
            To        = $row.To
            MessageId = $row.'Message-ID'
        }
    }

    Write-Progress -Activity $activity -Completed
}
}
