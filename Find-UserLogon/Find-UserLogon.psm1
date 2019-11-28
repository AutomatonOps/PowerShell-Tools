function Find-UserLogon
{
<#
    .SYNOPSIS
        Searches the logon.log for a specific user and extracts the last recorded hostname

    .DESCRIPTION
        Finds out where a user is currently logged in

    .PARAMETER UserName
        One or more usernames

    .EXAMPLE
        PS C:\> Find-UserLogon user01
        Finds out where user01 is currently logged in

    .EXAMPLE
        PS C:\> Find-UserLogon user01, user02, user03
        Finds out where user01, user02 and user03 are currently logged in
#>

    [CmdletBinding()]
    param
    (
        #[ValidateNotNullOrEmpty()]
        #[Parameter(Mandatory)]
        [String[]]$Name,
        [String[]]$UserName,
        [Switch]$OnlyActive
    )

 
    #If we are searching for a person rather than account name, do some juggling first...
    if($Name) {
        $UserName = @()
        foreach($Person in $Name) {
            try {
                $UserName = Get-ADUser -Filter "SurName -like '*$Name*' -or GivenName -like '*$Name*'" | Select-Object -ExpandProperty SamAccountName
            }
            catch {
                throw
            }
        }
    }




    $Result = Select-String -Path "\\fil-zz-rz1-sv03\Logon$\Logon.log" -Pattern $UserName | Select-Object -ExpandProperty Line -Unique 


    foreach($entry in $Result) 
    {
        $Split = $entry.Split()

        #Check if user is actually logged on
        if($OnlyActive) {
            if($Split[0] -eq "logoff") {
                continue
            }
            if(!(Get-LoggedInUser -ComputerName $Split[2] -WarningAction SilentlyContinue | Where-Object { $_.UserName -eq $Split[1] })) {
                continue
            }
        }

        $User = Get-ADUser -Identity $Split[1]

        $Out = [PSCustomObject]@{
            Type = $Split[0]
            UserName = $Split[1]
            ComputerName = $Split[2]
            SurName = $User.SurName
            GivenName = $User.GivenName
        }
        Write-Output $Out
    }
    
}