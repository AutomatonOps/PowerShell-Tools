function Test {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True)]
        [string[]]$ComputerName,
        [switch]$lmao
    )



    
    BEGIN {
      Write-Host -ForegroundColor Green (Get-Date) "Beginning?"
      Import-Module Test-CIMPing
      $Result = @()
    } #begin

    PROCESS {
      Write-Host -ForegroundColor Magenta (Get-Date) "Processing?" $ComputerName

      ForEach ($Computer in $ComputerName) {
        Write-Host (Get-Date) -ForegroundColor Blue "ForEach()ing?" $Computer

        Try {
          #Do stuff...
          $Result += Test-CIMPing -ComputerName $Computer
        }

        Catch {

          Write-Host "Lmao an error! ${$_.Exception.Message}"

        }
      }



    } #process

    END {
      Write-Host -ForegroundColor Red (Get-Date) "Ending?"

      #$Result | Receive-Job -Wait -AutoRemoveJob | Write-Output
      $Result | Write-Output
    } #end

} #function