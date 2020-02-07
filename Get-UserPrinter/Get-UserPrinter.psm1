function Get-UserPrinter {
    <#
    .SYNOPSIS
        Gets a list of all printers installed under HKEY_CURRENT_USER (printers available only to the current user).
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Get-UserPrinter -ComputerName localhost
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

                try {
                    $UserName = ((New-Object System.Security.Principal.SecurityIdentIfier("$SID")).Translate([System.Security.Principal.NTAccount]).Value).Split("\")[1]

                    $Lines = $RegistryEntries | Select-Object -ExpandProperty Name | Where-Object { $_ -like "*$SID*" }
                    $Lines = (Get-ChildItem -Path "Registry::\$Lines\Printers\Connections" -ErrorAction SilentlyContinue) | Select-Object -ExpandProperty PSChildName
                }
                catch [System.Management.Automation.ItemNotFoundException] {
                    #...Suppressing errors If a key does not contain "Printers\Connections"
                }
                catch [System.Management.Automation.MethodInvocationException] {
                    #...Suppressing errors If a SID can not be found in AD
                    $UserName = $SID
                }
                if (!($Lines)) {
                    continue
                }
                else {
                    foreach ($Line in $Lines) {
                        If (!($Line)) {
                            continue
                        }
                        $PrintServer = $Line.Split(",,")[2]
                        $Printer = $Line.Split(",")[3]
                        $PrinterName = "\\$PrintServer\$Printer"
                        $Type = "User"
                        $UserName_ = $UserName

                        $Properties = @{
                            ComputerName = $env:COMPUTERNAME
                            UserName     = $UserName_
                            PrinterName  = $PrinterName
                            Type         = $Type
                        }

                        Get-ChildItem -Path 'Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections' |
                        ForEach-Object -Process {
                            $MachinePrinter = $_ |
                            Get-ItemProperty -Name Printer |
                            Select-Object -ExpandProperty Printer
                            If ($MachinePrinter -eq $PrinterName) {
                                $Properties = @{
                                    ComputerName = $env:COMPUTERNAME
                                    UserName     = $UserName_
                                    PrinterName  = $PrinterName
                                    Type         = "Machine"
                                }
                            }
                        }
                        New-Object PSObject -Property $Properties
                    }
                }
            }
        }
        if ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
            foreach ($Computer in $ComputerName) {
                try {
                    If ($PSCmdlet.ShouldProcess("$Computer", "Get User Printer")) {
                        Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock | Select-Object ComputerName, UserName, PrinterName, Type
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
                    if ($PSCmdlet.ShouldProcess($PSSession.ComputerName, "Get User Printer")) {
                        Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock | Select-Object ComputerName, UserName, PrinterName, Type
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
