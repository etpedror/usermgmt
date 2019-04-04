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

function Get-ConnectionToAzure{
    <#
        .SYNOPSIS
            Gets a connection to Azure.
        .DESCRIPTION
            Connects to Azure. If the User File Path and User File Name are specified, it tries to retrieve the credentials
            from there. If the file doesn't exist, it will be created. If either of these parameters is absent or if the file doesn't exist,
            the user will be prompted for credentials.
        .PARAMETER BasePath
            The base path for the script. If left empty, the current location is used
        .PARAMETER UserFilePath
            The relative path for the credential file
        .PARAMETER UserFileName
            The filename of the credential file
        .EXAMPLE
            Get-ConnectiontoAzure -BasePath "C:\Code\Powershell\Azure" -UserFilePath "\Credentials" -UserFileName "\creds.xml"
    #>
    param(
        [Parameter(HelpMessage ='The base path for the script')] 
        [string] $BasePath = "C:\Code\Powershell\Azure", 
        [Parameter(HelpMessage ='The path for the credential file')] 
        [string] $UserFilePath = "\Credentials",
        [Parameter(HelpMessage ='The filename of the credential file')] 
        [string] $UserFileName = "\creds.xml"
    )
    if(-Not $BasePath){
        $BasePath = Get-Location;
    }
    if($UserFilePath -and $UserFileName){
        $Private:credFolderExists = Test-Path "$($BasePath)$($UserFilePath)" -PathType Container;
        if(-Not $Private:credFolderExists) {
            New-Item -ItemType Directory -Force -Path "$($BasePath)$($UserFilePath)";
        }

        $Private:credentialFile = "$($BasePath)$($UserFilePath)$($UserFileName)";

        $Private:credFileExists = Test-Path $Private:credentialFile -PathType Leaf;
        if(-Not $Private:credFileExists) {
            $Private:AzureAdCred = Get-Credential;
            $Private:AzureAdCred | Export-CliXml -Path $Private:credentialFile;
        }else{
            $Private:AzureAdCred = Import-CliXml -Path $Private:credentialFile;
        }
    }else{
        $Private:AzureAdCred = Get-Credential;
    }

    Connect-AzureAD -Credential $Private:AzureAdCred | Out-Null;
    Connect-AzureRmAccount -Credential $Private:AzureAdCred | Out-Null;
}

function Get-KeyVault{
    <#
        .SYNOPSIS
            Gets an Azure Resource Group.
        .DESCRIPTION
            Returns an existing Azure Key Vault or attempts to create one if non-existent.
        .PARAMETER Name
            The name of the Azure Key Vault.
        .PARAMETER Location
            The location of the Azure Key Vault if it needs to be created
        .EXAMPLE
            Get-KeyVault -Name "mykeyvault" -ResourceGroupName "myresourcegroup" -Location "West Europe"
    #>
    param (
        [Parameter(HelpMessage = 'The name of the Azure Key Vault')]
        [Parameter(Mandatory=$true)]
        [Parameter(ValueFromPipeline=$true)]
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(HelpMessage = 'The name of the resource group if it needs to be created')]
        [string]$ResourceGroupName,
        [Parameter(HelpMessage = 'The location of the resource group if it needs to be created')]
        [string]$Location
    )   
    $keyVault = Get-AzureRMKeyVault -VaultName $KeyVaultName;
    if(-Not $keyVault){
        if($KeyVaultName -and $Location){
            $resourceGroup = Get-ResourceGroup -Name $ResourceGroupName;
            if(-Not $resourceGroup)
            {
                Write-Error "Couldn't get or create resource group";
                return $null;
            }
            $keyVault = New-AzureRmKeyVault -Name $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $Location;
            if(-Not $keyVault){
                Write-Error "Couldn't create KeyVault";     
                return $null;
            }
        }else{
            Write-Error "Couldn't get KeyVault and parameters missing for creating";
            return $null;
        }
    }else{
        return $keyVault;
    }
}

function Get-ResourceGroup{
    <#
        .SYNOPSIS
            Gets an Azure Resource Group.
        .DESCRIPTION
            Returns an existing Azure Resource Group or attempts to create one if non-existent.
        .PARAMETER Name
            The name of the Azure Resource Group.
        .PARAMETER Location
            The location of the Azure Resource Group if it needs to be created
        .EXAMPLE
            Get-ResourceGroup -Name "myresourcegroup" -Location "West Europe"
    #>
    param (
        [Parameter(HelpMessage = 'The name of the Azure Resource Group')]
        [Parameter(Mandatory=$true)]
        [Parameter(ValueFromPipeline=$true)]
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter(HelpMessage = 'The location of the resource group if it needs to be created')]
        [string]$Location
    )     
    $resourceGroup = Get-AzureRmResourceGroup -Name $Name;
    if(-Not $resourceGroup -and $Location){
        $resourceGroup = New-AzureRmResourceGroup -Name $Name -Location $Location;
    }else{
        Write-Error "Resource Group not found (and couldn't be created as Location wasn't specified)";
        return $null; 
    }
    if(-Not $resourceGroup){
        Write-Error "Resource Group not found (and couldn't be created)";
        return $null; 
    }
    return $resourceGroup;    
}

