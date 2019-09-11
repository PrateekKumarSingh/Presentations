# Install-Module -Name PoshRSJob -Force -Confirm:$false
Import-Module -Name PoshRSJob
Get-RSJob | Remove-RSJob # clean jobs
function Invoke-Tracert {
    param([string]$RemoteHost)
    tracert $RemoteHost | ForEach-Object {
        if ($_.Trim() -match "Tracing route to .*") {
            Write-Host $_ -ForegroundColor Yellow
        }
        elseif ($_.Trim() -match "^\d{1,2}\s+" -and $_.trim() -notlike "*Request timed out*") {
            $hop, $packet1, $packet2, $packet3, $target, $null = $_.Trim() -split "\s{2,}"
            $target -match '(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}'|Out-Null

            $Properties = @{
                Hop    = $hop;
                First  = $($packet1 -replace " ms",'' -replace "<","LessThan ")
                Second = $($packet2 -replace " ms",'' -replace "<","LessThan ")
                Third  = $($packet3 -replace " ms",'' -replace "<","LessThan ")
                Node   = $Matches[0]
                Hostname = ($target -Replace "\s{1}\[$($Matches[0])\]","").trim()
            }
            New-Object psobject -Property $Properties
        }
    }
}
Function AddColor($data,$Threshold) { 
    if([int](($data -replace "LessThan ","" -replace "\*","").trim()) -lt $Threshold){ 
        "<font color='DarkGreen'>$data</font>" 
    }
    else{ 
        "<font color='Red'>$data</font>"
    }
}

$RemoteHosts = 'gmail.com', 'docs.microsoft.com', 'twitter.com'
$RemoteHosts| 
Start-RSJob -Name { $_ } `
            -ScriptBlock ${function:Invoke-tracert} `
            -ArgumentList $_ -Verbose |
Wait-RSJob -ShowProgress

$colors = 'blue', 'darkgreen','magenta', 'gray', 'orange', 'maroon'
$colorcounter = 0
Graph tracert {
    $Start = $Env:COMPUTERNAME
    node $Start @{shape = 'oval';style='filled';color='darkseagreen'}
    node @{shape = 'rect' }
    # iterate through each remote hosts
    Foreach ($RemoteHost in $RemoteHosts) {
        node $RemoteHost.ToUpper() @{
            shape="oval";Style="filled" ;color = "indianred1"
        }
        $Nodes = @()
        $Nodes = Receive-RSJob $RemoteHost |
        Where-Object { $_.node -notlike "*Request timed out*" } 

        # edge from source machine to first-hop
        edge $Start $Nodes[0].Node @{
            color = $colors[$colorcounter]; Label= ' Start' 
        }

        for ($i = 0; $i -lt $Nodes.count; $i++) {
            Record "$($Nodes[$i].Node)" -ScriptBlock {
                Row -Label "<b>Hostname    : $($Nodes[$i].Hostname)</b>"
                Row -Label "<b>Packet1(ms) : $(AddColor $Nodes[$i].first 10)</b>"
                Row -Label "<b>Packet2(ms) : $(AddColor $Nodes[$i].second 10)</b>"
                Row -Label "<b>Packet3(ms) : $(AddColor $Nodes[$i].third 10)</b>"
            }
            edge -From $Nodes[$i].Node `
                 -to $Nodes[$i + 1].Node `
                @{
                    Label={" hop-{0}" -f ($i+1)}
                    color = $colors[$colorcounter]
                }
        }
        # edge from last-hop to remote host
        edge $($Nodes[$($Nodes.count - 1)].Node) $RemoteHost.toUpper() @{
            color = $colors[$colorcounter]; 
            Label= 'End'
        }
        $colorcounter++
    }
} | Export-PSGraph