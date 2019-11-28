function Add-MachinePrinter {
    <#
    .SYNOPSIS
        Adds a list of all printers installing them under HKEY_LOCAL_MACHINE (printers available to any user logged on to the machine).
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Add-MachinePrinter -ComputerName localhost -PrinterName \\PRINTSERVER.FQDN\PRINTER
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string[]]$PrinterName
    )
    
    BEGIN {
        $Output = [System.Collections.Generic.List[PSObject]]::New()
    }

    PROCESS {
        ForEach ($Computer in $ComputerName) {
            #Write-Verbose -Message "Performing the operation 'Test-CIMPing' on target $Computer."
            TRY {
                If ((Test-CIMPing -ComputerName $Computer).Success) {

                    If ((Get-PSSession).ComputerName -notcontains $Computer) {
                        Write-Verbose -Message "Performing the operation 'New-PSSession' on target $Computer."
                        New-PSSession -ComputerName $Computer -Name $Computer | Out-Null
                    }

                    ForEach ($Printer in $PrinterName) {
                        $ScriptBlock = {
                            Start-Process -FilePath rundll32.exe -ArgumentList "printui,PrintUIEntry /ga /n$Using:Printer" -Wait
                        }#scriptblock

                        if ($PSCmdlet.ShouldProcess("$Computer", "Add Machine Printer $Printer")) {
                            $Output.Add((Invoke-Command -Session (Get-PSSession -Name $Computer) -ScriptBlock $ScriptBlock)) #-AsJob -JobName $Computer | Out-Null
                            $Properties = @{
                                ComputerName = $Computer
                                PrinterName  = $PrinterName
                                Status       = "Online"
                            }
                            $Output.Add((New-Object PSCustomObject -Property $Properties))
                        }#shouldprocess
                    }
                }#test-cimping
                Else {
                    $Properties = @{
                        ComputerName = $Computer
                        PrinterName  = $PrinterName
                        Status       = "Offline"
                    }
                    $Output.Add((New-Object PSCustomObject -Property $Properties))
                }           
        }#try
        CATCH {
            Write-Host "Error! ${$_.Exception.Message}"
            $Properties = @{
                ComputerName = $Computer
                PrinterName  = $PrinterName
                Status       = $_.Exception.Message
            }
            $Output.Add((New-Object PSCustomObject -Property $Properties))
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
    $Output | ForEach-Object { $_ | Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
}

}#function
