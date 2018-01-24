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
    Add-Content -Path $LogFile -value $LogLevelString + " " + $LogString

    if ($LogLevel -eq 0 ) { Write-Host "$LogLevelString $LogString" -ForegroundColor Green }
    if ($LogLevel -eq 1 ) { Write-Host "$LogLevelString $LogString" -ForegroundColor Yellow }
    if ($LogLevel -eq 2 ) { Write-Host "$LogLevelString $LogString" -ForegroundColor Red }
    if (($LogLevel -ne 0 ) -and ($LogLevel -eq 1 ) -and ($LogLevel -eq 2 ))  { Write-Host "$LogLevelString $LogString" -ForegroundColor Gray }
}

## Start Application
# Check if the backup Path is available and create if needbe
if ( $AppvPathExists -eq $false ) {
    LogWrite $LogLevel 2 -LogString "The Specified path [ $AppvPath ] does not exist, Exiting Script"
    exit
}

if ( (Test-Path "$BackupPath") -eq $false ) {
    LogWrite $LogLevel 1 -LogString "[ $BackupPath ] does not Exists : Creating"
    New-Item $BackupPath -type directory | Out-Null
    if ( (Test-Path "$BackupPath") -eq $true ) {
        LogWrite $LogLevel 0 -LogString "[ $BackupPath ] Created"
    } else  {
        LogWrite $LogLevel 2 -LogString "No backup path and insuficient permissions to create it, Exiting Script"
        exit   
    }
} else {
    LogWrite $LogLevel 0 -LogString "[ $BackupPath ] Exists"
}
# Roll through each package directory and identify the DeploymentConfig.xml
foreach ( $Package in $Packages ) {
    $DeploymentConfig = Get-ChildItem $Package -File *DeploymentConfig.xml
    $ConfigFile = "$Package\$DeploymentConfig"
    # Read the xml file
    [xml]$Config = Get-Content $ConfigFile
    $ShortcutSetting = $Config.DeploymentConfiguration.UserConfiguration.Subsystems.Shortcuts.Enabled
    
    # Check if the Shortcut settings is enabled
    if ( $ShortcutSetting -eq "true" ) {
        # Create a backup of the file
        Copy-Item $ConfigFile $BackupPath -Force
        LogWrite $LogLevel 0 -LogString "Backed up original file in [ $BackupPath ]"
        # Modify the settings
        $Shortcuts.Enabled = "false"
        LogWrite $LogLevel 0 -LogString "Disabled shortcut for $Package"
        # Saving the XML file
        $Config.Save("$ConfigFile")
        AppvSync
    } else {
        LogWrite $LogLevel 2 -LogString "Skipped $Package, setting already false"
    }
}