function Get-RestClientAdminToken{
    <#
        .SYNOPSIS
            Gets a token to use when requesting tokens to manage Azure Resources.
        .DESCRIPTION
            Gets a token to use when requesting tokens to manage Azure Resources.
        .PARAMETER ADTenantId
            The Id of the Azure AD tenant.
        .PARAMETER ClientId
            The client id on the Azure AD.
        .PARAMETER ClientSecret
            The client secret on the Azure AD.
        .PARAMETER ResourceUri
            The resource that the token will be used on. A null value defaults to "https://management.core.windows.net/"
        .EXAMPLE
            Get-RestClientAdminToken -ADTenantId "12345678-1234-1234-1234-1234567890AB" -clientId "" -clientSecret "" -ResourceUri ""
    #>
    param (
        [Parameter(HelpMessage = "The Id of the Azure AD tenant")]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty]
        [string] $ADTenantId,
        [Parameter(HelpMessage = "The client id on the Azure AD")]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty]
        [string] $ClientId,
        [Parameter(HelpMessage = "The client secret on the Azure AD")]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty]
        [string] $ClientSecret,
        [Parameter(HelpMessage = "The resource that the token will be used on")]
        [string] $ResourceUri = "https://management.core.windows.net/"
    )
    $authRequestBody = @{};
    $authRequestBody.grant_type = "client_credentials";
    $authRequestBody.resource = $Resource;
    $authRequestBody.client_id = $clientId;
    $authRequestBody.client_secret = $clientSecret;
    $authUri = "https://login.microsoftonline.com/$tenantId/oauth2/token?api-version=1.0"
    $auth = Invoke-RestMethod -Uri $authUri -Method Post -Body $authRequestBody;
    return $auth.access_token;
}

function Get-RestClientResourceToken{
    <#
        .SYNOPSIS
            Gets a token to use when managing an Azure resource.
        .DESCRIPTION
            Gets a token to use when managing an Azure resource.
        .PARAMETER AuthToken
            The token requester token. Can be obtained using Get-RestClientAdminToken.
        .PARAMETER SubscriptionId
            The id of the subscription.
        .PARAMETER ResourceGroupName
            The resource group name.
        .PARAMETER ResourceType
            The type of the resource.
        .PARAMETER ResourceName
            The name of the resource.
        .PARAMETER TokenEndpoint
            The resource's token endpoint.
        .PARAMETER ApiVersion
            The version of the API.
        .EXAMPLE
            Get-RestClientResourceToken -AuthToken "asdfasdasd" -SubscriptionId "12345678-..." -ResourceGroupName "myresourcegroup" -ResourceType "functions" -ResourceName "myfunction"
    #>
    param (
        [Parameter(HelpMessage = "The token requester token")]
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty]
        [string] $AuthToken,
        [Parameter(HelpMessage = "The id of the subscription")]
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty]
        [string] $SubscriptionId,
        [Parameter(HelpMessage = "The resource group name")]
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty]
        [string] $ResourceGroupName,
        [Parameter(HelpMessage = "The type of the resource")]
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty]
        [string] $ResourceType,
        [Parameter(HelpMessage = "The name of the resource")]
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty]
        [string] $ResourceName, 
        [Parameter(HelpMessage = "The resource's token endpoint")]
        [string] $TokenEndpoint = "/functions/admin/token",
        [Parameter(HelpMessage = "The version of the API")]
        [string] $ApiVersion = "2016-08-01"
    )
    $baseUri = "https://management.azure.com/subscriptions/$sSubscriptionId/resourceGroups/$ResourceGroupName/providers/$ResourceType/$ResourceName";
    $tokenHeader = @{ "Authorization" = "Bearer " + $AuthToken }
    $tokenUri = $baseUri + $TokenEndpoint + "?api-version=" + $ApiVersion
    return Invoke-RestMethod -Method Get -Uri $tokenUri -Headers $tokenHeader
}

Export-ModuleMember -Function 'Get-ConnectionToAzure';
Export-ModuleMember -Function 'Get-KeyVault';
Export-ModuleMember -Function 'Get-ResourceGroup';
Export-ModuleMember -Function 'Get-RestClientAdminToken';
Export-ModuleMember -Function 'Get-RestClientResourceToken';

<#
    function Get-ResourceGroupaaaaaa{  
    Write-Host $auth
    $functionAppBaseUri = "https://$functionAppName.azurewebsites.net/admin"
    $adminTokenHeader = @{ "Authorization" = "Bearer " + $adminBearerToken }
    $functionAppBaseUri = "https://$functionAppName.azurewebsites.net/admin"
    $functionName = "SchemaProviderSync"
    $functionKeysEndpoint = "/functions/$functionName/keys"
    $functionKeysUri = $functionAppBaseUri + $functionKeysEndpoint
    $adminTokenHeader = @{ "Authorization" = "Bearer " + $adminBearerToken }
    Write-Host "--------------------------------------------"
    Write-Host $functionKeysUri
    Write-Host "**************************************************"

    $functionKeys = Invoke-RestMethod -Method Get -Uri $functionKeysUri -Headers $adminTokenHeader
    Write-Host $functionKeys.keys
    */

}
#>