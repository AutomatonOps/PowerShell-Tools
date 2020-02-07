function Get-UserPrinterDefault {
    <#
    .SYNOPSIS
        Gets the default printer on a given computername for all users.
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Get-UserPrinterDefault -ComputerName localhost
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'ComputerName')][string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'PSSession', Mandatory = $true)][System.Management.Automation.Runspaces.PSSession[]]$Session
    )


    process {
        $ScriptBlock = {
            $RegistryEntries = Get-ChildItem -Path "Registry::\HKEY_USERS\" | Where-Object { ($_.PSChildName -like "S-1-5-21-*") -and ($_.PSChildName -notlike "*_Classes") }
            $SIDs = $RegistryEntries | Select-Object -ExpandProperty PSChildName
            foreach ($SID in $SIDs) {
                $UserName = ((New-Object System.Security.Principal.SecurityIdentIfier("$SID")).Translate([System.Security.Principal.NTAccount]).Value).Split("\")[1]

                $Result = (Get-ItemProperty -Path "Registry::\HKEY_USERS\$SID\Software\Microsoft\Windows NT\CurrentVersion\Windows\" -Name "Device" -ErrorAction Stop | Select-Object -ExpandProperty Device).Split(",")[0]

                $Properties = @{
                    ComputerName = $env:COMPUTERNAME
                    UserName     = $UserName
                    PrinterName  = $Result
                }
                New-Object PSObject -Property $Properties
            }
        }
        if ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
            foreach ($Computer in $ComputerName) {
                try {
                    if ($PSCmdlet.ShouldProcess($Computer, 'Get Default Printer')) {
                        Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock | Select-Object ComputerName, UserName, PrinterName
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
                    if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, 'Get Default Printer')) {
                        Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock | Select-Object ComputerName, UserName, PrinterName
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