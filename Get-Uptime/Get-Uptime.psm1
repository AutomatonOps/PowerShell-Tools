function Get-Uptime {
    <#
    .SYNOPSIS
        Returns the current uptime of a given system as a TimeSpan object.
    .EXAMPLE
        Get-Uptime -ComputerName PC01
    #>

    [cmdletbinding()]
    Param(
        [string[]]$ComputerName = "localhost"
    )

    foreach ($Computer in $ComputerName) {
        try {
            $CimSession = New-CimSession -ComputerName $Computer
            Write-Verbose -Message "$Computer is online"
            $result = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $CimSession -Property LastBootUpTime).LastBootUpTime
            Remove-CimSession -CimSession $CimSession
        }
        catch {
            Write-Warning -Message "Konnte keine Verbindung mit $Computer herstellen."
        }
        finally {
            $out = $result | Select-Object @{n="ComputerName";e={$Computer}}, *
            Write-Output $out
        }
    }
}