# GAM7 Module - Cohesive Patterns

This document describes the cohesive patterns used throughout the GAM7 module to ensure consistency and maintainability.

## Core Principles

- **Cohesion over coupling**: Functions follow aligned patterns without creating dependencies
- **Pipeline-friendly**: Support `ValueFromPipelineByPropertyName` where applicable
- **Consistent reporting**: Uniform logging, progress, and output styles
- **User-friendly**: Clear, informative feedback at each step

## Function Structure

### Pipeline Support

Functions that process items use:
```powershell
[CmdletBinding()]
param(
  [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
  [string] $Email  # or other primary identifier
)

process {
  # Function logic here
}
```

### Activity Pattern

Every function establishes an activity name at the start:
```powershell
$activity = 'FunctionName'
```

## Logging & Reporting Patterns

### 1. User-Facing Header (Cyan)
Use for the primary action being performed:
```powershell
Write-Host "$activity : $Email" -ForegroundColor Cyan
```

Multi-parameter variant:
```powershell
Write-Host "$activity : $Source -> $Destination" -ForegroundColor Cyan
```

### 2. Progress Indicators
Track major steps with progress bars:
```powershell
Write-Progress -Activity $activity -Status 'Fetching user info...' -PercentComplete 20
Write-Progress -Activity $activity -Status 'Suspending account...' -PercentComplete 55
Write-Progress -Activity $activity -Status 'Moving to OU...' -PercentComplete 80
Write-Progress -Activity $activity -Completed
```

**Guidelines:**
- Use descriptive status messages with ellipsis for ongoing actions
- Distribute percentages logically across major steps
- Always complete progress when done

### 3. Warnings
Use `Write-Warning` for non-fatal issues:
```powershell
Write-Warning "Mailbox for $Email is not set up."
Write-Warning "Skipping $Email — account is suspended"
```

**Don't use:**
- `Write-Error` with `-ErrorAction Stop` pattern
- Throwing exceptions for expected conditions

### 4. Quiet External Calls
Suppress GAM output unless it's intentional progress:
```powershell
& gam update user $Email suspended on | Out-Null
```

### 5. Output Format
Return structured objects piped to `Format-List`:
```powershell
[PSCustomObject]@{
  Email       = $Email
  Unsuspended = if ($unsuspended) { 'Yes' } else { 'Already active' }
  OUMoved     = if ($ouMoved) { "Yes (-> /Active Staff)" } else { 'Already in Active Staff' }
} | Format-List
```

**Guidelines:**
- Use friendly conditional strings ('Yes' / 'Already <state>')
- Include context in messages (e.g., "-> /Active Staff")
- Use `Format-List` not `Format-Table` for detailed output

## Comment-Based Help

Every function includes:
```powershell
<#
.SYNOPSIS
    Brief one-line description.
.DESCRIPTION
    Detailed description of what the function does.
    Can span multiple lines.
.PARAMETER ParamName
    Description of the parameter.
.EXAMPLE
    FunctionName -Param value
.EXAMPLE
    Get-Mailbox | FunctionName
.OUTPUTS
    Description of what the function returns.
#>
```

## File Organization

```
GAM7/
├── GAM7.psd1              # Module manifest
├── GAM7.psm1              # Root module (loads Public functions)
├── Public/                # All exported functions
│   └── *.ps1              # One function per file
├── PREREQUISITES.md       # Requirements
└── PATTERNS.md           # This file
```

## Function Naming

Follow PowerShell approved verbs:
- `Get-*`: Retrieve information
- `New-*`: Create new resources
- `Enable-*`: Activate/turn on
- `Disable-*`: Deactivate/turn off
- `Delete-*`: Remove (NOTE: Not standard PowerShell verb, consider `Remove-*`)
- `Export-*`: Send data out
- `Import-*`: Bring data in
- `Backup-*`: Create backups
- `Restore-*`: Restore from backups
- `Invoke-*`: Execute complex operations
- `Debug-*`: Diagnostic operations

## Example: Cohesive Function Template

```powershell
function Verb-Noun {
<#
.SYNOPSIS
    Brief description.
.DESCRIPTION
    Detailed description.
.PARAMETER Name
    Parameter description.
.EXAMPLE
    Verb-Noun -Name value
.OUTPUTS
    PSCustomObject with properties.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
  [string] $Name
)

process {
  $activity = 'Verb-Noun'
  Write-Host "$activity : $Name" -ForegroundColor Cyan

  Write-Progress -Activity $activity -Status 'Step 1...' -PercentComplete 20
  # Do work
  
  Write-Progress -Activity $activity -Status 'Step 2...' -PercentComplete 60
  # Do more work
  
  Write-Progress -Activity $activity -Completed

  [PSCustomObject]@{
    Name   = $Name
    Status = 'Success'
  } | Format-List
}
}
```

## What to Avoid

❌ **Coupling**: Don't make functions call each other unless unavoidable  
❌ **Inconsistent logging**: Don't mix Write-Host, Write-Output, Write-Verbose randomly  
❌ **Silent failures**: Always provide feedback  
❌ **Write-Error for expected cases**: Use Write-Warning instead  
❌ **Format-Table**: Use Format-List for consistency  
❌ **Global state**: Functions should be stateless  

## Summary

These patterns create a cohesive, predictable experience:
- Users know what to expect from progress indicators
- Pipeline operations work consistently
- Error handling is friendly and informative
- Help documentation is complete
- Code is maintainable without tight coupling
