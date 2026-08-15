<#
    .SYNOPSIS
        Remove PPAC RBAC role assignments.

    .DESCRIPTION
        Removes one or more PPAC RBAC role assignments by role assignment id.

    .PARAMETER RoleAssignmentId
        The id of the PPAC RBAC role assignment to remove.

    .PARAMETER Scope
        The scope of the PPAC RBAC role assignment. This parameter accepts the Scope property emitted by Get-PpacRbacRoleAssignment through the pipeline.

    .EXAMPLE
        PS C:\> Remove-PpacRbacRoleAssignment -RoleAssignmentId "016fff35-98b4-44bd-9519-fcfe9c0fa3b2"

        Removes the specified PPAC RBAC role assignment.

    .EXAMPLE
        PS C:\> Get-PpacRbacRoleAssignment -ScopeType Environment | Remove-PpacRbacRoleAssignment

        Removes the returned environment-scoped PPAC RBAC role assignments.

    .NOTES
        Author: Florian Hopfner (@FH-Inway)

        Based on:
        https://learn.microsoft.com/en-us/rest/api/power-platform/authorization/role-based-access-control/delete-role-assignment
        https://learn.microsoft.com/en-us/rest/api/power-platform/authorization/role-based-access-control/delete-environment-group-role-assignment
        https://learn.microsoft.com/en-us/rest/api/power-platform/authorization/role-based-access-control/delete-environment-role-assignment
#>
function Remove-PpacRbacRoleAssignment {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [guid[]] $RoleAssignmentId,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string] $Scope
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

        $pathMisc = Get-PSFConfigValue -FullName "d365bap.tools.internal.misc.path"
        $rbacRoles = Get-Content `
            -Path "$pathMisc\Ppac.Rbac.Roles.json" `
            -Raw | ConvertFrom-Json

        $failedRoleAssignmentIds = @()
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        foreach ($assignmentId in $RoleAssignmentId) {
            $roleAssignmentUri = "https://api.powerplatform.com/authorization/roleAssignments/${assignmentId}?api-version=2024-10-01"

            if ($Scope -match "/tenants/[^/]+/environmentgroups/([^/]+)$") {
                $environmentGroupId = $Matches[1]
                $roleAssignmentUri = "https://api.powerplatform.com/authorization/environmentGroups/$environmentGroupId/roleAssignments/${assignmentId}?api-version=2024-10-01"
            }
            elseif ($Scope -match "/tenants/[^/]+/environments/([^/]+)$") {
                $environmentId = $Matches[1]
                $roleAssignmentUri = "https://api.powerplatform.com/authorization/environments/$environmentId/roleAssignments/${assignmentId}?api-version=2024-10-01"
            }

            $statusCode = $null
            $removedAssignment = Invoke-RestMethod `
                -Method Delete `
                -Uri $roleAssignmentUri `
                -Headers $headersPowerApi `
                -SkipHttpErrorCheck `
                -StatusCodeVariable statusCode 4> $null

            if ($null -eq $removedAssignment) {
                $removedAssignment = [PSCustomObject]@{
                    roleAssignmentId = $assignmentId
                    scope            = $Scope
                }
            }

            $wasRemoved = $statusCode -like "2*"
            if (-not $wasRemoved) {
                $failedRoleAssignmentIds += $assignmentId
            }

            $role = $rbacRoles | `
                Where-Object { $_.roleDefinitionId -eq $removedAssignment.roleDefinitionId } | `
                Select-Object -First 1

            $removalResult = $removedAssignment | Select-PSFObject -TypeName "D365Bap.Tools.PpacRbacRoleAssignment.Removal" `
                -ExcludeProperty "@odata.context", "@odata.etag" `
                -Property "roleAssignmentId as RoleAssignmentId",
                @{Name = "Removed"; Expression = { $wasRemoved } },
                "scope as Scope",
                "principalType as PrincipalType",
                "principalObjectId as PrincipalObjectId",
                @{Name = "Role"; Expression = { $role.roleDefinitionName } }

            $removalResult.PSObject.TypeNames.Add("D365Bap.Tools.PpacRbacRoleAssignment")
            $removalResult
        }
    }

    end {
        if ($failedRoleAssignmentIds.Count -gt 0) {
            Write-PSFMessage -Level Warning -Message "$($failedRoleAssignmentIds.Count) PPAC RBAC role assignment(s) could not be removed. Failed role assignment ids: <c='em'>$($failedRoleAssignmentIds -join ', ')</c>."
        }
    }
}