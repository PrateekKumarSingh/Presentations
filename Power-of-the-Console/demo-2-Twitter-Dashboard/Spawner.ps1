param(
    [Parameter(Position=0)] [String[]] $Keywords = @('aws','linux','devops','pwsh','azure'),
    [Parameter(Position=1)][int] $Count = 10,
    [Parameter(Position=2)][String] $CustomLayout,
    [Parameter(Position=3)]$MaxStepsOnYAxis = 3,
    [Parameter(Position=4)]$MaxStepsOnXAxis = 20,
    [Switch] $IncludeSource
)

$ErrorActionPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Start-Process:Passthru']= $true
Import-Module Gridify

Write-Host "[+] Searching Keywords: $Keywords" -ForegroundColor Green   
Write-Host "[+] Configuring pwsh.exe with fresh API Keys" -ForegroundColor Green   

& 'C:\Program Files\PowerShell\7-preview\pwsh.exe' -Command { 
    Import-Module pscognitiveservice
    if(Get-Sentiment 'good'){exit}
    New-LocalConfiguration -FromAzure -AddKeysToProfile
}

$Processes = @() # empty array to hold [System.Diagnostics.Process] objects
$Keywords | ForEach-Object {
    Write-Host "[+] Starting a process to search keword: $_" -ForegroundColor Green   
    $Arguments = '-File Get-Tweet.ps1 "{0}" {1}' -f $_, $Count
    $Processes += Start-Process pwsh.exe $Arguments
}

$Processes += Start-Process pwsh.exe
$Processes += Start-Process pwsh.exe "-File Invoke-PerfMon.ps1 -Processor -PhysicalMemory -MaxStepsOnYAxis $MaxStepsOnYAxis -MaxStepsOnXAxis $MaxStepsOnXAxis"
$Processes += Start-Process pwsh.exe "-File Invoke-PerfMon.ps1 -EthernetSend -DiskWrite -MaxStepsOnYAxis $MaxStepsOnYAxis -MaxStepsOnXAxis $MaxStepsOnXAxis"

Start-Sleep -Seconds 2

if($CustomLayout){
    Set-GridLayout -Process $Processes -Custom $CustomLayout -Verbose -IncludeSource:$IncludeSource
}
else{
    Set-GridLayout -Process $Processes -Layout Mosaic -Verbose -IncludeSource:$IncludeSource
}