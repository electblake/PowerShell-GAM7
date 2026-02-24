function Invoke-BulkMailboxAction {
#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive mailbox management - list, select, and act on mailboxes.
.DESCRIPTION
    Loads all mailboxes via Get-Mailbox, presents them for multi-selection,
    then applies the chosen action (Enable, Disable, or Export) using the
    corresponding action functions.
.PARAMETER Query
    Optional Gmail search query for Export-Mailbox operations.
.EXAMPLE
    Invoke-BulkMailboxAction
.EXAMPLE
    Invoke-BulkMailboxAction -Query "WorkSafeBC"
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $Query
)

$activity   = 'Invoke-BulkMailboxAction'

# 1. Load mailboxes
Write-Progress -Activity $activity -Status 'Loading mailboxes...' -PercentComplete 10  
$mailboxes = Get-Mailbox
Write-Progress -Activity $activity -Completed

# 2. Select mailboxes
$selected = $mailboxes |
    Select-Object Email, Suspended, Archived, LastLogin, MailboxDisplay, Messages |
    Out-ConsoleGridView -Title 'Select mailboxes' -OutputMode Multiple
if (-not $selected) {
    Write-Warning 'No mailboxes selected.'
    return
}

Write-Verbose "Selected: $($selected.Email -join ', ')"

$actions = @(
    [PSCustomObject]@{ Action = 'Enable';  Description = 'Unsuspend and move to Active Staff'      }
    [PSCustomObject]@{ Action = 'Disable'; Description = 'Suspend and move to Disabled Accounts'   }
    [PSCustomObject]@{ Action = 'Export';  Description = 'Export messages to .eml files'           }
)

# 3 & 4. Select action - Esc returns to mailbox picker
while ($true) {
    $action = $actions | Out-ConsoleGridView -Title 'Select action  (Esc = back)' -OutputMode Single
    if (-not $action) {
        # Back to mailbox picker
        $selected = $mailboxes |
            Select-Object Email, Suspended, Archived, LastLogin, MailboxDisplay, Messages |
            Out-ConsoleGridView -Title 'Select mailboxes' -OutputMode Multiple
        if (-not $selected) {
            Write-Warning 'No mailboxes selected.'
            return
        }
        Write-Verbose "Selected: $($selected.Email -join ', ')"
        continue
    }

    switch ($action.Action) {
        'Enable'  { $selected | Enable-Mailbox }
        'Disable' { $selected | Disable-Mailbox }
        'Export'  { $selected | Export-Mailbox -Query $Query }
    }
    break
}
}
