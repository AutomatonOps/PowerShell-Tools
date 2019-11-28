#Check for PowerShell Core (min Version 6)
#If not we will notify the user that this is a prerequisite to run this script and others reliably
function Read-PowerShellVersion {
    if(($PSVersionTable).PSVersion.Major -lt 5) {
        Write-Host -ForegroundColor Red "Dieses Skript benoetigt PowerShell Core (Version 6.0.0 oder hoeher). `
    PowerShell Core ist eine Vorraussetzung für viele der Frontoffice Skripte. `
    Die jeweils aktuellste Installationsdatei ist unter Q:\ag-it\DavidHallmann\Prerequisites\ zu finden. `
    Bitte PowerShell Core installieren und dieses Skript anschließend erneut ausfuehren!"
            # If running in the console, wait for input before closing.
            if ($Host.Name -eq "ConsoleHost")
            {
                Write-Host "Press any key to continue..."
                Read-Host
            } 
        Exit                               
    }
}