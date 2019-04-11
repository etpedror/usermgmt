# DISCLAIMER
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

<#
.Synopsis
Simple azure connection tool for powershell scripts
.Description
This script implements a simple Azure connection tool for powershell
#>
Import-Module '.\SimpleLogging.psm1';
Import-Module '.\SimplePasswordUtils.psm1';
Import-Module '.\SimpleAzureUtils.psm1';

function Reset-UserPasswords{
    <#
        .SYNOPSIS
            A function to rotate the passwords for users.
        .DESCRIPTION
            Rotates the passwords for the usernames in the list.
        .PARAMETER Usernames
            The array of usernames to receive new passwords.
        .PARAMETER KeyVaultName
            The name of the KeyVault where the rotated user passwords will be stored.
        .PARAMETER ResourceGroupName
            The name of the resource group where to create the KeyVault if non existing.
        .PARAMETER Location
            The location where to create the Key Vault if non existing.
        .PARAMETER UserPwdPrefix
            The prefix to append to the user name when saving the password. For example, if the user is "jsmith" and the prefix is "pass4", the secret in KeyVault will be named "pass4jsmith".
        .EXAMPLE
            Reset-UserPasswords -Usernames "matt.jones","peter.bone" -KeyVaultName "supersecretstore" -ResourceGroupName "myresourcegroup" -Location "North Europe" -UserPwdPrefix "pass4"
    #>
    param (
        [Parameter(HelpMessage = "The array of usernames to receive new passwords")]
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty]
        [array] $Usernames,
        [Parameter(HelpMessage = "The name of the KeyVault where the rotated user passwords will be stored")]
        [Parameter(Mandatory = $True)]
        [ValidateNotNull]
        [string] $KeyVaultName,
        [Parameter(HelpMessage = "The name of the resource group where to create the KeyVault if non existing")]
        [Parameter(Mandatory = $True)]
        [string] $ResourceGroupName,
        [Parameter(HelpMessage = "The location where to create the Key Vault if non existing")]
        [Parameter(Mandatory = $False)]
        [string] $Location,
        [Parameter(HelpMessage = "The prefix to append to the user name when saving the password")]
        [Parameter(Mandatory = $False)]
        [string] $UserPwdPrefix
    )
    Write-Host "RESETTING PASSWORD(S)" -ForegroundColor Cyan;
    if($WhatIfPreference)
    {
        Write-Host "Running in WhatIf mode" -ForegroundColor Yellow;
    }
    if(-Not $WhatIfPreference)
    {
        $keyVault = Get-KeyVault -Name $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $Location;
        if(-Not $keyVault){
            Log -message "KeyVault not found and couldn't be created";
            Write-Error -message "KeyVault not found and couldn't be created" -Category ResourceUnavailable;
            return;
        }
    }

    foreach($username in $Usernames){
        $user = Get-AzureADUser -SearchString $username;
        if(!$user)
        {
            Log -message "Password rotation - User $username could not be found in the AD";
            Write-Error "Password rotation - User $username could not be found in the AD";
            return;
        }else{
            Write-Host "Resetting Password for $($username)" -ForegroundColor Cyan
            $keyVaultKey = "$($UserPwdPrefix)$($username)";
            $password = New-Password;
            Log -message "New password for user $($username) is $($password) - KeyVault: $($KeyVaultName), Key: $($keyVaultKey)";
            Write-Host "New password for user $($username) is $($password) - KeyVault: $($KeyVaultName), Key: $($keyVaultKey)";
            $securePassword = ConvertTo-SecureString -String $password -Force –AsPlainText;
            if(-Not $WhatIfPreference)
            {
                Set-AzureADUserPassword -ObjectId $user.ObjectId -Password $securePassword;
                $expiryDate = (Get-Date).AddDays(-1).ToUniversalTime()
                Set-AzureKeyVaultSecretAttribute -VaultName $KeyVaultName -Name $keyVaultKey -enable $false -Expires $expiryDate | Out-Null;
                $expiryDate = (Get-Date).AddYears(2).ToUniversalTime()
                Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $keyVaultKey -SecretValue $securePassword -Expires $expiryDate | Out-Null;
            }
            Write-Host ":: Done" -ForegroundColor Green;
        }
    }
    Write-Host "DONE RESETTING PASSWORD(S)!" -ForegroundColor Green;
}