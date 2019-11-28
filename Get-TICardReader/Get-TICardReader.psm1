function Get-TICardReader {
    <#
    .SYNOPSIS
        Gets the TI card reader that corresponds to a given ComputerName from an Excel Sheet.
        Q:\ag-it\Medatixx x.vianova\Telematik Infrastruktur\Aufstellung Telematikinfrastruktur.xlsx
    .EXAMPLE
        Get-TICardReader -ComputerName localhost
        Get-TICardReader -CardReader SKT-MAN-ROD-TI01
        ...
    #>


    [cmdletbinding()]
    Param(
        [parameter(ParameterSetName="ComputerName", ValueFromPipelineByPropertyName)][string[]]$ComputerName,
        [parameter(ParameterSetName="CardReader", ValueFromPipelineByPropertyName)][string[]]$CardReader
    )

    

    BEGIN {
        $Output = [System.Collections.Generic.List[PSObject]]::New()

        #Get XLSX
        Import-Module -Name PSExcel
        TRY {
            $Data = Import-XLSX -Path "\\fil-zz-rz1-sv03\dfs\group\ag-it\Medatixx x.vianova\Telematik Infrastruktur\Aufstellung Telematikinfrastruktur.xlsx" -Sheet "RadCentre KT" -WarningAction SilentlyContinue | Select-Object -Property @{n="ComputerName";e={$_.PC}}, @{n="TI-Kartenleser"; e={$_.Name}}, "Konnektor", @{n="Konnektor-Management";e={("https://10.150.32." + $_.Konnektor.TrimStart("CTI-MAN-TI0") + ":8500/management")}}
        }
        CATCH {
            Write-Host "Failed to open specified excel sheet. Maybe the file is already being used."
            Write-Output $error[0]
        }
    }

    PROCESS {
        ForEach ($Computer in $ComputerName) {
            TRY {
                
                $Output.Add($Data -match $Computer)

            }
            CATCH {
                Write-Host "Error!"
                Write-Output $error[0]

            }
            FINALLY {

            }
        }
        ForEach ($Card in $CardReader) {
            TRY {
                
                $Output.Add($Data -match $Card)

            }
            CATCH {
                Write-Host "Error!"
                Write-Output $error[0]

            }
            FINALLY {

            }
        }
    }

    END {

        Write-Output -InputObject $Output
    }

}