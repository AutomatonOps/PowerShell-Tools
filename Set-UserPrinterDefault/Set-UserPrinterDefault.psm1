function Set-UserPrinterDefault {
    <#
    .SYNOPSIS
        Sets a given printer to be the default on a given computer for a given user.
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Set-UserPrinterDefault -ComputerName localhost -UserName user01 -PrinterName \\PRINTSERVER.FQDN\PRINTER
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$PrinterName,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string[]]$UserName
    )
    
    process {
        foreach($Computer in $ComputerName) {
            try {
                    Test-Connection -ComputerName $Computer -Count 1 -Quiet -InformationAction Ignore -ErrorAction Stop | Out-Null
                        foreach($User in $UserName) {
                            $SID = Get-ADUser -Identity $User | Select-Object -ExpandProperty SID | Select-Object -ExpandProperty Value
                            if ($PSCmdlet.ShouldProcess("$Computer", "Set default printer $PrinterName for user $User")) {
                                Invoke-Command -ComputerName $Computer `
                                                -ScriptBlock {
                                                    #Get-ItemProperty -Path "Registry::\HKEY_USERS\$Using:SID\Software\Microsoft\Windows NT\CurrentVersion\Windows\" -Name "Device" | Select-Object -ExpandProperty Device
                                                    Set-ItemProperty -Path "Registry::\HKEY_USERS\$Using:SID\Software\Microsoft\Windows NT\CurrentVersion\Windows" -Name "Device" -Value "$Using:PrinterName,winspool,Ne00:"
                                                    #Get-ItemProperty -Path "Registry::\HKEY_USERS\$Using:SID\Software\Microsoft\Windows NT\CurrentVersion\Windows\" -Name "Device" | Select-Object -ExpandProperty Device
                                                } | Out-Null
                            }
                                # [PSCustomObject]@{
                                #     ComputerName = $Computer
                                #     UserName = $User
                                #     OldDefaultPrinter = $Result[0]
                                #     NewDefaultPrinter = $Result[1]
                                # }
                                
                        }
            }
            catch {
                Write-Warning -Message "Konnte nicht mit $Computer verbinden."
            }
        }
    }

}