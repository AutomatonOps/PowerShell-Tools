function Add-MachinePrinter {
    <#
    .SYNOPSIS
        Sends an e-mail with errors you provide a to facilitate easy troubleshooting
    .EXAMPLE
        Send-ErrorMail -To PowerShellAdmin@company.com -From PowerShellErrorLogging@company.com -Subject Scriptname_Hostname -Body $error
    #>


    Param(
        [string[]]$ComputerName = "localhost",
        [parameter(Mandatory)][string[]]$PrinterName,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    foreach($Computer in $ComputerName) {
        try {
                Test-Connection -ComputerName $Computer -Count 1 -Quiet -InformationAction Ignore -ErrorAction Stop | Out-Null
                    foreach($Printer in $PrinterName) {
                        if ($PSCmdlet.ShouldProcess("$Computer", "Add Machine Printer $PrinterName")) {
                            Invoke-Command -ComputerName $Computer `
                                            -ErrorVariable $eInvokeCommand `
                                            -ArgumentList $Printer `
                                            -Credential $Credential `
                                            -ScriptBlock {rundll32 printui,PrintUIEntry /ga /n$args
                        }
                    }
            }
        }
        catch {
            Write-Warning -Message "Konnte nicht mit $Computer verbinden."
        }
    }


}