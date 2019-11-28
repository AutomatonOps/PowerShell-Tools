function Get-Info {
    <#
    .SYNOPSIS
        Gets a list of various pieces of information relevant to 1st level support technicians
    .EXAMPLE
        Get-Info -ComputerName PC01
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
            $result = @{ Hostname = $ComputerName; 
                #CurrentUser = (Get-LoggedInUser -ComputerName $ComputerName).username
                LoggedOnUsers = (Get-CimInstance -ClassName Win32_LoggedOnUser -CimSession $CimSession -Property Antecedent).Antecedent.Name | Select-Object -Unique -Last 10
                IP = (Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -CimSession $CimSession -Property * | Where-Object { $null -ne $_.IPAddress } | Select-Object IPAddress).IPAddress
                Uptime = ((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $CimSession -Property LastBootUpTime).LastBootUpTime)
                Model = (Get-CimInstance -ClassName Win32_ComputerSystem -CimSession $CimSession -Property Model).Model
                RAM = (Get-CimInstance -ClassName Win32_ComputerSystem -CimSession $CimSession -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB;
                CPU = (Get-CimInstance -ClassName CIM_Processor -CimSession $CimSession -Property Name).Name
                Architecture = (Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $CimSession -Property OSArchitecture).OSArchitecture
                OS = (Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $CimSession -Property Caption).Caption
                SCCM = (Get-CimInstance -ClassName Win32_Service -CimSession $CimSession -Filter "Name like 'CmRcService'").State
            }
        }
        catch {
            Write-Warning -Message "Konnte keine Verbindung mit $Computer herstellen."
        }
        finally {
            $out = New-Object -TypeName PSObject -Property $result
            Write-Output $out
        }
    }
}