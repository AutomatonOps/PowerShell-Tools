function Get-MachinePrinter {
    <#
    .SYNOPSIS
        Gets a list of all printers installed under HKEY_LOCAL_MACHINE (printers available to any user logged on to the machine).
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Get-MachinePrinter -ComputerName localhost
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
                        Get-ChildItem -Path 'Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections' |
                        ForEach-Object -Process {
                            $PrinterName = $_ |
                            Get-ItemProperty -Name Printer |
                            Select-Object -ExpandProperty Printer

                            $Properties = @{
                                ComputerName = $env:ComputerName
                                UserName = "Machine"
                                PrinterName = $PrinterName
                                Type = "Machine"
                                Status = "Online"
                            }

                            New-Object PSObject -Property $Properties
                        }
                    }

                    if ($PSCmdlet.ShouldProcess("$Computer", "Get Machine Printer")) {
                        $Output.Add((Invoke-Command -Session (Get-PSSession -Name $Computer) -ScriptBlock $ScriptBlock)) #-AsJob -JobName $Computer | Out-Null
                    }
                }
                # Else {
                #     $Properties = @{
                #         ComputerName = $Computer
                #         UserName = "Machine"
                #         PrinterName = $null
                #         Type = "Machine"
                #         Status = "Offline"
                #     }
                #     $Output.Add((New-Object PSCustomObject -Property $Properties))
                # }

            }
            CATCH {
                Write-Host "Error!"# ${$_.Exception.Message}"
                Write-Output $error[0]
                $Properties = @{
                    ComputerName = $Computer
                    UserName = "Machine"
                    PrinterName = $null
                    Type = "Machine"
                    Status = "Error"
                }
                $Output.Add((New-Object PSCustomObject -Property $Properties))
            }
            FINALLY {
                #Write-Output $error[0]
            }
        }
    }

    END {
        ForEach ($Computer in (Get-PSSession | Select-Object -ExpandProperty ComputerName)) {
            # Write-Verbose -Message "Performing the operation 'Receive-Job -Wait' on target $Computer."
            # $Output.Add((Get-Job -Name $Computer | Receive-Job -Wait -AutoRemoveJob))

            Write-Verbose -Message "Performing the operation 'Remove-PSSession' on target $Computer."
            Get-PSSession -Name $Computer -ErrorAction SilentlyContinue | Remove-PSSession
        }
        $Output | ForEach-Object { $_ | Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
    }

}