



function Import-RegistryHive {
    <#
    .SYNOPSIS
        Imports the registry hive of a given user if it is not already loaded into the registry (User is already logged in, for example)
        Use -AllUsers to load all users registry hives that can be found.
        If no ComputerName is provided, it will default to localhost.
    .EXAMPLE
        Import-RegistryHive -ComputerName PC01
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

                    $ScriptBlock = {
                        # Regex pattern for SIDs
                        $PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
                                    
                        # Get Username, SID, and location of ntuser.dat for all users
                        $ProfileList = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object { $_.PSChildName -match $PatternSID } | 
                        Select-Object  @{name = "SID"; expression = { $_.PSChildName } }, 
                        @{name = "UserHive"; expression = { "$($_.ProfileImagePath)\ntuser.dat" } }, 
                        @{name = "Username"; expression = { $_.ProfileImagePath -replace '^(.*[\\\/])', '' } }
                                                            
                                                                
                        # Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
                        $LoadedHives = Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildname -match $PatternSID } | Select-Object @{name = "SID"; expression = { $_.PSChildName } }
                                                                
                        # Get all users that are not currently logged
                        $UnloadedHives = Compare-Object $ProfileList $LoadedHives | 
                        Select-Object @{name = "SID"; expression = { $_.InputObject.SID } }, 
                        @{name = "UserHive"; expression = { $_.InputObject.UserHive } },
                        @{name = "Username"; expression = { $_.InputObject.Username } }
                                    
                                    
                        foreach ($item in $ProfileList) {
                            # Load User ntuser.dat if it's not already loaded
                            If ($item.SID -ne $UnloadedHives.SID) {
                                #if ($PSCmdlet.ShouldProcess("hostname", "Load Registry Hive for " + $item.Username)) {
                                try {
                                    Start-Process -FilePath reg -ArgumentList "load HKU\$($Item.SID) $($Item.UserHive)"
                                }
                                catch {
                                    #...suppressing errors
                                }
                                #}
                            }
                        }
                    }

                    if ($PSCmdlet.ShouldProcess("$Computer", "Import Registry Hive")) {
                        $Output.Add((Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock))# -AsJob))
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
        $Output | ForEach-Object { $_ }#| Select-Object -Property ComputerName, UserName, PrinterName, Type | Select-Object -Property * -Unique }
    }

}