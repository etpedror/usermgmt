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
Simple password generator module
.Description
This script implements a simple password for powershell
#>

function Get-RandomCharacters{
    <#
        .SYNOPSIS
            Gets a string of random characters from a given set.
        .DESCRIPTION
            Returns a string of length Length made with random characters from the set Characters.
        .PARAMETER Length
            The length of the string to return.
        .PARAMETER Characters
            The set of characters that will be used as source.
        .EXAMPLE
            Get-RandomCharacters -Length 8 -Characters "abcdedfghijklmno"
    #>
    param (
        [Parameter(HelpMessage = 'The length of the string to return')]
        [Parameter(Mandatory = $true)]
        [ValidateRange(3,20)]
        [int] $Length, 
        [Parameter(HelpMessage = 'The set of characters that will be used as source')]
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array] $Characters
    )
    $random = 1..$Length | ForEach-Object { 
        Get-Random -Maximum $Characters.Length; 
    }
    $private:ofs="";
    return [string]$Characters[$random];
}

function Get-ScrambledString{
    <#
        .SYNOPSIS
            Scrambles a string.
        .DESCRIPTION
            Returns a string created by scrambling a given string.
        .PARAMETER InputString
            The string to scramble.
        .EXAMPLE
            Get-ScrambledString -InputString "abcdedfghijklmno"
    #>
    param (
        [Parameter(HelpMessage = 'The length of the string to return')]
        [Parameter(Mandatory=$true)]
        [Parameter(ValueFromPipeline=$true)]
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$InputString
    )     
    $characterArray = $InputString.ToCharArray();   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length;     
    $outputString = -join $scrambledStringArray;
    return $outputString;
}

function New-Password{
    <#
        .SYNOPSIS
            Creates a new random password.
        .DESCRIPTION
            Returns a new password that complies with the specified parameters.
        .PARAMETER LengthMin
            The minimum lenght of the password. The default value is 10
        .PARAMETER LengthMax
            The maximum length of the password. The default value is 15.
        .PARAMETER UpperMin
            The minimum number of uppercase characters. The default value is 1.
        .PARAMETER UpperMax
            The maximum number of uppercase characters. The default value is 3.
        .PARAMETER DigitMin
            The minimum number of numeric characters. The default value is 1.
        .PARAMETER DigitMax
            The maximum number of numeric characters. The default value is 3.
        .PARAMETER SymbolMin
            The minimum number of symbols. The default value is 1.
        .PARAMETER SymbolMax
            The maximum number of symbols. The default value is 3.
        .EXAMPLE
            New-Password -LengthMin 8 -LengthMax 10
    #>
    param(
        [Parameter(HelpMessage = 'The minimum lenght of the password. The default value is 10.')]
        [int] $LengthMin = 10,
        [Parameter(HelpMessage = 'The maximum length of the password. The default value is 15')]
        [int] $LengthMax = 15,
        [Parameter(HelpMessage = 'The minimum number of uppercase characters. The default value is 1')]
        [int] $UpperMin = 1,
        [Parameter(HelpMessage = 'The maximum number of uppercase characters. The default value is 3')]
        [int] $UpperMax = 3,
        [Parameter(HelpMessage = 'The minimum number of numeric characters. The default value is 1')]
        [int] $DigitMin = 1,
        [Parameter(HelpMessage = 'The maximum number of numeric characters. The default value is 3')]
        [int] $DigitMax = 3,
        [Parameter(HelpMessage = 'The minimum number of symbols. The default value is 1')]
        [int] $SymbolMin = 1,
        [Parameter(HelpMessage = 'The maximum number of symbols. The default value is 3')]
        [int] $SymbolMax = 3
    )
    $passwordLength = Get-Random -Minimum $LengthMin -Maximum $LengthMax;
    $numUpperCase = Get-Random -Minimum $UpperMin -Maximum $UpperMax;
    $numDigits = Get-Random -Minimum $DigitMin -Maximum $DigitMax;
    $numSymbols = Get-Random -Minimum $SymbolMin -Maximum $SymbolMax;
    $numLowerCase = $passwordLength - $numUpperCase - $numDigits - $numSymbols;

    $password = Get-RandomCharacters -length $numLowerCase -characters $SimpleLowercaseSet;
    $password += Get-RandomCharacters -length $numUpperCase -characters $SimpleUppercaseSet;
    $password += Get-RandomCharacters -length $numDigits -characters $SimpleNumericSet;
    $password += Get-RandomCharacters -length $num -characters $SimpleSymbolSet;

    return Get-ScrambledString $password;
}

[string] $Private:SimpleLowercaseSet = 'abcdefghiklmnoprstuvwxyz';
[string] $Private:SimpleUppercaseSet = 'ABCDEFGHKLMNOPRSTUVWXYZ';
[string] $Private:SimpleNumericSet = '0123456789';

[string] $SimpleSymbolSet = '!$%&/()=?}][{@#*+';

Export-ModuleMember -Function 'New-Password';
Export-ModuleMember -Variable 'SimpleSymbolSet';
