# Simple Logging  
*SimpleLogging.psm1*  
Simple log handler for powershell scripts - This script implements a simple logging tool for powershell.  
   
## Exposed Methods
### Start-Logging
**Description**  
Initializes the logging options and sets the path where to write the logs to, creating the folder structure if this doesn't exist. If left empty, the current path is used.  
  
**Syntax**
```ps1
Start-Logging -LogFullPath] <String> [[-AppendDate] <Boolean>] [[-IncludeTimeInLog] <Boolean>] [[-Level] {Trace | Debug | Information | Warning | Error | Critical | None}] [<CommonParameters>]
```
  
**Parameters**  
| Name | Type | Description |
| :--- | :--- | :--- |
| **LogFullPath** | *string* | The full path (including filename) of the log file |
| AppendDate | *boolean* | Whether or not to include the date on the filename. The default value is true |
| IncludeTimeInLog | *boolean* | Whether or not to include the timestamp on the beggining of each line. The default value is true |
| Level | *LogLevel* | The minimum level a message should have to be written to the log file. The default level is 2 (Information) |  
Mandatory parameters are in **bold**

**Example**
```ps1
Start-Logging -LogFullPath "C:\Code\Powershell\Azure\logs\myrecord.log"
```
    
      
### Write-Log
Writes a message to the log file, creating it if non existing.  
  
**Syntax**
```ps1
Write-Log [-Text] <String> [[-Level] {Trace | Debug | Information | Warning | Error | Critical | None}] [<CommonParameters>]
```
  
**Parameters**
|Name | Type | Description |
|:------------|:-------|:---------------------------------------------------|
| **Text** | *string* | The text to log |
| Level | *boolean* | The log level of the text. The default is 2, Information |

Mandatory parameters are in **bold**

**Example**
```ps1
Write-Log -Text "Something happened" -MessageLevel 4
```  
