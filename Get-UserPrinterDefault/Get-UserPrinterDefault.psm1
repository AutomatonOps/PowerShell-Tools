function Get-UserPrinterDefault {
    <#
    .SYNOPSIS
        Gets the default printer on a given computername for all users.
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Get-UserPrinterDefault -ComputerName localhost
    #>


    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string[]]$ComputerName = $env:COMPUTERNAME

        #[parameter(Mandatory, ValueFromPipelineByPropertyName)][string[]]$UserName,
    )

    BEGIN {
        $Output = [System.Collections.Generic.List[PSObject]]::New()
    }
    
    PROCESS {
        ForEach($Computer in $ComputerName) {
            TRY {
                If ((Test-CIMPing -ComputerName $Computer).Success) {

                    $ScriptBlock = {

                        $RegistryEntries = Get-ChildItem -Path "Registry::\HKEY_USERS\" | Where-Object { ($_.PSChildName -like "S-1-5-21-*") -and ($_.PSChildName -notlike "*_Classes") }
                        $SIDs = $RegistryEntries | Select-Object -ExpandProperty PSChildName
                                                            
                        foreach ($SID in $SIDs) {
                                      
                                $UserName = ((New-Object System.Security.Principal.SecurityIdentIfier("$SID")).Translate([System.Security.Principal.NTAccount]).Value).Split("\")[1]

                                $Result = (Get-ItemProperty -Path "Registry::\HKEY_USERS\$SID\Software\Microsoft\Windows NT\CurrentVersion\Windows\" -Name "Device" -ErrorAction Stop | Select-Object -ExpandProperty Device).Split(",")[0]

                                $Properties = @{
                                    ComputerName = $env:COMPUTERNAME
                                    UserName = $UserName
                                    PrinterName = $Result
                                }
                                New-Object PSObject -Property $Properties

                        }                    
                    }
                    If ($PSCmdlet.ShouldProcess("$Computer", "Get default printer")) {
                        $Output.Add((Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock)) #-AsJob -JobName $Computer | Out-Null
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
        $Output | ForEach-Object { $_ | Select-Object -Property ComputerName, UserName, PrinterName | Select-Object -Property * -Unique }
    }
}