function Remove-MachinePrinter {
    <#
    .SYNOPSIS
        Removes a list of all printers installing them under HKEY_LOCAL_MACHINE (printers available to any user logged on to the machine).
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Remove-MachinePrinter -ComputerName localhost -PrinterName \\PRINTSERVER.FQDN\PRINTER
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ComputerName')][string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'PSSession', Mandatory = $true)][System.Management.Automation.Runspaces.PSSession[]]$Session,

        [parameter(ValueFromPipelineByPropertyName, Mandatory = $true)][string[]]$PrinterName
    )


    process {
        if ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
            foreach ($Computer in $ComputerName) {
                try {
                    foreach ($Printer in $PrinterName) {
                        $ScriptBlock = {
                            Start-Process -FilePath rundll32.exe -ArgumentList "printui,PrintUIEntry /q /gd /n$Using:Printer" -Wait
                        }
                        if ($PSCmdlet.ShouldProcess($Computer, "Remove Machine Printer $Printer")) {
                            Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock
                        }
                    }
                }
                catch {
                    $error[0].InvocationInfo | Select-Object *
                    $error[0].Exception.Message
                }
            }
        }
        else {
            foreach ($PSSession in $Session) {
                try {
                    foreach ($Printer in $PrinterName) {
                        $ScriptBlock = {
                            Start-Process -FilePath rundll32.exe -ArgumentList "printui,PrintUIEntry /q /gd /n$Using:Printer" -Wait
                        }
                        if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Remove Machine Printer $Printer")) {
                            Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock
                        }
                    }
                }
                catch {
                    $error[0].InvocationInfo | Select-Object *
                    $error[0].Exception.Message
                }
            }
        }
    }
    end {
        if ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
            if ($PSCmdlet.ShouldProcess($ComputerName, "Get Machine Printer")) {
                Get-MachinePrinter -ComputerName $ComputerName
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Get Machine Printer")) {
                Get-MachinePrinter -Session $Session
            }
        }
    }
}