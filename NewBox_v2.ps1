#Check if we are in an elevated session.  If not, spawn an elevated session.
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $PSCommandPath) -Verb RunAs
  Break

}

function Get-TimeStamp {
    return Get-Date -Format HH:mm:ss
}

function Install-Package {
    param(
        [string]$installer
    )

    #Write-Host -nonewline "Installing $installer ... "
    choco install $installer -yr --no-progress > C:\ProgramData\chocolatey\logs\choco_install.log
    #Write-Host "Done"

}

#setting counter for progress bar
$counter = 0

#get a timestamp since we're now actually doing stuff.
$launch = Get-TimeStamp

#import current software inventory
$software = Import-Csv -Path "$PSscriptRoot\software.csv"

#adding one to inventory count to account for Chocolatey
$packagecount = $software.Count + 1

Write-progress -Activity 'Installing base packages' -Status 'Installing Chocolatey' -PercentComplete (($counter/$packagecount)*100)
#Check if Choco is installed.  If not, do so.
$testchoco = powershell choco -v
if(-not($testchoco)){
    Write-Host "Installing Chocolatey"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    $counter++
}
else{
    Write-Host "Chocolatey Version $testchoco is already installed"
    $counter++
    
    #since Choclatey is already installed, lets get a list of anything else installed
    $installedpackages = choco list -lo
}

FOREACH ($package in $software) {
    #Write-host $package.name
    #check if this package is currently installed.  Explicitly setting false so that a failure results in a reinstall.  This ensures that the package is installed at the end of the run.
    $installed = $false

    #$installedpackages will be NULL if chocolatey was not installed prior to start.  If $installedpackages is NOT NULL, then we'll cycle through it looking for our current package.
    FOREACH ($title in $installedpackages){
        IF ($title -like ($package.name + "*")) {
            #Setting explicit true because we found a match.
            $installed = $true
            write-host -NoNewline $package.name 
            Write-host " is already installed"
        }
    }
    
    #If $installed is still FALSE, then we install the package, update the progress bar, and move to the next package.
    #If $installed is now TRUE, then we update the progress bar, and move to the next package.

    IF ($installed -eq $false) {
        Write-progress -Activity 'Installing base packages' -Status "Installing $($package.name)" -PercentComplete (($counter/$packagecount)*100)
        Install-Package $package.name
        $counter ++        
    } else {
        $counter ++
        Write-progress -Activity 'Installing base packages' -Status "Installing $($package.name)" -PercentComplete (($counter/$packagecount)*100)
    }

}

#Add desktop shortcut to SysInternals
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\SysInternals.lnk")
$Shortcut.TargetPath = "C:\ProgramData\chocolatey\bin"
$Shortcut.Save()

#Add run-as-admin shortcut to CMD
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\CMD.lnk")
$Shortcut.TargetPath = "%windir%\system32\cmd.exe"
$Shortcut.Save()
$bytes = [System.IO.File]::ReadAllBytes("$Home\Desktop\CMD.lnk")
$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
[System.IO.File]::WriteAllBytes("$Home\Desktop\CMD.lnk", $bytes)

$complete = Get-TimeStamp

$elapsedtime = New-TimeSpan -Start $launch -End $complete

Write-Host "Build complete.  Elapsed Time:  $elapsedtime"
Write-Host "Press [Enter] to continue.  The machine WILL reboot."
pause

Restart-Computer