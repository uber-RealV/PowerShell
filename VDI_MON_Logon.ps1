$VerbosePreference= "continue"

Write-Verbose "##########################################################################"
Write-Verbose "##  Script to launch:                                                   ##"
Write-Verbose "##      - Dynatrace                                                     ##"
Write-Verbose "##      - Chrome with the monitoring URL                                ##"
Write-Verbose "##  in kiosk mode on 2 seperate monitors if the user is [user]          ##"
Write-Verbose "##########################################################################`n`n`n"

Function LaunchChrome{
    $ChromeWebsite = "https://google.com" # Placeholder
    $ChromePath = "$chromelocationstring\chrome.exe" #Create logic here
    $ChromeParameters = "$ChromeWebsite --no-first-run --no-default-browser-check --no-service-autorun --oobe-skip-postlogin --disable-default-apps --no-network-profile-warning --window-position=$MonitorResX,0 -kiosk"
    Write-Verbose "Launching Google Chrome ..."
    start-process -filepath $ChromePath $Chromeparameters
}

 ## Get Monitor Resolution
Write-Verbose "Defining Monitor size ..."
$MonitorRes = Get-WmiObject win32_DesktopMonitor | Where-Object DeviceID -eq DesktopMonitor2
$MonitorResX = $MonitorRes.ScreenWidth
$MonitorResX++
Write-Verbose "Setting Monitor X Coordinate to $MonitorResX ..."

#Define the package
$Packages = get-appvclientpackage "Google-Chrome-*"

if (( $Packages -eq $null ) -or ( $Packages -eq "" )) {
    Write-Verbose "Syncing AppVPackages from server..."
    Sync-AppvPublishingServer 1
	$Packages = get-appvclientpackage "Google-Chrome-*"
	$Packagename = $Packages.name
    Write-Verbose "Sync Complete"
	Write-Verbose "Mounting $Packagename"
	Mount-AppvClientPackage "$Packagename"
    Write-Verbose "Re-starting Prereq check .."
	if (( $Packages -eq $null ) -or ($Packages -eq "")){
        Write-Verbose "ABORTED LAUNCH: Package not available"
	} else {
    	LaunchChrome    
    }	
} else {
    LaunchChrome
}
   
## JavaPath
$JavaPath = "C:\Program Files\Java\jre1.8.0_144\bin\javaws.exe"

## Launch Dynatrace
Write-Verbose "Launching DynaTrace ..."
start-process -filepath $JavaPath 'http://dynatraceprod:8020/webstart/Client/mode=kiosk/client.jnlp'