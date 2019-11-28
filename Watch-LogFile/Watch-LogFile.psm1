function Watch-LogFile {
    <#
    .SYNOPSIS
        Continously monitors contents of a given file
    .EXAMPLE
        Watch-LogFile -Path C:\log.txt -Last 10
    #>

    [cmdletbinding()]
    Param(
        [parameter(Mandatory)][string] $Path,
        [int32]$Last = 1,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

        try {
            Test-Path -Path $Path -ErrorAction Stop -InformationAction Ignore
            Get-Content -Path $Path -Tail $Last -Wait -Credential $Credential
        }
        catch {
            Write-Error -Message $error[0]
        }
}
