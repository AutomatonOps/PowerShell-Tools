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
        [string[]]$Name = "*"
    )

    process {
        ForEach ($Computer in $ComputerName) {
            try {
                    Write-Verbose -Message "Getting Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ on $Computer"

                foreach($N in $Name) {

                    $ScriptBlock = {
                        $Out += Get-ChildItem -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue |
                            Get-ItemProperty

                        $Out += Get-ChildItem -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
                            Get-ItemProperty


                                
                        $Out |
                            Where-Object { ($_.DisplayName) -and ($_.DisplayName -like "*$Using:N*") } |
                                Select-Object -Property *, @{n = "UninstallArgs"; e = { if ($_.UninstallString -like 'MsiExec.exe *') { ($_.UninstallString.Split(' ')[1]).Replace("/I", "/X") } } } -Unique |
                                    Sort-Object -Property DisplayName
                    }

                    $ScriptBlockLocal = {
                        $Out += Get-ChildItem -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue |
                            Get-ItemProperty

                        $Out += Get-ChildItem -Path "Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
                            Get-ItemProperty


                                
                        $Out |
                            Where-Object { ($_.DisplayName) -and ($_.DisplayName -like "*$N*") } |
                                Select-Object -Property *, @{n = "UninstallArgs"; e = { if ($_.UninstallString -like 'MsiExec.exe *') { $_.UninstallString.Split(' ')[1].Replace("/I", "/X") } } } -Unique |
                                    Sort-Object -Property DisplayName
                    }

                    if ($PSCmdlet.ShouldProcess("$Computer", "Get MSI Installer")) {
                        if ($Computer -eq $env:COMPUTERNAME) {
                            Invoke-Command -ScriptBlock $ScriptBlockLocal
                        }
                        else {
                            Invoke-Command -ComputerName $Computer -ScriptBlock $ScriptBlock #-AsJob -JobName $Computer | Out-Null
                        }
                    }

                }
            }
            catch {
                Write-Host "Something went wrong."
                Write-Host $error[0]
            }
        }
    }
}



