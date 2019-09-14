$Path = 'D:\Workspace\Repository\Presentations\Power-of-the-Console' 
Set-Location $Path -ErrorAction SilentlyContinue

# verify dependent modules are loaded
$DependentModules = 'PSCognitiveService', 'Pester', 'Gridify','Graphical', 'PSHTML', 'Polaris', 'az', 'PSWordCloud','PSTwitterAPI'
$Installed = Import-Module $DependentModules -PassThru -ErrorAction SilentlyContinue| Where-Object { $_.name -In $DependentModules }
$missing = $DependentModules | Where-Object { $_ -notin $Installed.name }
if ($missing) {
    Write-host "    [+] Module dependencies not found [$($missing -Join ', ')]. Attempting to install." -ForegroundColor Green
    Install-Module $missing -Force -AllowClobber -Confirm:$false -Verbose
    Import-Module $missing -Verbose
}

# Clear-Host
Describe "Setup" {
    it 'Check PowerShell-7' {
        $PSVersionTable.PSVersion.Major -eq 7 | Should be $true
    }    
    it 'Check current working directory' {
        (Get-Location).Path -eq $Path | Should be $true
    }
    it  "Check required modules" {
        (Import-Module $DependentModules -PassThru -ErrorAction SilentlyContinue).count -eq $DependentModules.count | Should be $true
    }
    it 'Check Azure Login' {
        (Get-AzContext) -as [bool] | Should Be $true
    }
    it 'Check Progress Preference' {
        $ProgressPreference = 'SilentlyContinue'
        $ProgressPreference -eq 'SilentlyContinue' | Should Be $true
    }
    it 'Check C:\Temp is empty' {
        Get-ChildItem C:\temp | Remove-Item -Force
        !(Get-ChildItem C:\temp) | Should Be $true
    }
    it 'Check .\demo-2-Twitter-Dashboard\data\ is empty' {
        Get-ChildItem .\demo-2-Twitter-Dashboard\data\  | Remove-Item -Force
        !(Get-ChildItem .\demo-2-Twitter-Dashboard\data\ ) | Should Be $true
    }
}
