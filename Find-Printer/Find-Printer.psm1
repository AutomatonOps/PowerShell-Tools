function Find-Printer
{
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

    BEGIN {
        $Job = Start-Job { Import-Csv \\ATM-IT-RZ1-SV01\AUTOMATION\Jobs\PrinterCollector\PrinterList.csv }
        $Output = @()
        $Result = $Job | Receive-Job -Wait -AutoRemoveJob
    }
    
    PROCESS {   
        ForEach($Printer in $PrinterName) {
            TRY {
                $Output = $Result | Where-Object { $_.Name -like "*$Printer*" }
            }
            CATCH {
                Write-Verbose "Error! ${$_.Exception.Message}"
                $Properties = @{
                    PrinterName = $null
                    DriverName = $null
                    Location = $null
                    ComputerName = $null
                }
                $Output = New-Object PSObject -Property $Properties
            }
            FINALLY {
                foreach($o in $Output) {
                    if($o.ComputerName -eq "PRS-FK-RFK-SV01") {
                        Write-Output -InputObject $o | Select-Object @{n="PrinterName";e={"\\" + $_.ComputerName + ".FACHKLINIK.NET.LOCAL\" + $_.Name}}, DriverName, Location
                    }
                    else {
                        Write-Output -InputObject $o | Select-Object @{n="PrinterName";e={"\\" + $_.ComputerName + ".RNR.NET.LOCAL\" + $_.Name}}, DriverName, Location
                    }
                }
                
            }
        }
    }

    END {

    }
}



