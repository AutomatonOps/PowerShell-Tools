function Find-Printer {
    <#
    .SYNOPSIS
        Searches the PrinterList.csv for a given printer

    .DESCRIPTION
        Gives a bunch of info on a given printer

    .PARAMETER PrinterName
        One or more PrinterNames

    .EXAMPLE
        PS C:\> Find-Printer printer01
        Finds out a bunch of info about printer01

    .EXAMPLE
        PS C:\> Find-Printer printer01, printer02, printer03
#>

    [CmdletBinding()]
    param
    (
        [parameter(ValueFromPipelineByPropertyName)][string[]]$PrinterName
    )

    begin {
        $List = Import-Csv -Path '\\ATM-IT-RZ1-SV01\AUTOMATION\Jobs\PrinterCollector\PrinterList.csv'
    }
    
    process {
        foreach ($Printer in $PrinterName) {
            $Result = $List | Where-Object { $_.Name -like "*$Printer*" }

            foreach ($r in $Result) {
                if ($r.ComputerName -eq "PRS-FK-RFK-SV01") {
                    Write-Output -InputObject $r | Select-Object @{n = "PrinterName"; e = { "\\" + $_.ComputerName + ".FACHKLINIK.NET.LOCAL\" + $_.Name } }, DriverName, Location
                }
                else {
                    Write-Output -InputObject $r | Select-Object @{n = "PrinterName"; e = { "\\" + $_.ComputerName + ".RNR.NET.LOCAL\" + $_.Name } }, DriverName, Location
                }
            }
        }
    }
}



