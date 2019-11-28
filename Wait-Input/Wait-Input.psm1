function Wait-Input {
    #Param(
        #[string]$scriptPath
    #)
        # if($scriptPath) {
        #     $again = Read-Host "Nochmal? j/n"
        #     if($again -eq "j") {
        #         & $scriptPath
        #     }
        # }
            # If running in the console, wait for input before closing.
            if ($Host.Name -eq "ConsoleHost")
            {
                Write-Host "Beliebige Taste um fortzufahren..."
                Read-Host
            }
}