function Remove-Session {
    <#
    .SYNOPSIS
        Allows to easily close a remote session by providing a ComputerName and a UserName
        If no -ComputerName is provided it will default to the localhost.
    .EXAMPLE
        Remove-Session -ComputerName PC01 -UserName User01
    #>


    [cmdletbinding()]
    Param(
        [string[]]$ComputerName = "localhost",
        [string[]]$UserName,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )


        foreach($Computer in $ComputerName) {
            $QUser = quser /server:$Computer
            foreach($User in $UserName) {
                try {

                    $SessionId = (($QUser | Where-Object { $_ -match $User }) -split ' +')[2]
                    rwinsta $SessionId /server:$Computer

                }
                catch {
                    Write-Warning -Message "Something went wrong."
                    $error[0]
                }
            }

        }
}