function Get-LoggedInUser
{
<#
    .SYNOPSIS
        Sets an environment variable for PSLoginUser that will be used across all Med360 controllers to facilitate fast login

    .DESCRIPTION
        Sets 

    .PARAMETER UserName
        One UserName, preferably an admin account (oa-)...

    .EXAMPLE
        PS C:\> Set-PSLogin oa-hallmann
        Sets an environment variable for PSLoginUser with the value oa-hallmann
#>

    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [String]$UserName
    )

    if([System.Environment]::GetEnvironmentVariable("PSLoginUser", [System.EnvironmentVariableTarget]::Machine)) {
        $User = [System.Environment]::GetEnvironmentVariable("PSLoginUser", [System.EnvironmentVariableTarget]::Machine)
        Write-Warning -Message "Environment variable PSLoginUser already exists: $User. Do you want to replace it?"
        #$Password = [System.Environment]::GetEnvironmentVariable("PSLoginPassword", [System.EnvironmentVariableTarget]::Machine)
    }
    else {
        $User = Read-Host -Prompt "Please enter a username"
        $User = "RNR-NET\" + $User
        [System.Environment]::SetEnvironmentVariable("PSLoginUser", $User, [System.EnvironmentVariableTarget]::Machine)
    }




}