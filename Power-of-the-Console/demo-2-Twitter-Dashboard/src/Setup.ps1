Get-AzCognitiveServicesAccount | Remove-AzCognitiveServicesAccount -Verbose -Force
# make sure is azure portal is logged on
$Modules = 'PSCognitiveService','Graphical','Gridify','PSHTML','Polaris'
Import-Module $Modules -PassThru
Set-Location .\PSConfAsia2019\Power-of-the-Console -ErrorAction SilentlyContinue