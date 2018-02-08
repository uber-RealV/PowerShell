$ErrorActionPreference = 'SilentlyContinue'

## Declare Variables
$MachinePool = Get-BrokerDesktop # Filter output
$MachinePoolCount = Get-BrokerDesktop | measure-object # filter
$MachinePoolUpCount = $MachinePoolCount
$TartgetValue = ($MachinePoolCount * 0.2)
$LogFile = 
$UserThreshold = 2

## Functions
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

## Pre-reqs check
Add-PSSnapin Citrix*
$BrokerConnectionCheck = #check if the broker is online
if ($BrokerConnectionCheck -eq 'offline') {
    Exit
}

## Program
foreach ($XAServer in $MachinePool){
    if ($XAServer.InMaintenanceMode -eq $true) {
        LogWrite -loglevel 0 "Server "$XAServer.HostedMachineName" is already in Mainteance-mode" -ForegroundColor Red
        LogWrite -loglevel 0 "Checking for user sessions" -ForegroundColor Green
        
        $LoggedInUsers = Get-Brokersession -machinename $XAServer.HostedMachineName | Measure-Object
        
        if ($LoggedInUsers -eq 0) {
            LogWrite -loglevel 0 "shutting down the machine"
            ## Shutdown machine
            Exit
        } elseif ($LoggedInUsers -le $UserThreshold) {
            ## DEFINE ACTIONS FOR WHEN THE MACHINE IS NOT IN MAINTENANCE, HOW ARE WE GOING TO REDUCE THE SESSIONS
        }

    } else {
        LogWrite -loglevel 0 "Server "$XAServer.HostedMachineName" is not in Mainteance-mode" -ForegroundColor Red
    }
}
    } else {
        LogWrite -loglevel 0 "Server "$XAServer.HostedMachineName" is not in Mainteance-mode" -ForegroundColor Red
    }
}