# Intall-Module PSHTML, Polaris, Graphical, Gridify
Import-Module PSHTML, Polaris, Graphical, Gridify

# PSHTML 
#   Domain Specific language
#   That generates HTML document
$HTML = html {
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
    # web server returns are $response
    # to your web request
    $Response.SetContentType('text/html') 
    $Response.Send($HTML)
}
Start-Polaris -Port 5555


# Graphical
# points data points on a 2D graph 
# inside powershell console
$PSDefaultParameterValues["Show-Graph:YAxisStep"] = 25
$points = 1..99 | Get-Random -Count 20
Show-Graph -Datapoints $points -GraphTitle 'Bar Graph'
Show-Graph -Datapoints $points -Type Line -GraphTitle 'Line Graph'
Show-Graph -Datapoints $points -Type Scatter -GraphTitle 'Scatter Graph'


# Gridify
# set Running PowerShell consoles/ Applications
# to automatic grid.
$process = @()
$Process += 1..5 | ForEach-Object {
    Start-Process pwsh -PassThru
}

Set-GridLayout -Process $process -Layout Mosaic
Set-GridLayout -Process $process -Layout Vertical
Set-GridLayout -Process $process -Custom "*,***,*"

## Back to slides!