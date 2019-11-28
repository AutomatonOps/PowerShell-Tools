function Get-User {
    <#
    .SYNOPSIS
        Gets a list of recently logged on users on a given (list) of hostnames
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Get-User -ComputerName PC01 -Last 3
    #>

    [cmdletbinding()]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = "localhost",
        [int32]$Last = 5,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {    
        foreach ($Computer in $ComputerName) {
            try {
                $Session = New-CimSession -ComputerName $Computer -ErrorAction Stop
                $LoggedOnUser = Get-CimInstance -ClassName Win32_LoggedOnUser -CimSession $Session -Property * | Select-Object -ExpandProperty Antecedent | Where-Object { ($_.Name -ne "IUSR") -and ($_.Name -ne "DefaultAppPool") -and ($_.Name -ne $env:UserName) -and ($_.Name -ne "SYSTEM") -and ($_.Name -ne "Lokaler Dienst") -and ($_.Name -ne "Netzwerkdienst") -and ($_.Name -ne "ANONYMOUS-ANMELDUNG") -and ($_.Name -notlike "DWM-*") -and ($_.Name -notlike "UMFD-*") } | Select-Object  -Unique -Last $Last

                foreach ($User in $LoggedOnUser) {
                    [PSCustomObject]@{
                        ComputerName = $Computer
                        Status       = "Connected"
                        UserName     = $User.Name
                    }
                }
            }
            catch {
                Write-Warning -Message "Konnte keine Verbindung mit $Computer herstellen."
                [PSCustomObject]@{
                    ComputerName = $Computer
                    Status       = "Disconnected"
                    Users        = $User.Name
                }
            }
        }

    }
}