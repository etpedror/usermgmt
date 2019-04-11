# Simple Modules to help with some Azure operations
This set of powershell scripts is meant to automate some tasks on Azure.  
It is still a work in progress, but the main goal is to have a set of tools that make it simple to perform some normal tasks (like rotating passwords), either on the console or as part of a pipeline
  
  
---   
## Simple Logging  
*SimpleLogging.psm1*  
Simple log handler for powershell scripts - This script implements a simple logging tool for powershell.  
   
#### Exposed Methods
**Start-Logging**  
Initiliazes the logging options and sets the path where to write the logs to, creating the folder structure if this doesn't exist. If left empty, the current path is used.  
  
**Write-Log**
Writes a message to the log file, creating it if non existing.  
  
    
---
## Simple Password Utils  
*SimplePasswordUtils.psm1*  
Simple password generator module.  
  
#### Exposed Methods  
**New-Password**    
Returns a new password that complies with the specified parameters.  
  
#### Exposed Variables   
**SimpleSymbolSet**  
The set of symbols to be used when generation a password.
  
  
---
## Simple Azure Utils
*SimpleAzureUtils.psm1*  
Simple azure connection tool for powershell scripts.

#### Exposed Methods
**Get-ConnectionToAzure**  
Connects to Azure. If the User File Path and User File Name are specified, it tries to retrieve the credentials from there. If the file doesn't exist, it will be created. If either of these parameters is absent or if the file doesn't exist, the user will be prompted for credentials.  
  
**Get-KeyVault**  
Returns an existing Azure Key Vault or attempts to create one if non-existent.  
  
**Get-ResourceGroup**  
Returns an existing Azure Resource Group or attempts to create one if non-existent.  
  
**Get-RestClientAdminToken**  
Gets a token to use when requesting tokens to manage Azure Resources.  
  
**Get-RestClientResourceToken**  
Gets a token to use when managing an Azure resource.  
  
  
---
## Simple Azure AD Utils
*SimpleAzureADUtils.psm1*
Simple tool to reset user passwords.
  
#### Exposed Methods
**Reset-UserPasswords**  
A function to rotate the passwords for users.