function Clear-Spooler {
    <#
    .SYNOPSIS
        Clears a given Computers spooler as to remove print jobs that are "stuck" and seemingly can not be removed.
    .EXAMPLE
        Clear-Spooler -ComputerName prs-zz-rz1-sv01
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = $env:COMPUTERNAME
    )

    BEGIN {
        $Output = [System.Collections.Generic.List[PSObject]]::New()
    }    

    PROCESS {
        ForEach($Computer in $ComputerName) {
            TRY {
                If ((Test-CIMPing -ComputerName $Computer).Success) {

                    If ((Get-PSSession).ComputerName -notcontains $Computer) {
                        Write-Verbose -Message "Performing the operation 'New-PSSession' on target $Computer."
                        New-PSSession -ComputerName $Computer -Name $Computer | Out-Null
                    }

                    $ScriptBlock = {
                        ##List Spooler Jobs
                        Write-Verbose -Message "List spooler jobs"
                        Get-ChildItem -Path C:\Windows\system32\spool\PRINTERS


                        ##Stop Spooler
                        Write-Verbose -Message "Stop spooler"
                        Get-Service -Name Spooler | Stop-Service -Force
                        (Get-Service -Name Spooler).WaitForStatus("Stopped")


                        ##Clear Spooler Jobs
                        Write-Verbose -Message "Remove spooler jobs"
                        Remove-Item C:\Windows\system32\spool\PRINTERS\* -Recurse -Force -Verbose

                        ##Start Spooler
                        Write-Verbose -Message "Start spooler"
                        Get-Service -Name Spooler | Start-Service
                        (Get-Service -Name Spooler).WaitForStatus("Running")
                    }

                    If ($PSCmdlet.ShouldProcess($Computer, "Clear Spooler")) {
                        $Output.Add((Invoke-Command -Session (Get-PSSession -Name $Computer) -ScriptBlock $ScriptBlock))
                    }

                }
            }#try
            CATCH {
                Write-Warning -Message "Konnte nicht mit $Computer verbinden."
            }#catch
        }#foreach()
    }#process

    END {
        ForEach ($Computer in (Get-PSSession | Select-Object -ExpandProperty ComputerName)) {
            # Write-Verbose -Message "Performing the operation 'Receive-Job -Wait' on target $Computer."
            # $Output.Add((Get-Job -Name $Computer | Receive-Job -Wait -AutoRemoveJob))
    
            Write-Verbose -Message "Performing the operation 'Remove-PSSession' on target $Computer."
            Get-PSSession -Name $Computer | Remove-PSSession
        }
        $Output
    }#end    

}#function