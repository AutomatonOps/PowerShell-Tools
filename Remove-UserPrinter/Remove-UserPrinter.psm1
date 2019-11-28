function Remove-UserPrinter {
    <#
    .SYNOPSIS
        Removes a list of printers installed for a specIfic user (printers only available to a specIfic user)
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Remove-UserPrinter -ComputerName localhost -UserName User01 -PrinterName \\PRINTSERVER.FQDN\PRINTER
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string[]]$UserName,

        [parameter(Mandatory, ValueFromPipelineByPropertyName)][string[]]$PrinterName,

        [switch]$Force
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

                        If ($PSCmdlet.ShouldProcess("$Computer", "Import Registry Hive")) {
                            Import-RegistryHive -ComputerName $Computer
                        }
                    }


                    $ScriptBlock = {

                        If ($Using:Force) {
                            Stop-Service -Name "Spooler" -Force
                        }

                        ForEach ($User in $Using:UserName) {

                            If ($User.Contains("\")) {
                                $User = $User.Split("\")[1]
                            }
                            try {
                                $SID = (New-Object System.Security.Principal.NTAccount($User)).Translate([System.Security.Principal.SecurityIdentIfier]).Value
                            }
                            catch [System.Management.Automation.MethodInvocationException] {
                                #...Suppressing errors If a UserName can not be found in AD
                                $SID = $User
                            } 



                            ForEach ($Printer in $Using:PrinterName) {
                                #If ($PSCmdlet.ShouldProcess($ComputerName, "Remove User Printer $Printer for $User")) {
                                    #$Server = $Printer.Trim("\").Split("\")[0]
                                    $Printer_ = $Printer.Replace("\", ",")
                                    $Server_ = $Printer_.Trim(",").Split(",")[0]
                                    $PrinterString = $Printer_.Trim(",").Split(",")[1]
                
                                    Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\$SID\Printers\Connections\$Printer_" -ErrorAction SilentlyContinue | Remove-Item 
                                    Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\$Server_\Monitors\Client Side Port\" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.PrinterPath -like "*$PrinterString*" } | Remove-Item 
                                    Get-Item -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\$Server_\Printers\" -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object { $_.Description -like "*$PrinterString*" } | Remove-Item -Recurse 
                                    Get-Item -Path "Registry::\HKEY_USERS\$SID\Printers\Connections\$Printer_" -ErrorAction SilentlyContinue | Remove-Item 
                                    Get-ItemProperty -Path "Registry::\HKEY_USERS\$SID\Printers\Settings\" -Name $Printer -ErrorAction SilentlyContinue | Remove-Item -Recurse         
                                #}
                            }

                        }

                        If ($Using:Force) {
                            Start-Service -Name "Spooler"
                        }

                    }


                    If ($PSCmdlet.ShouldProcess("$Computer", "Remove User Printer $PrinterName")) {
                        $Output.Add((Invoke-Command -Session (Get-PSSession -Name $Computer) -ScriptBlock $ScriptBlock)) #-AsJob -JobName $Computer
                    }
                }
                Else {
                    $Properties = @{
                        ComputerName = $Computer
                        UserName     = $null
                        PrinterName  = $null
                        Type         = $null
                        Status       = "Offline"
                    }
                    $Output.Add((New-Object PSObject -Property $Properties))
                }                
            }
            CATCH {
                Write-Verbose "Error! ${$_.Exception.Message}"
                $Properties = @{
                    ComputerName = $Computer
                    UserName     = $null
                    PrinterName  = $null
                    Type         = $null
                    Status       = "Error"
                }
                $Output.Add((New-Object PSObject -Property $Properties))
            }
            FINALLY {
            }
        }
    }

    END {
        ForEach ($Computer in (Get-PSSession | Select-Object -ExpandProperty ComputerName)) {
            #Write-Verbose -Message "Performing the operation 'Receive-Job -Wait' on target $Computer."
            #$Output.Add((Get-Job -Name $Computer | Receive-Job -Wait -AutoRemoveJob))

            Write-Verbose -Message "Performing the operation 'Remove-PSSession' on target $Computer."
            Get-PSSession -Name $Computer | Remove-PSSession

            Write-Verbose -Message "Performing the operation 'Export Registry Hive' on target $Computer."
            Export-RegistryHive -ComputerName $Computer
        }
        #$Output | ForEach-Object { ($_ | Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique) }
        ForEach ($Out in $Output) {
            $Out | Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique
        }
    }


}