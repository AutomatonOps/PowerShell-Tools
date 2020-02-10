function Remove-UserPrinter {
    <#
    .SYNOPSIS
        Removes a list of printers installed for a specIfic user (printers only available to a specIfic user)
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Remove-UserPrinter -ComputerName localhost -UserName User01 -PrinterName \\PRINTSERVER.FQDN\PRINTER
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ComputerName')][string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'PSSession', Mandatory = $true)][System.Management.Automation.Runspaces.PSSession[]]$Session,

        [parameter(ValueFromPipelineByPropertyName, Mandatory = $true)][string[]]$UserName,
        [parameter(ValueFromPipelineByPropertyName, Mandatory = $true)][string[]]$PrinterName,
        [switch]$Force
    )


    process {
        if ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
            foreach ($Computer in $ComputerName) {
                try {
                    $ScriptBlock = {
                        if ($Using:Force) {
                            Stop-Service -Name "Spooler" -Force
                        }

                        foreach ($User in $Using:UserName) {
                            if ($User.Contains("\")) {
                                $User = $User.Split("\")[1]
                            }
                            try {
                                $SID = (New-Object System.Security.Principal.NTAccount($User)).Translate([System.Security.Principal.SecurityIdentIfier]).Value
                            }
                            catch [System.Management.Automation.MethodInvocationException] {
                                # *Suppressing errors If a UserName can not be found in AD
                                $SID = $User
                            } 

                            foreach ($Printer in $Using:PrinterName) {
                                $Printer_ = $Printer.Replace("\", ",")
                                $Server_ = $Printer_.Trim(",").Split(",")[0]
                                $PrinterString = $Printer_.Trim(",").Split(",")[1]
                
                                Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\$SID\Printers\Connections\$Printer_" -ErrorAction SilentlyContinue | Remove-Item 
                                Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\$Server_\Monitors\Client Side Port\" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.PrinterPath -like "*$PrinterString*" } | Remove-Item 
                                Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\$Server_\Printers\" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.Description -like "*$PrinterString*" } | Remove-Item -Recurse 
                                Get-Item -Path "Registry::\HKEY_USERS\$SID\Printers\Connections\$Printer_" -ErrorAction SilentlyContinue | Remove-Item 
                                Get-ItemProperty -Path "Registry::\HKEY_USERS\$SID\Printers\Settings\" -Name $Printer -ErrorAction SilentlyContinue | Remove-Item -Recurse         
                            }
                        }

                        if ($Using:Force) {
                            Start-Service -Name "Spooler"
                        }
                    }


                    if ($PSCmdlet.ShouldProcess($Computer, "Remove User Printer $PrinterName")) {
                        Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock
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
                        if ($Using:Force) {
                            Stop-Service -Name "Spooler" -Force
                        }

                        foreach ($User in $Using:UserName) {
                            if ($User.Contains("\")) {
                                $User = $User.Split("\")[1]
                            }
                            try {
                                $SID = (New-Object System.Security.Principal.NTAccount($User)).Translate([System.Security.Principal.SecurityIdentIfier]).Value
                            }
                            catch [System.Management.Automation.MethodInvocationException] {
                                # *Suppressing errors If a UserName can not be found in AD
                                $SID = $User
                            } 

                            foreach ($Printer in $Using:PrinterName) {
                                $Printer_ = $Printer.Replace("\", ",")
                                $Server_ = $Printer_.Trim(",").Split(",")[0]
                                $PrinterString = $Printer_.Trim(",").Split(",")[1]
                
                                Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\$SID\Printers\Connections\$Printer_" -ErrorAction SilentlyContinue | Remove-Item 
                                Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\$Server_\Monitors\Client Side Port\" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.PrinterPath -like "*$PrinterString*" } | Remove-Item 
                                Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\$Server_\Printers\" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.Description -like "*$PrinterString*" } | Remove-Item -Recurse 
                                Get-Item -Path "Registry::\HKEY_USERS\$SID\Printers\Connections\$Printer_" -ErrorAction SilentlyContinue | Remove-Item 
                                Get-ItemProperty -Path "Registry::\HKEY_USERS\$SID\Printers\Settings\" -Name $Printer -ErrorAction SilentlyContinue | Remove-Item -Recurse         
                            }
                        }

                        if ($Using:Force) {
                            Start-Service -Name "Spooler"
                        }
                    }


                    if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Remove User Printer $PrinterName ")) {
                        Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock
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
            if ($PSCmdlet.ShouldProcess($ComputerName, "Get User Printer")) {
                Get-UserPrinter -ComputerName $ComputerName
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Get User Printer")) {
                Get-UserPrinter -Session $Session
            }
        }
    }
}