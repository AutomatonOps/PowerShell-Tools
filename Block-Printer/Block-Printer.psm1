function Block-Printer {
    <#
    .SYNOPSIS
        Blocks all printers installed on a given (list) of ComputerName.
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Block-Printer -ComputerName localhost,PC01
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = $env:COMPUTERNAME  
    )


    BEGIN {
        $Output = [System.Collections.Generic.List[PSObject]]::New()
    }

    PROCESS {
        ForEach ($Computer in $ComputerName) {
            TRY {
                If ((Test-CIMPing -ComputerName $Computer).Success) {

                    If ((Get-PSSession).ComputerName -notcontains $Computer) {
                        Write-Verbose -Message "Performing the operation 'New-PSSession' on target $Computer."
                        New-PSSession -ComputerName $Computer -Name $Computer | Out-Null
                    }


                    $ScriptBlock = {

                        #Get architecture 
                        if((Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty AddressWidth) -eq "64") {
                            $Environment = "Windows x64"
                        }
                        else {
                            $Environment = "Windows 4.0"
                        }

                        #Stop Spooler
                        Stop-Service -Name Spooler -Force
                        (Get-Service -Name Spooler).WaitForStatus("Stopped")

                        #Rename Print Processors
                        $PrintProcessors = Get-ChildItem -Path "Registry::\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Environments\$Environment\Print Processors"
                        foreach ($printprocessor in $PrintProcessors) {
                            $newname = $printprocessor.PSChildName -replace ".old"
                            $oldname = $printprocessor.PSChildName
                            Rename-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Environments\$Environment\Print Processors\$oldname" -NewName $newname
                        }

                        #Start Spooler
                        Start-Service -Name Spooler
                        (Get-Service -Name Spooler).WaitForStatus("Running")

                    }


                    if ($PSCmdlet.ShouldProcess("$Computer", "Block-Printer")) {
                        $Output.Add((Invoke-Command -Session (Get-PSSession -Name $Computer) -ScriptBlock $ScriptBlock)) #-AsJob -JobName $Computer | Out-Null
                    }

                }
            }
            CATCH { 
                Write-Host "Error! ${$_.Exception.Message}"
            }
            FINALLY {
            }
        }
    }

    END {
        ForEach ($Computer in (Get-PSSession | Select-Object -ExpandProperty ComputerName)) {
            # Write-Verbose -Message "Performing the operation 'Receive-Job -Wait' on target $Computer."
            # $Output.Add((Get-Job -Name $Computer | Receive-Job -Wait -AutoRemoveJob))

            Write-Verbose -Message "Performing the operation 'Remove-PSSession' on target $Computer."
            Get-PSSession -Name $Computer | Remove-PSSession
        }
        $Output | ForEach-Object { $_ }#| Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
    }


}




