function Get-UserPrinter {
    <#
    .SYNOPSIS
        Gets a list of all printers installed under HKEY_CURRENT_USER (printers available only to the current user).
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Get-UserPrinter -ComputerName localhost
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

                        If ($PSCmdlet.ShouldProcess("$Computer", "Import Registry Hive")) {
                            Import-RegistryHive -ComputerName $Computer | Out-Null
                        }
                    }
                        

                    $ScriptBlock = {

                        $RegistryEntries = Get-ChildItem -Path "Registry::\HKEY_USERS\" | Where-Object { ($_.PSChildName -like "S-1-5-21-*") -and ($_.PSChildName -notlike "*_Classes") }
                        $SIDs = $RegistryEntries | Select-Object -ExpandProperty PSChildName
                                                            
                        foreach ($SID in $SIDs) {
                                        
                            try {
                                $UserName = ((New-Object System.Security.Principal.SecurityIdentIfier("$SID")).Translate([System.Security.Principal.NTAccount]).Value).Split("\")[1]
                                            
                                $Lines = $RegistryEntries | Select-Object -ExpandProperty Name | Where-Object { $_ -like "*$SID*" }
                                $Lines = (Get-ChildItem -Path "Registry::\$Lines\Printers\Connections" -ErrorAction SilentlyContinue) | Select-Object -ExpandProperty PSChildName
                            }
                            catch [System.Management.Automation.ItemNotFoundException] {
                                #...Suppressing errors If a key does not contain "Printers\Connections"
                            }
                            catch [System.Management.Automation.MethodInvocationException] {
                                #...Suppressing errors If a SID can not be found in AD
                                $UserName = $SID
                            }
                            if (!($Lines)) { 
                                # $Properties = @{
                                #     ComputerName = $env:COMPUTERNAME
                                #     UserName     = $UserName
                                #     PrinterName  = $null
                                #     Type         = $null
                                #     Status       = "Online"
                                # }
                                # New-Object PSObject -Property $Properties
                                continue
                            }
                            else {
                                foreach ($Line in $Lines) {
                                    If (!($Line)) {
                                        continue
                                    }
                                    $PrintServer = $Line.Split(",,")[2]
                                    $Printer = $Line.Split(",")[3]
                                    $PrinterName = "\\$PrintServer\$Printer"
                                    $Type = "User"
                                    $UserName_ = $UserName

                                    Get-ChildItem -Path 'Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections' |
                                    ForEach-Object -Process {
                                        $MachinePrinter = $_ |
                                        Get-ItemProperty -Name Printer |
                                        Select-Object -ExpandProperty Printer
                                        If ($MachinePrinter -eq $PrinterName) {
                                            #$UserName_ = "Machine"
                                            #$Type = "Machine"
                                            continue
                                        }
                                        $Properties = @{
                                            ComputerName = $env:COMPUTERNAME
                                            UserName     = $UserName_
                                            PrinterName  = $PrinterName
                                            Type         = $Type
                                            Status       = "Online"
                                        }
                                        New-Object PSObject -Property $Properties
                                    }
                                }
                            }            
                        }
                    }


                    If ($PSCmdlet.ShouldProcess("$Computer", "Get User Printer")) {
                        $Output.Add((Invoke-Command -Session (Get-PSSession -Name $Computer) -ScriptBlock $ScriptBlock)) #-AsJob -JobName $Computer | Out-Null
                    }
                }
                # Else {
                #     $Properties = @{
                #         ComputerName = $Computer
                #         UserName     = $null
                #         PrinterName  = $null
                #         Type         = $null
                #         Status       = "Offline"
                #     }
                #     $Output.Add((New-Object PSCustomObject -Property $Properties))
                # }                
            }
            CATCH {
                Write-Verbose "Error! ${$_.Exception.Message}"
                # $Properties = @{
                #     ComputerName = $Computer
                #     UserName     = $null
                #     PrinterName  = $null
                #     Type         = $null
                #     Status       = "Error"
                # }
                # $Output.Add((New-Object PSCustomObject -Property $Properties))
            }
            FINALLY {
            }
        }
    }

    END {
        ForEach ($Computer in (Get-PSSession | Select-Object -ExpandProperty ComputerName)) {
            ##Write-Verbose -Message "Performing the operation 'Receive-Job -Wait' on target $Computer."
            ##$Output.Add((Get-Job -Name $Computer | Receive-Job -Wait -AutoRemoveJob))

            Write-Verbose -Message "Performing the operation 'Remove-PSSession' on target $Computer."
            Get-PSSession -Name $Computer | Remove-PSSession

            Write-Verbose -Message "Performing the operation 'Export Registry Hive' on target $Computer."
            Export-RegistryHive -ComputerName $Computer | Out-Null
        }
        $Output | ForEach-Object { $_ | Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
    }

}







