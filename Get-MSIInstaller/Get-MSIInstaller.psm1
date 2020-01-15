function Get-MSIInstaller {
    <#
    .SYNOPSIS
        Gets the MSI Installer file to a given installed program.
    .EXAMPLE
        Get-MSIInstaller -ComputerName PC01 -Name "Office"
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = $env:COMPUTERNAME,
        [string]$Name = "*"
    )


    BEGIN {
        $Output = [System.Collections.Generic.List[PSObject]]::New()
    }

    PROCESS {
        ForEach ($Computer in $ComputerName) {
            TRY {
                If ((Test-CIMPing -ComputerName $Computer).Success) {

                    If ((Get-PSSession).Name -notcontains $Computer) {
                        Write-Verbose -Message "Performing the operation 'New-PSSession' on target $Computer."
                        New-PSSession -ComputerName $Computer -Name $Computer | Out-Null
                    }

                    Write-Verbose -Message "Getting Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ on $Computer"

                        $ScriptBlock = {
                            $Out += Get-ChildItem -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue |
                                Get-ItemProperty |
                                Where-Object {
                                    ($_.DisplayName) -and ($_.DisplayName -like "*$Using:Name*") 
                                }

                            $Out += Get-ChildItem -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
                                Get-ItemProperty |
                                Where-Object {
                                    ($_.DisplayName) -and ($_.DisplayName -like "*$Using:Name*") 
                                }

                            
                            $Out | Select-Object -Property DisplayName, InstallLocation, DisplayVersion, UninstallString -Unique | Sort-Object -Property DisplayName

                            #Write-Output -InputObject $Out
                        }

                    if ($PSCmdlet.ShouldProcess("$Computer", "Get MSI Installer")) {
                        $Output.Add((Invoke-Command -Session (Get-PSSession -Name $Computer) -ScriptBlock $ScriptBlock)) #-AsJob -JobName $Computer | Out-Null
                    }
                }
            }
            CATCH {
                Write-Error -Message $Computer
                Write-Error -Message $error[0]
                #Write-Warning "Konnte nicht mit $Computer verbinden."
            }
            FINALLY {
                #Write-Output $WMI
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
        $Output | ForEach-Object { $_ }
    }
}



