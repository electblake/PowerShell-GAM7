function Debug-GAM {
  <#
.SYNOPSIS
    Runs diagnostic checks for GAM7 Google Workspace access.
.DESCRIPTION
    Executes a series of GAM commands to verify configuration, authentication,
    and access to Google Workspace resources. Useful for troubleshooting
    connection and permission issues.
.EXAMPLE
    Debug-GAM
.OUTPUTS
    Console output showing results of each diagnostic check.
#>
  [CmdletBinding()]
  param()

  $steps = [ordered]@{
    'gam config'                                       = { gam config }
    'gam config verify variables oauth2service_json'   = { gam config verify variables oauth2service_json }
    'gam info currentprojectid'                        = { gam info currentprojectid }
    'gam info domain'                                  = { gam info domain }
    'gam user blake@northone.com check serviceaccount' = { gam user blake@northone.com check serviceaccount }
    'gam info customer'                                = { gam info customer }
    'gam print adminroles'                             = { gam print adminroles }
    "gam info adminrole 'Super Delegate'"              = { gam info adminrole 'Super Delegate' }
    'gam print admin'                                  = { gam print admin }
    'gam print orgs'                                   = { gam print orgs }
    'gam print domains'                                = { gam print domains }
    'gam print domainaliases'                          = { gam print domainaliases }
  }

  $i = 0
  foreach ($label in $steps.Keys) {
    Write-Progress -Activity 'Debug-WorkspaceAccess' -Status $label -PercentComplete ($i / $steps.Count * 100)
    "`n=== $label ==="
    & $steps[$label]
    $i++
  }
  Write-Progress -Activity 'Debug-WorkspaceAccess' -Completed
}
