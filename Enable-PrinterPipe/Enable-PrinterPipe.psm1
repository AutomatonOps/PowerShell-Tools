function Enable-PrinterPipe {
    <#
    .SYNOPSIS
        Enables the PrinterPipe, allowing Cmdlets from the Windows 10 module PrintManagement to connect to remote Windows 7 machines.
        Neccessary if you want to leverage the PrintManagement Cmdlets on Windows 7 machines to manage local printers, drivers and ports.
    .EXAMPLE
        Enable-PrinterPipe -ComputerName localhost
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

                    $ScriptBlock = {                        
                        #Test pipes
                        Write-Verbose -Message "[$Computer] Test pipes"
                        $Pipes = [System.IO.Directory]::GetFiles("\\.\\pipe\\") | Select-String -pattern '\\spoolss'
                        if(!($Pipes)) {
                            #Fix pipes
                            Write-Verbose -Message "[$Computer] Fix pipes"
                                New-ItemProperty -Path 'REGISTRY::HKLM\Software\Policies\Microsoft\Windows NT\Printers' -Name RegisterSpoolerRemoteRpcEndPoint -PropertyType DWORD -Value 1 -Verbose | Out-Null
                                Restart-Service -Name Spooler -Force 
                            #Wait for Spooler
                            Write-Verbose -Message "[$Computer] Wait for spooler"
                                (Get-Service -Name Spooler).WaitForStatus("Running")
                        }
                    }
                    If ($PSCmdlet.ShouldProcess("$Computer", "Enabling PrinterPipe")) {
                        $Output.Add((Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock))
                    }
                        
                }
            }
            CATCH {
                Write-Verbose "Error! ${$_.Exception.Message}"                
            }
            FINALLY {
            }
        }
    }

    END {
        $Output
    }
}