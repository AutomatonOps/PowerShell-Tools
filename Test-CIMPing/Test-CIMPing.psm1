function Test-CimPing {
    <#
    .SYNOPSIS
        Pings a list of ComputerNames using Cim
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Test-CimPing -ComputerName localhost -Loop
    #>


    [cmdletbinding()]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = $env:COMPUTERNAME,
        [switch]$Loop = $False,
        [switch]$Wait = $False,
        [int32]$Count = 1,
        [int32]$Delay = 1,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        while($Loop -or $Count -or $Wait) {
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
                    if(($Wait)) {
                        if(($Res.Success)) {
                            Write-Output $Res | Select-Object ComputerName, ResponseTime, Success, TimeStamp
                        }
                    }
                    else {
                        Write-Output $Res | Select-Object ComputerName, ResponseTime, Success, TimeStamp
                    }

                }
            }
            $Count -= 1
            Start-Sleep -Seconds $Delay
        }
    }

}