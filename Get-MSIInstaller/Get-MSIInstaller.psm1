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

                    Write-Verbose -Message "Getting Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ on $Computer"

                        $ScriptBlock = {
                            $Out += Get-ChildItem -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue |
                                Get-ItemProperty

                            $Out += Get-ChildItem -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
                                Get-ItemProperty


                            
                            $Out |
                                Where-Object {($_.DisplayName) -and ($_.DisplayName -like "*$Using:Name*")} |
                                    Select-Object -Property DisplayName, InstallLocation, DisplayVersion, UninstallString, @{n="UninstallArgs";e={if($_.UninstallString -like 'MsiExec.exe *'){$_.UninstallString.Split(' ')[1]}}} -Unique |
                                        Sort-Object -Property DisplayName

                            #Write-Output -InputObject $Out
                        }

                    if ($PSCmdlet.ShouldProcess("$Computer", "Get MSI Installer")) {
                        if($Computer -eq $env:COMPUTERNAME) {
                            $Output.Add((Invoke-Command -ScriptBlock $ScriptBlock))
                        }
                        else {
                            $Output.Add((Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock)) #-AsJob -JobName $Computer | Out-Null
                        }
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
        $Output | ForEach-Object { $_ }
    }
}



