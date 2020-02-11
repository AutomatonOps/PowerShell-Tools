function Get-MachinePrinter {
    <#
    .SYNOPSIS
        Gets a list of all printers installed under HKEY_LOCAL_MACHINE (printers available to any user logged on to the machine).
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Get-MachinePrinter -ComputerName localhost
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ComputerName')][string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'PSSession', Mandatory = $true)][System.Management.Automation.Runspaces.PSSession[]]$Session
    )

    
    process {
        $ScriptBlock = {
            Get-ChildItem -Path 'Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections' |
                ForEach-Object -Process {
                    $PrinterName = $_ |
                        Get-ItemProperty -Name Printer |
                            Select-Object -ExpandProperty Printer

                    $Properties = @{
                        ComputerName = $env:ComputerName
                        UserName     = "Machine"
                        PrinterName  = $PrinterName
                        Type         = "Machine"
                        Status       = "Online"
                    }

                    New-Object PSObject -Property $Properties
                }
        }
        if ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
            foreach ($Computer in $ComputerName) {
                try {
                    if ($PSCmdlet.ShouldProcess("$Computer", "Get Machine Printer")) {
                        if ($env:COMPUTERNAME -ne $Computer) {
                            Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock | ForEach-Object { $_ | Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
                        }
                        else {
                            Invoke-Command -ScriptBlock $ScriptBlock | ForEach-Object { $_ | Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
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
                    if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Get Machine Printer")) {
                        if ($env:COMPUTERNAME -ne $Computer) {
                            Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock | ForEach-Object { $_ | Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
                        }
                        else {
                            Invoke-Command -ScriptBlock $ScriptBlock | ForEach-Object { $_ | Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
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
}