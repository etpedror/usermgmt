# Simple Modules to help with some Azure operations
  
    
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
The set of symbols to be used when generation a password


