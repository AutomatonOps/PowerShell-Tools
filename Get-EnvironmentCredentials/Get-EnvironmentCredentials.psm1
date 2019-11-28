    #Get Credentials
function Get-EnvironmentCredentials {    
    if([System.Environment]::GetEnvironmentVariable("PSLoginUser", [System.EnvironmentVariableTarget]::Machine)) {
        $User = [System.Environment]::GetEnvironmentVariable("PSLoginUser", [System.EnvironmentVariableTarget]::Machine)
        #$Password = [System.Environment]::GetEnvironmentVariable("PSLoginPassword", [System.EnvironmentVariableTarget]::Machine)
    }
    else {
        $User = Read-Host -Prompt "Bitte anmelden"
        $User = "RNR-NET\" + $User
        #[System.Environment]::SetEnvironmentVariable("PSLoginUser", $User, [System.EnvironmentVariableTarget]::Machine)
    }
    return Get-Credential $User
}