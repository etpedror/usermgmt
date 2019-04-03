$userToDelete = "<user2delete>"; # The name of the user to disable
$disableInAD = $false; # Set to true to disable user in AD (user is not deleted, just disabled)
$subscriptionName = "<Subscription Name>"; # Leave Empty to go over all the subscriptions
$usersToReset = "<user2reset1>", "<user2reset2>", "<user2reset3>"; # Comma-separated list of users to reset passwords for
$keyVaultName = "passes4all"; # Name of the KeyVault to Store the passwords in
$keyVaultRegion = "North Europe"; # Region where the keyvault should be created if non existent
$keyVaultRG = "TestResource"; # Resource group in which the keyvault should be created if non existent
$passwordSecretPrefix = "Pass4"; # Prefix to preppend to the username to make the key of keyvault
$basePath = "C:\Code\Powershell\Azure"; # the base path to run the script from
$credentialPath = "\Credentials"; # The subfolder where the credentials file is to be stored
$credentialFileName = "\creds.xml"; # the name of the file where to store the credentials
$logPath = "\logs"; # The subfolder where the logs are to be written
$logFileName = "\DisableUser_Log_"; # Prefix to preppend to the date to get the log file name

function Reset-UserPasswords{
    param (
        [array] $usernames,
        [string] $keyVaultName,
        [string] $resourceGroupName = "Group14",
        [string] $location = "North Europe",
        [string] $passwordFieldNamePrefix = "Pass4"
    )
    write-Host "";
    Write-Host "RESETTING PASSWORD(S)" -ForegroundColor Cyan;
    write-Host "";

    $keyVault = Get-AzureRMKeyVault -VaultName $keyVaultName;
    if(-Not $keyVault){
        $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName;
        if(-Not $resourceGroup){
            $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $location;
        }
        $keyVault = New-AzureRmKeyVault -Name $keyVaultName -ResourceGroupName $resourceGroupName -Location $location;
    }
    if(-Not $keyVault){
        Log -message "KeyVault not found and couldn't be created";
        Write-Error "KeyVault not found and couldn't be created";
        return;
    }
    foreach($username in $usernames){
        $user = Get-AzureADUser -SearchString $username;
        if(!$user)
        {
            Log -message "Password rotation - User $username could not be found in the AD";
            Write-Error "Password rotation - User $username could not be found in the AD";
            return;
        }else{
            Write-Host "Resetting Password for $($username)" -ForegroundColor Cyan
            $keyVaultKey = "$($passwordFieldNamePrefix)$($username)";
            $password = New-Password;
            Log -message "New password for user $($username) is $($password) - KeyVault: $($keyVaultName), Key: $($keyVaultKey)";
            #Write-Host "New password for user $($username) is $($password) - KeyVault: $($keyVaultName), Key: $($keyVaultKey)";
            $securePassword = ConvertTo-SecureString -String $password -Force –AsPlainText;
            #Set-AzureADUserPassword -ObjectId $user.ObjectId -Password $securePassword;
            $expiryDate = (Get-Date).AddDays(-1).ToUniversalTime()
            Set-AzureKeyVaultSecretAttribute -VaultName $keyVaultName -Name $keyVaultKey -enable $false -Expires $expiryDate | Out-Null;
            $expiryDate = (Get-Date).AddYears(2).ToUniversalTime()
            Set-AzureKeyVaultSecret -VaultName $keyVaultName -Name $keyVaultKey -SecretValue $securePassword -Expires $expiryDate | Out-Null;
            Write-Host ":: Done" -ForegroundColor Green;
        }
    }
    Write-Host "DONE RESETTING PASSWORD(S)!" -ForegroundColor Green;
}

