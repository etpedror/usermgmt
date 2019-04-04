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

function Get-Logging{
    <#
        .SYNOPSIS
            Gets the path where to write the logs to.
        .DESCRIPTION
            Gets the path where to write the logs to, creating the folder structure if this doesn't exist.
            If left empty, the current path is used.
        .PARAMETER BasePath
            The base path where the script is running from.
        .PARAMETER LogPath
            The folder structure under BasePath where the logs are meant to be written to.
        .PARAMETER LogFilename
            The filename of the log file, without extension (this will always be "log").
        .PARAMETER IncludeDate
            Whether or not to include the date on the filename.
        .EXAMPLE
            Get-Logging -BasePath "C:\Code\Powershell\Azure" -LogPath "\logs" -LogFilename "\log"
    #>
    param (
        [Parameter(HelpMessage ='The base path where the script is running from')]
        [string] $BasePath = "",
        [Parameter(HelpMessage ='The folder structure under BasePath where the logs are meant to be written to')]
        [string] $LogPath = "\logs",
        [Parameter(HelpMessage =' The filename of the log file, without extension')]
        [string] $LogFilename = "\log",
        [Parameter(HelpMessage ='Whether or not to include the date on the filename')]
        [boolean] $IncludeDate = $true
    )
    if(-not $BasePath){
        $BasePath = (Get-Location).Path;
    }
    $logFolderExists = Test-Path "$($BasePath)$($LogPath)" -PathType Container;
    if(-Not $logFolderExists) {
        New-Item -ItemType Directory -Force -Path "$($BasePath)$($LogPath)";
    }
    $now = "";
    if($IncludeDate){
        $now = "_" + (Get-Date).ToString("yyyyMMdd");
    }
    $CurrentLogFilePath = "$($BasePath)$($LogPath)$($LogFilename)$($now).log"
    $IsLogInitialized = $true;
    return $CurrentLogFilePath;
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
            Log -File "C:\log\file.log" -Message "Something happened" -MessageLevel 4 -IncludeTime $true -DefaultLevel 2
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
    if(($DefaultLevel -ne 6) -and ($MessageLevel -ge $DefaultLogLevel))
    {
        if(-Not $IsLogInitialized){
            Get-Logging;
        }
        $logMessage = "";
        if($IncludeTimeInLog){
            $logMessage = (Get-Date).ToString("HH:mm:ss - ");
        }
        $logMessage = "$($logMessage)$($Message)";
        Out-File -Append -FilePath $CurrentLogFilePath -InputObject $logMessage;
    }
}

[string] $CurrentLogFilePath = '';
[boolean] $Private:IsLogInitialized = $false;
[LogLevel] $DefaultLogLevel = 2;
[boolean] $IncludeTimeInLog = $true;

Export-ModuleMember -Function 'Get-Logging';
Export-ModuleMember -Function 'Write-Log';
Export-ModuleMember -Variable '$CurrentLogFilePath';
Export-ModuleMember -Variable '$DefaultLogLevel';
Export-ModuleMember -Variable '$IncludeTimeInLog';
