# Declare Script variables
$ErrorActionPreference = "SilentlyContinue"
$rootpath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$sourcepath = $rootpath + "\paths.csv"
$records = Import-Csv -Path $sourcepath
$ExcelPath = $rootpath + "\UPMprofiles.xlsx"
$ExcelPathExists = Test-Path $ExcelPath
$DateTime = get-date -format dd/MM/yy
$TitleName = "UPM Sizing $DateTime"
$Logfile = $rootpath + "\UPMCheck.log"

## Declare Excel Variables
$UPMCol = 1
$SizeCol = 2
$DateBGColor = 23
$DateFontColor = 2
$MAlertColor = 40
$HAThreshold = 500
$HAlertColor = 2
$MAThreshold = 350
$HBGAlertColor = 9
$TitleBGColor = 23
$TitleFontColor = 2
$MTitleBGColor = 49
$MTitleFontColor = 2

## Functions
# Function to Generate the Data for the ExcelFile
function PopulateFile {
    foreach ( $record in $records ) {
        $NetworkPathType = $record.Type
        $NetworkPath = $record.Path
        $ProfileNames = Get-ChildItem $NetworkPath
        LogWrite -LogLevel 2 "Getting Data for Sheet $NetworkPathType from $NetworkPath"
        foreach ($UPMProfile in $ProfileNames) {
            LogWrite -LogLevel 0 "Checking Profile $NetworkPath$UPMProfile"
            [double]$FolderSize = "{0:N2}" -f ((Get-ChildItem $NetworkPath$UPMProfile -Recurse -Force | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB)
            if (( $FolderSize -eq $null ) -or ( $FolderSize -eq "" )){
                LogWrite -LogLevel 2 "Settings FolderSize to 0 to avoid errors"
                [double]$FolderSize = 0
                CreateSheet
            } else {
                CreateSheet
            }
        }
    }
}
# Function to Write the data in the sheet
function WriteData {
    $excel.ActiveSheet.Range("A$c").Activate() | Out-Null
    $excel.cells.item($c,$UPMCol) = $UPMProfile
    $excel.Cells.Item($c,$UPMCol).Interior.ColorIndex = $DateBGColor
    $excel.Cells.Item($c,$UPMCol).Font.ColorIndex = $DateFontColor
    $excel.cells.item($c,$SizeCol) = $FolderSize
    if ($FolderSize -gt $HAThreshold) {
        $excel.cells.item($c,$SizeCol).Interior.ColorIndex = $HBGAlertColor
        $excel.Cells.Item($c,$SizeCol).Font.ColorIndex = $HAlertColor
    } elseif ($FolderSize -gt $MAThreshold) {
        $excel.cells.item($c,$SizeCol).Interior.ColorIndex = $MAlertColor
    }
    $c = 3
}
# Function to Create the table
function CreateTable {
    # Create the title
    LogWrite -LogLevel 0 "Creating Title Cells"
    $row = 1
    $Column = 1

    # Merging a few cells on the top row to make the title look nicer 
    $MergeCells = $XlsName.Range("A1:B1") 
    $MergeCells.Select() | Out-Null
    $MergeCells.MergeCells = $true
    $XlsName.Cells.Item(1,1).HorizontalAlignment = -4108
    $XlsName.Cells.Item(1,1).Font.Size = 12
    $XlsName.Cells.Item(1,1).Font.Bold =$True
    $XlsName.Cells.Item(1,1).Font.ColorIndex = $MTitleFontColor
    $XlsName.cells.item(1,1).Interior.ColorIndex = $MTitleBGColor
    
    # Create the column headers
    LogWrite -LogLevel 0 "Creating Column headers"
    $XlsName.Cells.Item(2,1) = 'UPMProfile'
    $XlsName.Cells.Item(2,1).Font.Bold=$True 
    $XlsName.Cells.Item(2,1).Font.ColorIndex = $TitleFontColor
    $XlsName.cells.item(2,1).Interior.ColorIndex = $TitleBGColor
    $XlsName.Cells.Item(2,2) = 'FolderSize'
    $XlsName.Cells.Item(2,2).Font.Bold=$True
    $XlsName.Cells.Item(2,2).Font.ColorIndex = $TitleFontColor
    $XlsName.cells.item(2,2).Interior.ColorIndex = $TitleBGColor
}
# Function to create a sheet
function CreateSheet {
    $SheetTitle = $NetworkPathType
    $WorkbookSheet = $workbook.Worksheets | Where-Object {$_.name -eq $SheetTitle}
    if ($WorkbookSheet.Name -eq $SheetTitle) {
        # Selecting Excisting Sheet
        $XlsName = $Excel.WorkSheets.item("$SheetTitle")
        $XlsName.activate() | Out-Null
        $XlsName.Cells.Item(1,1) = $TitleName

        # Checking Empy Cells
        $c = 3
        $Cellcheck = $XlsName.Cells.Item($c,1)
        $CellText = $Cellcheck.Text
        if (($CellText -ne $null) -or ($CellText -ne "")) {
            do {
                $c++
                $Cellcheck = $XlsName.Cells.Item($c,1)
                $CellText = $Cellcheck.Text
            } until ($CellText -eq "")
        }

        # Adding Data
        WriteData

        # Adjusting the column width so all data's properly visible 
        $usedRange = $XlsName.UsedRange 
        $usedRange.EntireColumn.AutoFit() | Out-Null

    } else {
        # Create the sheet
        LogWrite -LogLevel 0 "Settings Sheet Title"
        $DateTime = get-date -format HH:mm:ss-dd/MM/yy
        $sheet = $workbook.Worksheets.add()
        $sheet.name = "$SheetTitle"
        $XlsName = $Excel.WorkSheets.item("$SheetTitle")
        CreateTable
        $XlsName.Cells.Item(1,1) = $TitleName
        $c = 3

        # Adding Data
        LogWrite -LogLevel 0 "Writing Data to sheet"
        WriteData

        # Adjusting the column width so all data's properly visible 
        $usedRange = $XlsName.UsedRange 
        $usedRange.EntireColumn.AutoFit() | Out-Null
    }
}
# Logging the Script progress
Function LogWrite {
    Param (
        [string] $logstring,
        [int] $LogLevel = 0
    )
    
    New-Item $Logfile -type file -force | Out-Null
    
    switch ($LogLevel)
    {
        0 { $LogLevelString = "[INFORMATION..]" }
        1 { $LogLevelString = "[WARNING......]" }
        2 { $LogLevelString = "[ERROR........]" }
        default  { $LogLevelString = "[NOTSPECIFIED.]" }
    }

    Add-content $Logfile -value $LogLevelString + " " + $logstring
    if ($LogLevel -eq 0) { Write-Host "$LogLevelString $logstring" -ForegroundColor green }
    if ($LogLevel -eq 1) { Write-Host "$LogLevelString $logstring" -ForegroundColor Yellow }
    if ($LogLevel -eq 2) { Write-Host "$LogLevelString $logstring" -ForegroundColor Red }
    if (($LogLevel -ne 0) -and ($LogLevel -ne 1) -and ($LogLevel -ne 2)) { Write-Host "$LogLevelString $logstring" -ForegroundColor Gray }
}

## Start the Program
# Start Excel and open it
LogWrite "Starting the Script"
$excel = New-Object -ComObject excel.application
$excel.visible = $true
$excel.DisplayAlerts = $false

# Create the Workbook and remove unneeded sheets
if ($ExcelPathExists -eq $true) {
    LogWrite -LogLevel 0 "Found the file: $ExcelPath"
    $workbook = $excel.Workbooks.Open("$ExcelPath")

    PopulateFile
} else {
    LogWrite -LogLevel 1 "File not found"
    LogWrite -LogLevel 0 "Creating new file: $ExcelPath"
    $workbook = $excel.Workbooks.Add()
    $workbook.Worksheets.Item(3).Delete() | Out-Null
    $workbook.Worksheets.Item(2).Delete() | Out-Null
    
    # Rename the remaining sheet
    $XlsName = $workbook.Worksheets.Item(1)
    $XlsName.Name = "Summary"

    CreateTable
    PopulateFile
    
    if ($XlsName.Name -eq "Summary") {
        $workbook.Worksheets.Item(1).Delete() | Out-Null
    }
}

# Saving & closing the file
LogWrite -LogLevel 0 "Saving the ExcelFile"
$workbook.SaveAs($ExcelPath) | Out-Null
$workbook.Close() | Out-Null
$excel.Quit() | Out-Null