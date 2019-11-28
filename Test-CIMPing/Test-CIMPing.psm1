function Test-CIMPing {
    <#
    .SYNOPSIS
        Pings a list of ComputerNames using CIM
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Test-CIMPing -ComputerName localhost -Loop
    #>


    [cmdletbinding()]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = "localhost",
        [switch]$Loop = $False,
        [int32]$Count = 4,
        [int32]$Delay = 0,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        while($Loop -or $Count) {
            foreach($Computer in $ComputerName) {
                try {
                    $Res = Get-CimInstance -ClassName Win32_PingStatus -Filter "Address='$Computer' AND Timeout=1000"
                    Add-Member -InputObject $Res -NotePropertyName TimeStamp -NotePropertyValue (Get-Date)
                    Add-Member -InputObject $Res -NotePropertyName ComputerName -NotePropertyValue $Res.Address
                    if  ($Res.StatusCode -ne 0) {
                        Add-Member -InputObject $Res -NotePropertyName Success -NotePropertyValue $false
                    }
                    else {
                        Add-Member -InputObject $Res -NotePropertyName Success -NotePropertyValue $true
                    }
                }
                catch {
                    Write-Warning -Message "Something went wrong."
                    $error[0]
                }
                finally {
                    Write-Output $Res | Select-Object ComputerName, ResponseTime, Success, TimeStamp
                }
            }
            $Count -= 1
            Start-Sleep -Seconds $Delay
        }
    }

}