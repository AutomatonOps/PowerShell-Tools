#Used to quickly swap between cntlm.ini files to either use or bypass proxy.
function Enable-Cntlm {
    Copy-Item -Path 'C:\Program Files (x86)\Cntlm\cntlm.ini.sophos' -Destination 'C:\Program Files (x86)\Cntlm\cntlm.ini' -Verbose
    Get-Service -Name 'cntlm' | Stop-Service -Verbose
    Start-Service -Name 'cntlm' -Verbose -PassThru
}

function Disable-Cntlm {
    Copy-Item -Path 'C:\Program Files (x86)\Cntlm\cntlm.ini.noproxy' -Destination 'C:\Program Files (x86)\Cntlm\cntlm.ini' -Verbose
    Get-Service -Name 'cntlm' | Stop-Service -Verbose
    Start-Service -Name 'cntlm' -Verbose -PassThru 
}