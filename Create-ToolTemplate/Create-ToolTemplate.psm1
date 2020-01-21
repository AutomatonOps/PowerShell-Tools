
function Create-ToolTemplate {
    param(
        [Parameter(Mandatory=$True)]
        [String]$Name
    )

$String = @'
<#
.SYNOPSIS
###more text
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory$=True,
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True,
               HelpMessage="The first parameter")]
    [Alias('Hostname', 'cn')]
    [String[]]$ComputerName
)

foreach($Computer in $ComputerName) {
    try {
        $CimSession = New-CimSession $ComputerName $Computer -ErrorAction Stop
        ###more code


        $Properties @{
            ComputerName = $Computer
            ###more properties
        }
    }
    catch {
        Write-Verbose "Couldn't connect to $Computer"
        $Properties @{
            ComputerName = $Computer
            ###more properties
        }
    }
    finally {
        Remove-CimSession $CimSession
        $Output = New-Object -TypeName PSObject -Property $Properties
        Write-Output $Output
    }
}
'@

$String | Out-File -FilePath ".\$Name.ps1"

}