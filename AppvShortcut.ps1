## Define Parameters


## Define Variables
$AppvPath = "C:\Temp\AppV\"
$Packages = Get-ChildItem $AppvPath -Exclude "_Backup"
$AppvPathExists = Test-Path $AppvPath
$LogPath = "C:\Temp\AppV\_Backup\"
$LogFile = $LogPath + "AppvShortcuts.log"
$BackupPath = $LogPath

## Functions
Function AppvSync {
    Import-Module Appvserver
    $packageID = $Config.DeploymentConfiguration.PackageId
    Set-AppvServerPackage -PackageID $packageID -DynamicDeploymentConfigurationPath $ConfigFile
}
Function LogWrite {
    Param (
        [string] $LogString,
        [int] $LogLevel = 0
    )

    New-Item $Logfile -tipe file -Force | Out-Null

    switch ( $LogLevel ) {
        0 { $LogLevelString = "[Information].." }
        1 { $LogLevelString = "[Warning]......" }
        2 { $LogLevelString = "[Error]........" }
        default { $LogLevelString = "[Not Specified].." }
    }
    Add-Content $Logfile -value $LogLevelString + " " + $LogString

    if ($LogLevel -eq 0 ) { Write-Host "$LogLevelString $LogString" -ForegroundColor Green }
    if ($LogLevel -eq 1 ) { Write-Host "$LogLevelString $LogString" -ForegroundColor Yellow }
    if ($LogLevel -eq 2 ) { Write-Host "$LogLevelString $LogString" -ForegroundColor Red }
    if (($LogLevel -ne 0 ) -and ($LogLevel -eq 1 ) -and ($LogLevel -eq 2 ))  { Write-Host "$LogLevelString $LogString" -ForegroundColor Gray }
}

## Start Application
# Check if the backup Path is available and create if needbe
if ( (Test-Path "$BackupPath") -eq $false ) {
    Write-Host "[ $BackupPath ] does not Exists : Creating" -ForegroundColor Red
    New-Item $BackupPath -type directory | Out-Null
    if ( (Test-Path "$BackupPath") -eq $true ) {
        Write-Host "[ $BackupPath ] Created" -ForegroundColor Green
    } else  {
        Write-Host "No backup path and insuficient permissions to create it" -ForegroundColor Red
        exit   
    }
} else {
    Write-Host "[ $BackupPath ] Exists" -ForegroundColor Green
}
# Roll through each package directory and identify the DeploymentConfig.xml
foreach ( $Package in $Packages ) {
    $DeploymentConfig = Get-ChildItem $Package -File *DeploymentConfig.xml
    $ConfigFile = "$Package\$DeploymentConfig"
    # Read the xml file
    [xml]$Config = Get-Content $ConfigFile
    $Shortcuts = $Config.DeploymentConfiguration.UserConfiguration.Subsystems.Shortcuts
    $ShortcutSetting = $Config.DeploymentConfiguration.UserConfiguration.Subsystems.Shortcuts.Enabled
    
    # Check if the Shortcut settings is enabled
    if ( $ShortcutSetting -eq "true" ) {
        # Create a backup of the file
        Copy-Item $ConfigFile $BackupPath -Force
        Write-Host "Backed up original file in [ $BackupPath ]" -ForegroundColor Cyan
        # Modify the settings
        #$Shortcuts.Enabled = "false"
        
        # Saving the XML file
        $Config.Save("$ConfigFile")
        AppvSync
    } else {
        Write-Host "Skipped $Package" -ForegroundColor Red
    }
}