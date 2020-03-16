function Add-MachinePrinter {
    <#
    .SYNOPSIS
        Adds a list of all printers installing them under HKEY_LOCAL_MACHINE (printers available to any user logged on to the machine).
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Add-MachinePrinter -ComputerName localhost -PrinterName \\PRINTSERVER.FQDN\PRINTER
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
                    $ScriptBlock = {
                        $version = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption
                        if ($version -like '*Windows 10*') {
                            #* Disable metadata download from internet to make the printer show up instantly
                            if (!(Test-Path -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata')) {
                                New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata\'
                            }
                            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata\' -PSProperty PreventDeviceMetadataFromNetwork -Value 1 -Force #* 1 == disable metadata downloading
                            #Get-Service -Name Spooler | Restart-Service -Force
                        }
                    }
                    Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock

                    foreach ($Printer in $PrinterName) {
                        $ScriptBlock = {
                            Start-Process -FilePath rundll32.exe -ArgumentList "printui,PrintUIEntry /q /ga /n$Using:Printer" -Wait
                        }
                        if ($PSCmdlet.ShouldProcess($Computer, "Add Machine Printer $Printer")) {
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
                    $ScriptBlock = {
                        $version = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption
                        if ($version -like '*Windows 10*') {
                            #* Disable metadata download from internet to make the printer show up instantly
                            if (!(Test-Path -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata')) {
                                New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata\'
                            }
                            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata\' -PSProperty PreventDeviceMetadataFromNetwork -Value 1 -Force #* 1 == disable metadata downloading
                            #Get-Service -Name Spooler | Restart-Service -Force
                        }
                    }
                    Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock

                    foreach ($Printer in $PrinterName) {
                        $ScriptBlock = {
                            Start-Process -FilePath rundll32.exe -ArgumentList "printui,PrintUIEntry /q /ga /n$Using:Printer" -Wait
                        }
                        if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Add Machine Printer $Printer")) {
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
                # Invoke-Command -ComputerName $Computer -ScriptBlock {
                #     Get-Service -Name Spooler | Restart-Service -Force
                # }  
                # $ScriptBlock = {
                #     $version = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption
                #     if ($version -like '*Windows 10*') {
                #         Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata\' -PSProperty PreventDeviceMetadataFromNetwork -Value 0 -Force #* 0 == enable metadata downloading
                #         #Get-Service -Name Spooler | Restart-Service -Force
                #     }
                # }
                # Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Get Machine Printer")) {
                Get-MachinePrinter -Session $Session
                # Invoke-Command -Session $Session -ScriptBlock {
                #     Get-Service -Name Spooler | Restart-Service -Force
                # }
                # $ScriptBlock = {
                #     $version = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption
                #     if ($version -like '*Windows 10*') {
                #         Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata\' -PSProperty PreventDeviceMetadataFromNetwork -Value 0 -Force #* 0 == enable metadata downloading
                #         #Get-Service -Name Spooler | Restart-Service -Force
                #     }
                # }
                # Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock

            }
        }
    }
}
