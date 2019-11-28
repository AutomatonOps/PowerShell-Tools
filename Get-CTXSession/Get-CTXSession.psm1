function Get-CTXSession() {
   <#
    .SYNOPSIS
        Gets a list of all CTX sessions for a given application
    .EXAMPLE
        Get-CTXSession -UserName User01 -Application RadCentre
    #>


    Param(
        [parameter(Mandatory)][string[]]$UserName,
        [string[]]$Application = @("Mosaiq", "RadCentre", "xVianova"),
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )    
    
    forEach( $app in $Application ) {
    	$hostnames = "\\fil-zz-rz1-sv03\dfs\group\ag-it\DavidHallmann\AUTOMATION\Tools\Get-CTXSession\Servers\$App.txt"
 
    	forEach( $hostname in ( Get-Content -Path $hostnames ) ) {
        
        	$query = ((quser /server:$hostname) -replace '^>', '') -replace '\s{2,}', ',' | ConvertFrom-Csv | Where-Object -FilterScript {$_.BENUTZERNAME -match $username}
        	$query | Add-Member -MemberType NoteProperty -Name "SERVER" -Value $hostname 
        	$query
    	}
    }
}


