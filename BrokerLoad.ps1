##############################
#.SYNOPSIS
#
#
#.DESCRIPTION
#Long description
#
#.PARAMETER LogString
#Parameter description
#
#.PARAMETER LogLevel
#Parameter description
#
#.EXAMPLE
#An example
#
#.NOTES
#General notes
##############################
## Variables
$Broker = #Adminbroker
$RootPath =
$Logfile =
$MaxThreshold = 
$MinThreshold = 

## Functions
Function LogWrite {
    Param (
        [string] $LogString,
        [int] $LogLevel = 0
    )

    New-Item $Logfile -type file -Force | Out-Null

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

Function LoadCheck {
    foreach ($VDAMachine in $DeliveryGroup){
        $Load += $Brokermachines.LoadIndex
    }
    $AverageLoad = $Load / 2
}

Function ScaleIn {
    # Put Machines in maintenance
}
Function ScaleOut {
    # Boot machines
}
## Program Start

LoadCheck

If ($AverageLoad -ge $MaxThreshold) {
    # ScaleOut
} Elseif ($AverageLoad -le $MinThreshold) {
    # ScaleIn
} Else {
    # Take no action and report
}