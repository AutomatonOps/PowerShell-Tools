function Get-Uptime {
    <#
    .SYNOPSIS
        Returns the current uptime of a given system as a TimeSpan object.
    .EXAMPLE
        Get-Uptime -ComputerName PC01
    #>

    [cmdletbinding()]
    Param(
        [string[]]$ComputerName = "localhost",
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = $Credential
    )

    foreach ($Computer in $ComputerName) {
        try {
            $CimSession = New-CimSession -ComputerName $ComputerName -Credential $Credential
            Write-Verbose -Message "$ComputerName is online"
            $result = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $CimSession -Property LastBootUpTime).LastBootUpTime
        }
        catch {
            Write-Warning -Message "Konnte keine Verbindung mit $Computer herstellen."
        }
        finally {
            $out = $result
            Write-Output $out
        }
    }
}