function Get-EventLogTimePeriod {
    <#
    .SYNOPSIS
        Gets a set of all available EventLogs that may be filtered using additional Parameters
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Get-EventLogTimePeriod -ComputerName PC01,PC02 -EventLevel 2 -StartDate "01/04/2019 08:00 AM" -EndDate "01/04/2019 04:00 PM"
    #>

    [cmdletbinding()]
    Param(
        [string[]]$ComputerName = "localhost",
        [int32]$EventLevel = 2,
        [parameter(Mandatory)][DateTime]$StartDate,
        [parameter(Mandatory)][DateTime]$EndDate,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )


    Write-Verbose -Message "Gathering EventLogs..."

        foreach($Computer in $ComputerName) {
            try {
                Test-Connection -ComputerName $Computer -Count 1 -Quiet -ErrorAction Stop -Verbose | Out-Null
                #Filter empty logs out
                $logs = (Get-WinEvent -ComputerName $Computer -ListLog * -ErrorAction Stop -Verbose | Where-Object {$_.RecordCount}).LogName

                foreach($log in $logs) {
                    #try {
                        $data = Get-WinEvent -ComputerName $Computer -FilterHashtable @{logname=$log;level=$EventLevel;starttime=$StartDate;endtime=$EndDate} -ErrorAction Stop -Verbose
                        if($data) {
                            $Out = [PSCustomObject]@{
                                Id = $data.Id
                                Message = $data.Message
                                UserId = $data.UserId
                                TimeCreated = $data.TimeCreated
                                LevelDisplayName = $data.LevelDisplayName
                                LogName = $data.LogName
                                MachineName = $data.MachineName
                                ProviderName = $data.ProviderName
                            }

                            $Out
                        }
                    #}
                    #catch {
                    #    Write-Error -Message "$Computer :: $log :: $error[0].Exception.Message"
                    #}
                }
            }
            catch {
            Write-Verbose -Message  "$error[0].Exception.Message"
            }
        }

    Write-Verbose -Message "Finished gathering Eventlogs!"
    }
