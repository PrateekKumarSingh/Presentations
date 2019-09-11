$Path = 'D:\Workspace\Repository\Psconfasia2019\Visualize-Document-Infrastructure' 
Set-Location $Path -ErrorAction SilentlyContinue

# verify dependent modules are loaded
$DependentModules = 'PSGraph', 'PSGraphPlus','Polaris', 'PSHTML', 'PoshRSJob', 'PowerShellForGithub', 'az'
$Installed = Import-Module $DependentModules -PassThru -ErrorAction SilentlyContinue| Where-Object { $_.name -In $DependentModules }
$missing = $DependentModules | Where-Object { $_ -notin $Installed.name }
if ($missing) {
    Write-host "    [+] Module dependencies not found [$missing]. Attempting to install." -ForegroundColor Green
    Install-Module $missing -Force -AllowClobber -Confirm:$false
    Import-Module $missing
}

# start required virtual machines 
$VM = 'DC1','SRV1','SRV2', 'democl1', 'democl2', 'demodc', 'mylabcl1','mylabcl2','mylabdc1'
Get-VM -Name $VM | 
Where-Object {$_.State -ne 'Running'} -ov stopped 
# else{
if($stopped){
    $stopped | 
    ForEach-Object {
        Start-VM -Name $_.Name -Verbose | Out-Null
    }

}

# set defaults
$Username = 'Administrator'
$Password = '01000000d08c9ddf0115d1118c7a00c04fc297eb01000000724d09ce0305f244968c56f654c1f8f3000000000200000000001066000000010000200000006b236ad161d6f60f3243cfec67fb1bc6d59b9d9baa07cffc5f057a5a29760be5000000000e80000000020000200000002f895322341c56add38fbb33158d74a389a3a4d72ca26f0038a1e0edf99495db20000000e7900470fe7a6e92c467a2eb26884ac70695138c191fc1bf99e3194820203f8b40000000458a82feded8ad1ecc0b9d8a622aaf49469a9d03ded8f6b009ab896d6e0268902a5b67a1c6d885f8a4e1e8d4880b7b7d649b4784e8eb48be6d0432ca2c547324'
$Creds = [pscredential]::new($Username, ($Password | ConvertTo-SecureString))
$PSDefaultParameterValues['Export-PSGraph:DestinationPath'] = "$env:TEMP\output.png"
$PSDefaultParameterValues['Invoke-Command:Credential'] = $Creds
Set-GitHubConfiguration -DisableTelemetry

# open an empty graph
Graph demo {
} | Export-PSGraph -ShowGraph | Out-Null

Clear-Host
Describe "Setup" {
    it 'Check current working directory' {
        (Get-Location).Path -eq $Path | Should be $true
    }
    it 'Check required modules' {
        $DependentModules = 'PSGraph','Polaris', 'PSHTML', 'PoshRSJob', 'PowerShellForGithub', 'az'
        (Import-Module $DependentModules -PassThru -ErrorAction SilentlyContinue).count -eq $DependentModules.count | Should be $true
    }
    it 'Check Azure Context' {
        (Get-AzContext) -as [bool] | Should Be $true
    }

    it 'Check PSDefaultParameter Values' {
        $PSDefaultParameterValues['Export-PSGraph:DestinationPath'] -eq "$env:TEMP\output.png"| Should be $true
        $PSDefaultParameterValues['Invoke-Command:Credential'] -eq $Creds| Should be $true
    }
    it 'Check Github Telemetry' {
        Get-GitHubConfiguration -Name DisableTelemetry  | Should be $true
    }
    
    
    Foreach($V in (Get-VM $VM)){
       it "Check Virtual Machine: $($v.Name) is Running" {
            $_.state -eq 'running'
        }
    }
}