function Disable-User{
    param (
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

function Prepare-Logging{
    param (
        [PSDefaultValue(Help = 'The base path for the script')] [string] $basePath = "C:\Code\Powershell\Azure", 
        [PSDefaultValue(Help = 'The path for the logs')] [string] $logPath = "\logs",
        [PSDefaultValue(Help = 'The filename prefix for the log file')] [string] $logFilename = "\log"
    )
    $logFolderExists = Test-Path "$($basePath)$($logPath)" -PathType Container;
    if(-Not $logFolderExists) {
        New-Item -ItemType Directory -Force -Path "$($basePath)$($logPath)";
    }
    $now = (Get-Date).ToString("yyyyMMdd");
    return "$($basePath)$($logPath)$($logFilename)_$($now).log";
}

function Log{
    param (
        [PSDefaultValue(Help = 'The full path to the log file')][string] $file,
        [PSDefaultValue(Help = 'The message to log')][string] $message,
        [PSDefaultValue(Help = 'Whether to include time at the start of the message')][boolean] $includeTime = $true
    )
    if(-Not $file){
        $file = Prepare-Logging;
    }
    $logMessage = "";
    if($includeTime){
        $logMessage = (Get-Date).ToString("HH:mm:ss - ");
    }
    $logMessage = "$($logMessage)$($message)";
    Out-File -Append -FilePath $file -InputObject $logMessage;
}

function Get-ConnectionToAzure{
    param(
        [PSDefaultValue(Help = 'The base path for the script')] [string] $basePath = "C:\Code\Powershell\Azure", 
        [PSDefaultValue(Help = 'The path for the credential file')] [string] $credentialPath = "\Credentials",
        [PSDefaultValue(Help = 'The filename of the credential file')] [string] $credentialFilename = "\creds.xml"
    )
    $credFolderExists = Test-Path "$($basePath)$($credentialPath)" -PathType Container;
    if(-Not $credFolderExists) {
        New-Item -ItemType Directory -Force -Path "$($basePath)$($credentialPath)";
    }

    $credentialFile = "$($basePath)$($credentialPath)$($credentialFilename)";
    $credFileExists = Test-Path $credentialFile -PathType Leaf;
    if(-Not $credFileExists) {
        $credential = Get-Credential;
        $credential | Export-CliXml -Path $credentialFile;
    }

    $AzureAdCred = Import-CliXml -Path $credentialFile;
    Connect-AzureAD -Credential $AzureAdCred | Out-Null;
    Connect-AzureRmAccount -Credential $AzureAdCred | Out-Null;
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

function Get-RandomCharacters{
    param (
        [int] $length, 
        [array] $characters
    )
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}
 
function Scramble-String{
    param (
        [string]$inputString
    )     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}

function New-Password{
    param(
        [int] $lengthMin = 10,
        [int] $lengthMax = 15,
        [int] $upperMin = 1,
        [int] $upperMax = 3,
        [int] $digitMin = 1,
        [int] $digitMax = 3,
        [int] $symbolMin = 1,
        [int] $symbolMax = 3
    )


    $passwordLength = Get-Random -Minimum $lengthMin -Maximum $lengthMax;
    $numUpperCase = Get-Random -Minimum $upperMin -Maximum $upperMax;
    $numDigits = Get-Random -Minimum $digitMin -Maximum $digitMax;
    $numSymbols = Get-Random -Minimum $symbolMin -Maximum $symbolMax;
    $numLowerCase = $passwordLength - $numUpperCase - $numDigits - $numSymbols;

    $password = Get-RandomCharacters -length $numLowerCase -characters 'abcdefghiklmnoprstuvwxyz';
    $password += Get-RandomCharacters -length $numUpperCase -characters 'ABCDEFGHKLMNOPRSTUVWXYZ';
    $password += Get-RandomCharacters -length $numDigits -characters '1234567890';
    $password += Get-RandomCharacters -length $num -characters '!$%&/()=?}][{@#*+';

    return Scramble-String $password;
}

clear;
Prepare-Logging -basePath $basePath -logPath $logPath -logFilename $logFileName | Out-Null
Get-ConnectionToAzure -basePath $basePath -credentialPath $credentialPath -credentialFilename $credentialFileName;
#Disable-User -usernameToDelete $userToDelete
Reset-UserPasswords -usernames $usersToReset -keyVaultName $keyVaultName -resourceGroupName $keyVaultRG -location $keyVaultRegion -passwordFieldNamePrefix $passwordSecretPrefix

