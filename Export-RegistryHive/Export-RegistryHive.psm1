



function Export-RegistryHive {
    <#
    .SYNOPSIS
        Exports (Unloads) the registry hive of a given user if it is already loaded into the registry (Use this after using Import-RegistryHive...)
        Use -AllUsers to unload all users registry hives that can be found EXCEPT for the users that are currently logged in. Export-RegistryHive will never unload registry hives for logged in users.
        If no ComputerName is provided, it will default to localhost.
    .EXAMPLE
        Export-RegistryHive -ComputerName PC01
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
                    
                    $LoadedHives = Get-User -ComputerName $Computer | ForEach-Object -Process { Get-ADUser -Identity $_.UserName }

                    $ScriptBlock = { # Regex pattern for SIDs
                        $PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
                                
                        # Get Username, SID, and location of ntuser.dat for all users
                        $ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -match $PatternSID } | 
                        Select-Object  @{name = "SID"; expression = { $_.PSChildName } }, 
                        @{name = "UserHive"; expression = { "$($_.ProfileImagePath)\ntuser.dat" } }, 
                        @{name = "UserName"; expression = { $_.ProfileImagePath -replace '^(.*[\\\/])', '' } }
                                
                                
                        $UnloadedHives = Compare-Object $ProfileList $Using:LoadedHives | Select-Object @{name = "SID"; expression = { $_.InputObject } }, UserHive, UserName
                            
                        foreach ($item in $ProfileList) {
                            # Unload ntuser.dat        
                            If ($item.SID -notcontains $UnloadedHives.SID) {
                                #if ($PSCmdlet.ShouldProcess("$Using:Computer", "Unload Registry Hive for " + $item.Username)) {
                                ### Garbage collection and closing of ntuser.dat ###
                                try {
                                    [gc]::Collect()
                                    Start-Process -FilePath reg -ArgumentList "unload HKU\$($Item.SID)"
                                }
                                catch {
                                    #...suppressing errors
                                }
                                #}
                            }
                        }
                    }
                }

                        
                if ($PSCmdlet.ShouldProcess("$Computer", "Export Registry Hive")) {
                    $Output.Add((Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock))# -AsJob))
                }                           
            }
            CATCH {
                #Write-Warning -Message "Konnte nicht mit $Computer verbinden."
            }
            FINALLY {
            }
        }
    }

    END {
        $Output | ForEach-Object { $_ }#| Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
    } 

}