﻿# DISCLAIMER
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
Import-Module '.\SimpleLogging.psm1';
Import-Module '.\SimplePasswordUtils.psm1';
Import-Module '.\SimpleAzureUtils.psm1';
Import-Module '.\SimpleAzureADUtils.psm1';


$userToDelete = "<user2delete>"; # The name of the user to disable
$disableInAD = $false; # Set to true to disable user in AD (user is not deleted, just disabled)
$subscriptionName = "<Subscription Name>"; # Leave Empty to go over all the subscriptions
$usersToReset = {"<user2reset1>", "<user2reset2>", "<user2reset3>"}; # Comma-separated list of users to reset passwords for
$KeyVaultName = "passes4all"; # Name of the KeyVault to Store the passwords in
$keyVaultRegion = "North Europe"; # Region where the keyvault should be created if non existent
$keyVaultRG = "TestResource"; # Resource group in which the keyvault should be created if non existent
$passwordSecretPrefix = "Pass4"; # Prefix to preppend to the username to make the key of keyvault
$BasePath = "C:\Code\Powershell\Azure"; # the base path to run the script from
$credentialPath = "\Credentials"; # The subfolder where the credentials file is to be stored
$credentialFileName = "\creds.xml"; # the name of the file where to store the credentials
$LogPath = "\logs"; # The subfolder where the logs are to be written
$LogFilename = "\DisableUser_Log_"; # Prefix to preppend to the date to get the log file name

