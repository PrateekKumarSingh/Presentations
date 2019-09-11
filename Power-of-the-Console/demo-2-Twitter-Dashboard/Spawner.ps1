param(
    [Switch] $IncludeSource,
    [String[]] $Keywords = @("#PowerShell", "#Azure", "Python"),
    [int] $NumberOfTweets = 100,
    [String] $CustomLayout
)

$ErrorActionPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Start-Process:Passthru']= $true
Import-Module Gridify

$Processes = @() # empty array to hold [System.Diagnostics.Process] objects
$Keywords | ForEach-Object {
    Write-Host "[+] Starting a process to search keword: $_" -ForegroundColor Green   
    $Arguments = '-File Get-TwitterStatus.ps1 "{0}" {1}' -f $_, $NumberOfTweets
    $Processes += Start-Process pwsh.exe $Arguments
}
$Processes += Start-Process pwsh.exe
$Processes += Start-Process pwsh.exe '-File Invoke-PerfMon.ps1 -Processor -PhysicalMemory -VirtualMemory -MaxStepsOnYAxis 3'
$Processes += Start-Process pwsh.exe '-File Invoke-PerfMon.ps1 -EthernetSend -EthernetReceive -DiskWrite -MaxStepsOnYAxis 3'

Start-Sleep -Seconds 2

if($CustomLayout){
    Set-GridLayout -Process $Processes -Custom $CustomLayout -Verbose -IncludeSource:$IncludeSource
}
else{
    Set-GridLayout -Process $Processes -Layout Mosaic -Verbose -IncludeSource:$IncludeSource
}