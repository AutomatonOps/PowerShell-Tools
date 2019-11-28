function Wait-Proceed {
        param(
            [string]$Question = "Proceed"
        )
        ##Proceed?
        $answer = Read-Host "$Question (j/n)"

        while("j","n" -notcontains $answer) {
	        $answer = Read-Host "$Question (j/n)"
        }

        if( $answer -eq "n" ) {
            #Write-Host "Aborting..."
            return $false
        }
        return $true
}       



