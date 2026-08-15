<#
    .SYNOPSIS
        Get PPAC RBAC role assignments.

    .DESCRIPTION
        Gets PPAC RBAC role assignments at tenant, environment group, and environment scopes.

    .PARAMETER ScopeType
        The scope type to return. Specify All, Tenant, EnvironmentGroup, or Environment.

    .PARAMETER ScopeIdentifier
        The name or id of the scope to return. Wildcards (*) are supported. For environment groups, specify the environment group id.

    .PARAMETER AsExcelOutput
        Instructs the command to output the results to an Excel file instead of the console.

    .EXAMPLE
        PS C:\> Get-PpacRbacRoleAssignment -Scope Environment -ScopeIdentifier "*Production*"

        Gets role assignments for environments with names containing "Production".

    .EXAMPLE
        PS C:\> Get-PpacRbacRoleAssignment -Scope EnvironmentGroup

        Gets role assignments for all environment groups.

    .NOTES
        Author: Florian Hopfner (@FH-Inway)

        Based on:
        https://learn.microsoft.com/en-us/rest/api/power-platform/authorization/role-based-access-control/list-role-assignments
        https://learn.microsoft.com/en-us/rest/api/power-platform/authorization/role-based-access-control/list-environment-group-role-assignments
        https://learn.microsoft.com/en-us/rest/api/power-platform/authorization/role-based-access-control/list-environment-role-assignments

#>
function Get-PpacRbacRoleAssignment {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
    param (
        [ValidateSet("All", "Tenant", "EnvironmentGroup", "Environment")]
        [string] $ScopeType = "All",

        [Alias('EnvironmentGroupId', 'EnvironmentGroupName', 'EnvironmentId', 'EnvironmentName')]
        [string] $ScopeIdentifier = "*",

        [switch] $AsExcelOutput
    )

    begin {
        $token = Get-PSFConfigValue -FullName "d365bap.tools.internal.ppac.rbac.token"

        if ($null -eq $token) {
            Write-PSFMessage -Level Warning -Message "No PPAC RBAC authentication token found. Falling back to the Azure access token for <c='em'>https://api.powerplatform.com/</c>."
            Write-PSFMessage -Level Important -Message "If you want to use the PPAC RBAC cmdlets with application id impersonation, please run <c='em'>Set-PpacRbacContext</c> first to authenticate and obtain a token."
            $secureTokenPowerApi = (Get-AzAccessToken -ResourceUrl "https://api.powerplatform.com/" -AsSecureString).Token
            $tokenPowerApiValue = ConvertFrom-SecureString -AsPlainText -SecureString $secureTokenPowerApi
            $token = "Bearer $tokenPowerApiValue"
        }

        $headersPowerApi = @{ 'Content-Type' = 'application/json' }
        $headersPowerApi.Add('Authorization', $token)

        $tenantId = (Get-AzContext).Tenant.Id
        $pathMisc = Get-PSFConfigValue -FullName "d365bap.tools.internal.misc.path"
        $rbacRoles = Get-Content `
            -Path "$pathMisc\Ppac.Rbac.Roles.json" `
            -Raw | ConvertFrom-Json

        $scopeTargets = @()

        if ($ScopeType -in "All", "Tenant") {
            $scopeTargets += [PSCustomObject]@{
                Type = "Tenant"
                Id   = $tenantId
                Name = $tenantId
            }
        }

        if ($ScopeType -in "All", "EnvironmentGroup") {
            $environmentGroupId = [guid]::Empty

            if ([guid]::TryParse($ScopeIdentifier, [ref] $environmentGroupId)) {
                $scopeTargets += [PSCustomObject]@{
                    Type = "EnvironmentGroup"
                    Id   = $environmentGroupId.ToString()
                    Name = $environmentGroupId.ToString()
                }
            }
            else {
                Write-PSFMessage -Level Warning -Message "Environment group names are not yet available. Specify a valid environment group id with <c='em'>-Scope EnvironmentGroup -ScopeIdentifier [id]</c>."
            }
            Write-PSFMessage -Level Important -Message "Role assignments for multiple environment groups are not yet supported. Specify a single environment group id with <c='em'>-Scope EnvironmentGroup -ScopeIdentifier [id]</c>."
        }

        if ($ScopeType -in "All", "Environment") {
            Get-BapEnvironment | Where-Object {
                ($_.PpacEnvName -like $ScopeIdentifier) -or ($_.PpacEnvId -like $ScopeIdentifier)
            } | ForEach-Object {
                $scopeTargets += [PSCustomObject]@{
                    Type = "Environment"
                    Id   = $_.PpacEnvId
                    Name = $_.PpacEnvName
                }
            }
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        $resCol = foreach ($scopeTarget in $scopeTargets) {
            $roleAssignmentUri = switch ($scopeTarget.Type) {
                "Tenant" {
                    "https://api.powerplatform.com/authorization/roleAssignments?api-version=2024-10-01"
                }
                "EnvironmentGroup" {
                    "https://api.powerplatform.com/authorization/environmentGroups/$($scopeTarget.Id)/roleAssignments?api-version=2024-10-01"
                }
                "Environment" {
                    "https://api.powerplatform.com/authorization/environments/$($scopeTarget.Id)/roleAssignments?api-version=2024-10-01"
                }
            }

            $resColRaw = Invoke-RestMethod `
                -Method Get `
                -Uri $roleAssignmentUri `
                -Headers $headersPowerApi 4> $null | `
                Select-Object -ExpandProperty value

            foreach ($assignment in $resColRaw) {
                $role = $rbacRoles | `
                    Where-Object { $_.roleDefinitionId -eq $assignment.roleDefinitionId } | `
                    Select-Object -First 1

                $roleAssignment = $assignment | Select-PSFObject -TypeName "D365Bap.Tools.PpacRbacRoleAssignment.Full" `
                    -ExcludeProperty "@odata.etag" `
                    -Property "roleAssignmentId as RoleAssignmentId", 
                    "scope as Scope",
                    @{Name = "ScopeType"; Expression = { $scopeTarget.Type } },
                    @{Name = "ScopeId"; Expression = { $scopeTarget.Id } },
                    @{Name = "ScopeName"; Expression = { $scopeTarget.Name } },
                    "principalType as PrincipalType",
                    "principalObjectId as PrincipalObjectId",
                    "roleDefinitionId as RoleId",
                    @{Name = "Role"; Expression = { $role.roleDefinitionName } },
                    "createdByPrincipalType as CreatedByPrincipalType",
                    "createdByPrincipalObjectId as CreatedByPrincipalObjectId",
                    "createdOn as CreatedTime",
                    "expiresOn as ExpirationTime"

                $roleAssignment.PSObject.TypeNames.Add("D365Bap.Tools.PpacRbacRoleAssignment")
                $roleAssignment
            }
        }

        if ($AsExcelOutput) {
            $resCol | Export-Excel -WorksheetName "Get-PpacRbacRoleAssignment"
            return
        }

        $resCol
    }

    end {

    }
}