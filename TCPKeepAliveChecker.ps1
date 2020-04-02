<#
.NOTES
	Name: TCPKeepAliveTimeChecker.ps1
    Author: Josh Jerdon
    Email: jojerd@microsoft.com
	Requires: PowerShell 3.0, Exchange Management Shell as well as administrator rights on the target Exchange
	server.
	Version History:
	1.0 - 5/15/2017
    1.01 - 6/28/2017 Fixed Foreach loop bug asking for KeepAliveTime Value for each server when changing multiple servers.
    1.02 - 3/7/2018 Fixed PSSnapin load errors if script was executed more than once in a single PowerShell session. Also refined how script checks for PowerShell version.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
.SYNOPSIS
	Checks all of the Exchange Servers within a given AD site and generates a report of it's findings,
    namely if the TCP KeepAliveTime registry key exists and if so what the value is.
    It also provides the functionality to modify the TCP Keep Alive Settings of all Exchange servers
    in the local AD site. This is extremely useful in large Exchange organizations but should be used with
    care.

#>

#Checking Powershell Version to Ensure Script Works as Intended
if ($PSVersionTable.PSVersion.Major -gt 3) {
    Write-Host "PowerShell meets minimum version requirements, continuing" -ForegroundColor Green
    Start-Sleep -Seconds 3
    Clear-Host

    #Add Exchange Management Capabilities Into The Current PowerShell Session.
    $CheckSnapin = (Get-PSSnapin | Where {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"} | Select Name)
    if ($CheckSnapin -like "*Exchange.Management.PowerShell*") {
        Write-Host "Exchange Snap-in already loaded, continuing...." -ForegroundColor Green
    }
    else {
        Write-Host "Loading Exchange Snap-in Please Wait..."
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue
    }
    #Search local AD Site for all Exchange Servers.
    $ADSite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name
    Write-Host "Searching Active Directory Site $ADSite for Exchange Servers, Please Wait..."
    $Servers = Get-ExchangeServer | Where-Object {$_.Site -match $ADSite}

    #File Output parameters for report output
    $OutputFilePath = "."
    $OutPutReportName = "TCPKeepAliveTimeReport" + "-" + (Get-Date).ToString("MMddyyyyHHmmss") + ".csv"
    $OutPutFullReportPath = $OutputFilePath + "\" + $OutPutReportName

    if ($Servers.count -gt 0) {

        #Connect to Each server that it finds from above and open the KeepAliveTime registry key if it exists and record the value.
        foreach ($Server in $Servers) {

            $EXCHServer = $Server.name
            $OpenReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $EXCHServer)
            $RegKeyPath = 'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
            $RegKey = $OpenReg.OpenSubKey($RegKeyPath)
            $TCPKeepAlive = $RegKey.GetValue('KeepAliveTime')
            $Exists = if ($TCPKeepAlive) {$true} else {$false}

            #Dump the scripts findings into an object.
            $Report = [PSCustomObject]@{
                "Server Name"         = $EXCHServer;
                "Key Present"         = $Exists;
                "TCP Keep Alive Time" = $TCPKeepAlive
            }

            #Write the output to a report file
            $Report | Export-Csv ($OutPutFullReportPath) -Append -NoTypeInformation
        }
    }
    else {

        Write-Host "Found 0 Exchange Servers, Exiting Script..." -ForegroundColor Red
        Write-Host " "
        Write-Host " "
        Write-Host "Press Any Key To Continue ..."
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        Exit
    }
    #Asks if you'd like to change the TCP Keep Alive Times.
    Clear-Host
    $Message = "Do You Want To Create And Or Modify The TCP KeepAliveTime Registry Key?"
    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "help";
    $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "help";
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $no);
    $answer = $host.UI.PromptForChoice($caption, $message, $choices, 1)

    switch ($answer) {
        0 {Write-Host "Continuing Script As You Have Confirmed That You Want To Create And Or Modify The TCP KeepAliveTime Registry Key"; Start-Sleep -Seconds 5}
        1 {Write-Host "Exiting Script..."; exit}
    }
    Clear-Host
    $TimeValue = Read-Host 'How Many Milliseconds Do You Want The TCP Keep Alive Time Set Too? (Default is 1,800,000ms (30 minutes)'
    $DefaultValue = "1800000"
    $KeyName = "KeepAliveTime"
    Clear-Host


    foreach ($Server in $Servers) {

        $EXCHServer = $Server.name
        $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $EXCHServer)
        $SubKey = $BaseKey.OpenSubkey("SYSTEM\CurrentControlSet\Services\Tcpip\Parameters", $true)

        if ($TimeValue) {
            $SubKey.SetValue($KeyName, $TimeValue, [Microsoft.Win32.RegistryValueKind]::DWORD)
        }
        Else {
            $SubKey.SetValue($KeyName, $DefaultValue, [Microsoft.Win32.RegistryValueKind]::DWORD)
        }
    }

    Clear-Host
    Write-Host 'Each Server That Had Its TCP Keep Alive Time Value Changed Will Require A Reboot For The Changes To Take Affect.' -ForegroundColor Green
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Exit
}
else {
    Write-Host "PowerShell Version does not meet minimum requirements of at least 3.0, please update to at least PowerShell 3.0 and try again." -ForegroundColor Red
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Exit
}

Exit