function Disable-User{
    <#
        .SYNOPSIS
            A function to disable an user.
        .DESCRIPTION
            Disables the user in the AD.
        .PARAMETER Username
            The username of the user to remove.
        .EXAMPLE
            Disable-User -Username "matt.jones"
    #>
    param (
        [Parameter(Mandatory = $True)]
        [string] $username
    )
    
    write-Host "";
    Write-Host "DISABLING USER $username" -ForegroundColor Cyan;
    write-Host "";
    
    $user = Get-AzureADUser -SearchString $username
    if(!$user)
    {
        Log -message "User $username could not be found in the AD";
        Write-Error "User $username could not be found in the AD";
        return;
    }else{
        Log -message "User $username found: ObjectId = $($user.ObjectId)";
        Write-Host "User $username found: ObjectId = $($user.ObjectId)";
        if($disableInAD){
           Disable-ADUser -user $user;
        }
    
        Log -message "Looking for subscriptions";
        Write-Host "Looking for Subscriptions " -ForegroundColor Cyan -NoNewline;
        $subscriptions = Get-AzureRmSubscription;
        Log -message "Found $($subscriptions.Count) Subscriptions";
        Write-Host ":: Found $($subscriptions.Count) Subscriptions" -ForegroundColor Green;
        foreach($subscription in $subscriptions){
            if(($subscriptionName.Length -eq 0) -or ($subscription.Name -eq $subscriptionName))
            {   
                Write-Host "   Crawling Subscription $($subscription.Name) for Resource Groups " -ForegroundColor Cyan -NoNewline;
                Set-AzureRmContext -SubscriptionId $subscription.Id -Tenant $subscription.TenantId | Out-Null ;
                $resourceGroups = Get-AzureRmResourceGroup ;
                Write-Host ":: Found $($resourceGroups.Count) ResourceGroups" -ForegroundColor Green;
                foreach($resourceGroup in $resourceGroups){
                    Write-Host "      Crawling Resource Group $($resourceGroup.ResourceGroupName) for RBACs " -ForegroundColor Cyan -NoNewline;
                    $rbacsrg = Get-AzureRmRoleAssignment -ResourceGroupName $resourceGroup.ResourceGroupName -ResourceName $resource.ResourceName -ResourceType $resource.ResourceType;
                    Write-Host ":: Found $($rbacsrg.Count) RBACs" -ForegroundColor Green;
                    foreach($rbacrg in $rbacsrg)
                    {
                        if($rbacrg.DisplayName -eq $user.DisplayName)
                        {
                            Write-Host "      Removing RBAC for role $($rbacrg.RoleDefinitionName) and user $($rbacrg.DisplayName)" -NoNewline -ForegroundColor Cyan;
                            Remove-AzureRmRoleAssignment -ObjectId $rbacrg.ObjectId -RoleDefinitionName $rbacrg.RoleDefinitionName -ResourceGroupName $resourceGroup.ResourceGroupName;
                            Write-Host " :: Removed " -ForegroundColor Green;
                        }else{
                            Write-Host "      Skipping RBAC for role $($rbacrg.RoleDefinitionName) and user $($rbacrg.DisplayName)" -ForegroundColor DarkGray;
                        }                    
                    }
                    Write-Host "      Crawling Resource Group $($resourceGroup.ResourceGroupName) for Resources " -ForegroundColor Cyan -NoNewline;
                    $resources = Get-AzureRmResource -ODataQuery "`$filter=resourcegroup eq '$($resourceGroup.ResourceGroupName)'";
                    Write-Host ":: Found $($resources.Count) Resources" -ForegroundColor Green;
                    foreach($resource in $resources){
                        Write-Host "         Crawling Resource '$($resource.ResourceName)' [$($resource.ResourceType)] for RBACs " -ForegroundColor Cyan -NoNewline;
                        $rbacs = Get-AzureRmRoleAssignment -ResourceGroupName $resourceGroup.ResourceGroupName -ResourceName $resource.ResourceName -ResourceType $resource.ResourceType;
                        Write-Host ":: Found $($rbacs.Count) RBACs" -ForegroundColor Green;
                        foreach($rbac in $rbacs)
                        {
                            if($rbac[0].DisplayName -eq $user.DisplayName)
                            {
                                Write-Host "            Removing RBAC for role $($rbac.RoleDefinitionName) and user $($rbac.DisplayName)" -NoNewline -ForegroundColor Cyan;
                                Remove-AzureRmRoleAssignment -ObjectId $rbac.ObjectId -RoleDefinitionName $rbac.RoleDefinitionName -ResourceGroupName $resourceGroup.ResourceGroupName -ResourceName $resource.ResourceName -ResourceType $resource.ResourceType;
                                Write-Host " :: Removed " -ForegroundColor Green;
                            }else{
                                Write-Host "            Skipping RBAC for role $($rbac.RoleDefinitionName) and user $($rbac.DisplayName)" -ForegroundColor DarkGray;
                            }                    
                        }
                    }
                }
            }else{
                Write-Host "   Skipping Subscription $($subscription.Name)" -ForegroundColor DarkGray;
            }
        }
    }
    Write-Host "DONE DISABLING USER!" -ForegroundColor Green;
}


function Disable-ADUser{
    param (
         $user = $null 
    )
    if(-Not $user){
        Write-Host "Calling Disable-ADUser without a user parameter is not a valid function call" -ForegroundColor Red;
        Log("Called Disable-ADUser without a user parameter");
        Stop;
    }
    Write-Host "Disabling Account" -ForegroundColor Cyan -NoNewline;
    Set-AzureADUser -ObjectId $user.ObjectId -AccountEnabled false;
    Log -message "Account Disabled";
    Write-Host " : Done" -ForegroundColor Green;
    Write-Host "Revoking access tokens" -ForegroundColor Cyan -NoNewline;
    Revoke-AzureADUserAllRefreshToken -ObjectId $user.ObjectId;
    Log -message "Access Tokens Revoked";
    Write-Host "Done" -ForegroundColor Green;
}


clear;
#Get-Logging -BasePath $BasePath -LogPath $LogPath -LogFilename $LogFilename | Out-Null
#Get-ConnectiontoAzure -BasePath $BasePath -UserFilePath $credentialPath -UserFileName $credentialFileName;
#Disable-User -usernameToDelete $userToDelete
#Reset-UserPasswords -usernames $usersToReset -keyVaultName $KeyVaultName -resourceGroupName $keyVaultRG -location $keyVaultRegion -passwordFieldNamePrefix $passwordSecretPrefix

