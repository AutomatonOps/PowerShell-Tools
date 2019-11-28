function Remove-UserPrinter {
    <#
    .SYNOPSIS
        Removes a list of printers installed for a specific user (printers only available to a specific user)
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Remove-UserPrinter -ComputerName localhost -UserName User01 -PrinterName \\PRINTSERVER.FQDN\PRINTER
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = "localhost",

        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string[]]$UserName,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string[]]$PrinterName,

        [switch]$Force,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        $Result = @()
    }

    process {
        foreach ($Computer in $ComputerName) {
            try {
                Test-Connection -ComputerName $Computer -Count 1 -Quiet -InformationAction Ignore -ErrorAction Stop | Out-Null

                if ($PSCmdlet.ShouldProcess("$Computer", "Import Registry Hive")) {
                    Import-RegistryHive -ComputerName $Computer
                }




                foreach ($User in $UserName) {
                    if ($User.Contains("\")) {
                        $User = $User.Split("\")[1]
                    }
                    try {
                        $SID = Get-ADUser -Identity $User | Select-Object -ExpandProperty SID
                    }
                    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                        #...Suppressing errors if a SID can not be found in AD
                        $SID = $User
                    }

                    if ($Force) {
                        Invoke-Command -ComputerName $Computer -ScriptBlock { Stop-Service -Name "Spooler" -Force }
                    }


                    foreach ($Printer in $PrinterName) {
                        if ($PSCmdlet.ShouldProcess("$Computer", "Remove User Printer $Printer for $User")) {
                            #$Server = $Printer.Trim("\").Split("\")[0]
                            $Printer_ = $Printer.Replace("\", ",")
                            $Server_ = $Printer_.Trim(",").Split(",")[0]
                            $PrinterString = $Printer_.Trim(",").Split(",")[1]

                            Invoke-Command -ComputerName $Computer `
                                -ScriptBlock { 
                                Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\$Using:SID\Printers\Connections\$Using:Printer_" -ErrorAction SilentlyContinue | Remove-Item 
                                Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\$Using:Server_\Monitors\Client Side Port\" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.PrinterPath -like "*$Using:PrinterString*" } | Remove-Item 
                                Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\$Using:Server_\Printers\" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.Description -like "*$Using:PrinterString*" } | Remove-Item -Recurse 
                                Get-Item -Path "Registry::\HKEY_USERS\$Using:SID\Printers\Connections\$Using:Printer_" -ErrorAction SilentlyContinue | Remove-Item 
                                Get-ItemProperty -Path "Registry::\HKEY_USERS\$Using:SID\Printers\Settings\" -Name $Using:Printer -ErrorAction SilentlyContinue | Remove-Item -Recurse 
                            }
                        }

                    }

                    if ($Force) {
                        Invoke-Command -ComputerName $Computer -ScriptBlock { Start-Service -Name "Spooler" }
                    }
                }


                if ($PSCmdlet.ShouldProcess("$Computer", "Get User Printer")) {
                    $Result += Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock -AsJob -HideComputerName
                }                        



                #Make sure to release the ntuser.dats from the registry again!
                if ($PSCmdlet.ShouldProcess("$Computer", "Export Registry Hive")) {
                    Export-RegistryHive -ComputerName $Computer
                }
            }
            catch {
                Write-Warning -Message "Konnte nicht mit $Computer verbinden."
            }
        }
    }


}