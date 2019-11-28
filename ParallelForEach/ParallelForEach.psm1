function ParallelForEach {
    <#
    .SYNOPSIS
        Creates a runspace for every object in the pipeline and then executes the process block simultaneously
    .EXAMPLE
        (Measure-Command {
            1..100 | ParallelForEach { sleep 1; $_ }
        }).TotalSeconds
    #>



        param([scriptblock]$Process, [parameter(ValueFromPipeline)]$InputObject)
        $runspaces = $Input | ForEach-Object {
            $r = [PowerShell]::Create().AddScript("param(`$_);$Process").AddArgument($_)
            [PSCustomObject]@{ Runspace = $r; Handle = $r.BeginInvoke() }
        }
        $runspaces | ForEach-Object { 
            while (!$_.Handle.IsCompleted) { Start-Sleep -m 100 }
            $_.Runspace.EndInvoke($_.Handle)
        }
}


