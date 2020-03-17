function Get-LoggedInUser
{
<#
    .SYNOPSIS
        Shows all the users currently logged in

    .DESCRIPTION
        Shows the users currently logged into the specified computernames

    .PARAMETER ComputerName
        One or more computernames

    .EXAMPLE
        PS C:\> Get-LoggedInUser
        Shows the users logged into the local system

    .EXAMPLE
        PS C:\> Get-LoggedInUser -ComputerName server1,server2,server3
        Shows the users logged into server1, server2, and server3

    .EXAMPLE
        PS C:\> Get-LoggedInUser  | where idletime -gt "1.0:0" | ft
        Get the users who have been idle for more than 1 day.  Format the output
        as a table.

        Note the "1.0:0" string - it must be either a system.timespan datatype or
        a string that can by converted to system.timespan.  Examples:
            days.hours:minutes
            hours:minutes
#>

    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String[]]$ComputerName = $env:COMPUTERNAME
    )

    $out = @()

    ForEach ($computer in $ComputerName)
    {
        try { if (-not (Test-Connection -ComputerName $computer -Quiet -Count 1 -ErrorAction Stop)) { } }#Write-Warning "Can't connect to $computer"; continue } }
        catch { Write-Warning "Can't test connect to $computer"; continue }

        #fix quser error: https://www.adilhindistan.com/2014/01/fixing-quser-access-is-denied-error.html
        Invoke-Command -ComputerName $computer -Command { Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name AllowRemoteRPC  -Value 0x1 -Force }

        $quserOut = quser.exe /SERVER:$computer 2>&1
        if ($quserOut -match "No user exists")
        { Write-Warning "No users logged in to $computer";  continue }


$Template = @'
BENUTZERNAME          SITZUNGSNAME       ID  STATUS  LEERLAUF   ANMELDEZEIT
{UserName*:gpt-fnk-ada-6}         ica-tcp#0           9  {Status:Aktiv}          32  19.04.2019 08:13
{UserName*:a-02915}               console             1  {Status:Aktiv}       Kein   19.04.2019 20:11
{UserName*:da-keil}               console             1  {Status:Aktiv}       Kein   19.04.2019 20:11
{UserName*:oa-klee}               console             1  {Status:Aktiv}       Kein   19.04.2019 20:11
{UserName*:gpt-fnk-ada-6}         ica-tcp#0           9  {Status:Getr.}          32  19.04.2019 08:13
{UserName*:a-02915}               console             1  {Status:Getr.}       Kein   19.04.2019 20:11
{UserName*:da-keil}               console             1  {Status:Getr.}       Kein   19.04.2019 20:11
{UserName*:oa-klee}               console             1  {Status:Getr.}       Kein   19.04.2019 20:11
'@
        
        
        $users = $quserOut | ConvertFrom-String -TemplateContent $Template -ErrorAction SilentlyContinue #| Select-Object -ExpandProperty User

        $out += $users
    }
    Write-Output $out
}