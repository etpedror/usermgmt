# Simple Password Utils
*SimplePasswordUtils.psm1*  
Simple password generator module.  
  
## Exposed Methods  
### New-Password  
**Description**  
Returns a new password that complies with the specified parameters.  

**Syntax**  
```ps1
New-Password  
```

**Parameters**

|Name | Type | Description |
|:------------|:-------|:---------------------------------------------------|
| **LogFullPath** | *string* | The full path (including filename) of the log file |
| AppendDate | *boolean* | Whether or not to include the date on the filename. The default value is true |  

Mandatory parameters are in **bold**

**Example**
```ps1
New-Password -LogFullPath "C:\Code\Powershell\Azure\logs\myrecord.log"
```
    
      
## Exposed Variables   
### SimpleSymbolSet
**Description**    
The set of symbols to be used when generation a password.

**Default Value**  
!$%&/()=?}][{@#*+   
