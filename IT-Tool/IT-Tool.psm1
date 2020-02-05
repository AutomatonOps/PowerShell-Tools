##All kinds of code for the IT-Tool

function LoadAssemblies {
    [System.Reflection.Assembly]::LoadFrom('\\ATM-IT-RZ1-SV01\IT-Tool\Assets\WPF\MaterialDesignThemes.Wpf.dll') | Out-Null
    [System.Reflection.Assembly]::LoadFrom('\\ATM-IT-RZ1-SV01\IT-Tool\Assets\WPF\MaterialDesignColors.dll') | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
}

function Show-Console
{
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '

    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 5) #5 show
}

function Hide-Console
{
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '
    
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0) #0 hide
}

function Read-CredentialsFromDisk
{
    $FileName = Get-ChildItem -Path 'C:\.credstore\' | Select-Object -ExpandProperty Name
    $UserName = "RNR-NET\$($FileName.Replace('.cred', ''))"
    $SecureString = Get-Content -Path "C:\.credstore\$FileName" | ConvertTo-SecureString
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $SecureString
    Write-Output $Credential
}