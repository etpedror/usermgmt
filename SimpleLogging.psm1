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
Simple log handler for powershell scripts
.Description
This script implements a simple logging tool for powershell
#>

enum LogLevel {
    Trace = 0
    Debug = 1
    Information = 2
    Warning = 3
    Error = 4
    Critical = 5
    None = 6
}

class LogParameters {
    [string] $LogFilePath = '';
    [LogLevel] $DefaultLogLevel = 2;
    [boolean] $IncludeTimeInLog = $true;
}

[LogParameters] $private:SimpleLogParameters = $null;

function Start-Logging{
    <#
        .SYNOPSIS
            Initiliazes the logging options and sets the path where to write the logs to.
        .DESCRIPTION
            Initiliazes the logging options and sets the path where to write the logs to, creating the folder structure if this doesn't exist.
            If left empty, the current path is used.
        .PARAMETER LogFullPath
            The full path (including filename) of the log file.
        .PARAMETER AppendDate
            Whether or not to include the date on the filename. The default value is true.
        .PARAMETER IncludeTimeInLog
            Whether or not to include the date on the filename. The default value is true.
        .PARAMETER LogLevel
            The default log level. the default value is Information.
        .EXAMPLE
            Start-Logging -LogFullPath "C:\Code\Powershell\Azure\logs\myrecord.log"
    #>
    param (
        [Parameter(HelpMessage ='The full path (including filename) of the log file')]
        [string] $LogFullPath = "C:\Logs\simplelog.log",
        [Parameter(HelpMessage ='Whether or not to append the date to the filename. The default value is true')]
        [boolean] $AppendDate = $true,
        [Parameter(HelpMessage ='Whether or not to prepend a timestamp to the beggining of every log message. The default value is true')]
        [boolean] $IncludeTimeInLog = $true,
        [Parameter(HelpMessage ='The default log level')]
        [LogLevel] $Level = "Information"
    )
    $private:SimpleLogParameters = New-Object -TypeName LogParameters;
    $private:SimpleLogParameters.DefaultLogLevel = Level;
    $private:SimpleLogParameters.IncludeTimeInLog = $IncludeTimeInLog;
    if($private:SimpleLogParameters.DefaultLogLevel -ne 6)
    {
        $logPath = Split-Path $LogFullPath -Parent;
        $logFolderExists = Test-Path $logPath -PathType Container;
        if(-Not $logFolderExists) {
            New-Item -ItemType Directory -Force -Path $logPath;
        }
        $now = "";
        if($AppendDate){
            $now = "_" + (Get-Date).ToString("yyyyMMdd");
        }
        $filename = Split-Path $LogFullPath -Leaf;
        $parts = $filename.Split(".")
        $logFileName = $parts[0]
        $logFileExtension = ".$($parts[1])";
        $CurrentLogFilePath = "$LogFilename$now$logFileExtension";
        $private:SimpleLogParameters.LogFilePath = $CurrentLogFilePath;
    }
}

function Write-Log{
    <#
        .SYNOPSIS
            Writes a message to the log file.
        .DESCRIPTION
            Writes a message to the log file, creating it if non existing.
        .PARAMETER Message
            The message to log.
        .PARAMETER MessageLevel
            The log level of the message. The default is 2, Information.
        .EXAMPLE
            Log -File "C:\log\file.log" -Message "Something happened" -MessageLevel 4
            Log -File "C:\log\file.log" -Message "Something happened"
            Log -File "C:\log\file.log" -Message "Something happened" -MessageLevel 6 
    #>
    param (
        [Parameter(HelpMessage ='The message to log')]
        [Parameter(Mandatory = $true)]
        [Parameter(ValueFromPipeline=$true)]
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $Message,
        [Parameter(HelpMessage ='The log level of the message. The default is 2, Information')]
        [LogLevel] $MessageLevel = 2
    )
    if(-Not $private:SimpleLogParameters)
    {
        throw "SimpleLogging not initialized. See Start-Logging for more information";
    }
    if(($private:SimpleLogParameters.$DefaultLevel -ne 6) -and ($MessageLevel -ge $private:SimpleLogParameters.$DefaultLogLevel))
    {
        $logMessage = "";
        if($private:SimpleLogParameters.$IncludeTimeInLog){
            $logMessage = (Get-Date).ToString("HH:mm:ss - ");
        }
        $logMessage = "$($logMessage)$($Message)";
        Out-File -Append -FilePath $private:SimpleLogParameters.$CurrentLogFilePath -InputObject $logMessage;
    }
}

Export-ModuleMember -Function 'Start-Logging';
Export-ModuleMember -Function 'Write-Log';
