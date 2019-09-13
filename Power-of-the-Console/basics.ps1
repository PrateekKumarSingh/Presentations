Using module Polaris
Import-Module PSHTML, Polaris, Graphical, Gridify

# PSHTML 
#   Domain Specific language
#   That generates HTML document
$HTML  = html  {
    Body {
        p {
           h1 "Hello World"
        }
    }
}

# Polaris
#   Cross-platform
#   Minimalist web framework for PowerShell 
New-PolarisGetRoute -Path "/demo" -Scriptblock {
    $Response.SetContentType('text/html')
    $Response.Send($HTML)
}
Start-Polaris -Port 5555

# Graphical
$points = 1..40 | Get-Random -Count 20
Show-Graph -Datapoints $points -GraphTitle 'Bar Graph'
Show-Graph -Datapoints $points -Type Line -GraphTitle 'Line Graph'
Show-Graph -Datapoints $points -Type Scatter -GraphTitle 'Scatter Graph'


# Gridify
$process =@()
$Process += 1..5 | ForEach-Object {
    Start-Process pwsh
}

Set-GridLayout -Process $process -Layout Mosaic
Set-GridLayout -Process $process -Layout Cascade
Set-GridLayout -Process $process -Layout Vertical
Set-GridLayout -Process $process -Layout Horizontal
Set-GridLayout -Process $process -Custom "*,****"