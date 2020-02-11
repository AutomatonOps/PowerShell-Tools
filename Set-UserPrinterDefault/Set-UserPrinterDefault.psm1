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
        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ComputerName')][string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'PSSession', Mandatory = $true)][System.Management.Automation.Runspaces.PSSession[]]$Session,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$PrinterName,
        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string[]]$UserName
    )
    
    
    process {
        if ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
            foreach($Computer in $ComputerName) {
                try {
                    foreach($User in $UserName) {
                        $SID = Get-ADUser -Identity $User | Select-Object -ExpandProperty SID | Select-Object -ExpandProperty Value
                        $ScriptBlock = {
                            Set-ItemProperty -Path "Registry::\HKEY_USERS\$Using:SID\Software\Microsoft\Windows NT\CurrentVersion\Windows" -Name "Device" -Value "$Using:PrinterName,winspool,Ne00:"
                        }
                        if ($PSCmdlet.ShouldProcess($Computer, "Set Default Printer $PrinterName for user $User")) {
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
            foreach($PSSession in $Session) {
                try {
                    foreach($User in $UserName) {
                        $SID = Get-ADUser -Identity $User | Select-Object -ExpandProperty SID | Select-Object -ExpandProperty Value
                        $ScriptBlock = {
                            Set-ItemProperty -Path "Registry::\HKEY_USERS\$Using:SID\Software\Microsoft\Windows NT\CurrentVersion\Windows" -Name "Device" -Value "$Using:PrinterName,winspool,Ne00:"
                        }
                        if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Set Default Printer $PrinterName for user $User")) {
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
            if ($PSCmdlet.ShouldProcess($ComputerName, "Get Default Printer")) {
                Get-UserPrinterDefault -ComputerName $ComputerName
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Get Default Printer")) {
                Get-UserPrinterDefault -Session $Session
            }
        }
    }
}