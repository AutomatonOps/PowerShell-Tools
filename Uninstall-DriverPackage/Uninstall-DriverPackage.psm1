function Uninstall-DriverPackage {
    <#
    .SYNOPSIS
        Uninstalls a list of printer driver packages from a given (list) of Computers.
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Uninstall-DriverPackage -ComputerName localhost,PC01 -DriverPackage "Xerox Phaser 3320", "Brother"
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [string[]]$ComputerName = "localhost",
        [parameter(Mandatory)][string[]]$DriverPackage,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    foreach($Computer in $ComputerName) {
        try {
                Test-Connection -ComputerName $Computer -Count 1 -Quiet -InformationAction Ignore -ErrorAction Stop | Out-Null
                    foreach($Driver in $DriverPackage) {
                        if ($PSCmdlet.ShouldProcess("$Computer", "Remove driver package $Driver")) {
                            Invoke-Command -ComputerName $Computer `
                                            -ArgumentList $Driver `
                                            -Credential $Credential `
                                            -ScriptBlock {rundll32 printui,PrintUIEntry /dd /m $args} | Out-Null
                        }
                    }
        }
        catch {
            Write-Warning -Message "Konnte nicht mit $Computer verbinden."
        }
    }


}