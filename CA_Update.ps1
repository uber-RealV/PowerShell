##
#   Script automating the installation of the belgiumrCA root certificates
#   Author: Franz Kerremans
##

$ErrorActionPreference = "Silentlycontinue"

## Set Script Variables
$URL = "http://certs.eid.belgium.be/"
$WebContent = Invoke-WebRequest -Uri $URL
$RootPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

## Start the Program
ForEach ( $Item in $WebContent.Links ) {
    If ( $Item.href -like "belgiumrca*" ) {
        # Set Loop ariables
        $CAName = $Item.href
        $DL_Link = $URL+$CAName

        # Download the crt files
        Invoke-WebRequest "$DL_Link" -OutFile "$RootPath\$CAName"

        # Install the Certificates
        certutil.exe -addstore Root "$RootPath\$CAName" | Out-Null

        # Cleanup the files
        Remove-Item "$RootPath\$CAName" -Force
    } 
}