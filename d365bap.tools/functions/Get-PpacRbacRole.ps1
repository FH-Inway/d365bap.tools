
<#
    .SYNOPSIS
        Get PPAC RBAC roles available in the tenant.
        
    .DESCRIPTION
        Gets PPAC RBAC roles available in the tenant. This command is used to retrieve the list of available PPAC RBAC roles, which can then be used for role assignments in Power Platform.
        
    .PARAMETER Role
        The name, id or description of the PPAC RBAC role to retrieve.
        
        Use wildcards (*) for partial matches. If not specified, all roles will be returned.
        
    .PARAMETER AsExcelOutput
        Instructs the command to output the results to an Excel file instead of the console.
        
    .EXAMPLE
        PS C:\> Get-PpacRbacRole -Role "Power Platform *"
        
        This command retrieves all PPAC RBAC roles with names starting with "Power Platform".
        
    .EXAMPLE
        PS C:\> Get-PpacRbacRole -Role "*admin*" -AsExcelOutput
        
        This command retrieves all PPAC RBAC roles with names or descriptions containing "admin".
        The results will be exported to an Excel file instead of being displayed in the console.
        
    .NOTES
        Author: Mötz Jensen (@Splaxi)
        
        Based on:
        https://learn.microsoft.com/en-us/power-platform/admin/programmability-tutorial-rbac-role-assignment?tabs=PowerShell
        https://learn.microsoft.com/en-us/power-platform/admin/programmability-authentication-v2?tabs=powershell%2Cpowershell-interactive%2Cpowershell-confidential
#>
function Get-PpacRbacRole {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
    param (
        [string] $Role = "*",

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
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }

        $resColRaw = Invoke-RestMethod `
            -Method Get `
            -Uri "https://api.powerplatform.com/authorization/roleDefinitions?api-version=2022-03-01-preview" `
            -Headers $headersPowerApi 4> $null | `
            Select-Object -ExpandProperty value

        #Saving the latest role definitions to a json file for later use in other cmdlets (like Get-PpacRbacRoleMember and Add-PpacRbacRoleMember)
        $pathMisc = Get-PSFConfigValue -FullName "d365bap.tools.internal.misc.path"
        $resColRaw | ConvertTo-Json -Depth 10 | `
            Set-Content -Path "$pathMisc\Ppac.Rbac.Roles.json" `
            -Force `
            -ErrorAction SilentlyContinue

        $resCol = $resColRaw | Where-Object {
            ($_.roleDefinitionId -like $Role) -or
            ($_.roleDefinitionName -like $Role) -or
            ($_.description -like $Role)
        } | Select-PSFObject -TypeName "D365Bap.Tools.PpacRbacRole" `
            -ExcludeProperty "@odata.etag", "description", "assignableScopes", "restrictedScopes", "permissions" `
            -Property "roleDefinitionId as RoleId",
        "roleDefinitionName as Role",
        "description as Description",
        "assignableScopes as AssignableScopes",
        "restrictedScopes as RestrictedScopes",
        "permissions as Permissions",
        @{Name = "PermissionList"; Expression = { $_.permissions -join "," } },
        @{Name = "RestrictedScopeList"; Expression = { $_.restrictedScopes -join "," } },
        @{Name = "AssignableScopeList"; Expression = { $_.assignableScopes -join "," } },
        *

        if ($AsExcelOutput) {
            $resCol | Export-Excel -WorksheetName "Get-PpacRbacRole"
            return
        }

        $resCol
    }

    end {
        
    }
    
}