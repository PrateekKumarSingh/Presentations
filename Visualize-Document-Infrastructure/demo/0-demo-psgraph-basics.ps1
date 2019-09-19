# install PSGraph module from PowerShell gallery
Install-Module PSGraph -Verbose -Confirm:$false
Import-Module PSGraph

Get-Command -Module PSGraph

# install GraphViz from the Chocolatey repo
Install-GraphViz -Verbose -Confirm:$false 

# generate your first graph
graph 'name' {
    Edge first, second, third
} | Export-PSGraph -DestinationPath $env:TEMP\output.png

#region simple-family-tree

# adding nodes to a graph
graph 'myfamily' {
    node mother
    Edge -From father -To daughter, son
    Edge -From mother -To daughter, son
} | Export-PSGraph

# node and edge attributes
graph 'myfamily' {
    node mother -Attributes @{
        shape="rect"
    }
    Edge -From father -To daughter, son -Attributes @{color='blue'}
    Edge -From mother -To daughter, son -Attributes @{color='magenta'}
} | Export-PSGraph

# generic nodes and edges
graph 'myfamily' {
    # generic node without a name for all the node defined below
    # attributes apply to all nodes
    node @{ shape= 'diamond'; style= 'filled'; color = 'grey'} 
    node mother -Attributes @{
        shape="rect"
        color='yellowgreen'
    }
    Edge -From father -To daughter, son -Attributes @{color='blue'}
    Edge -From mother -To daughter, son -Attributes @{color='magenta'}
    
    # generic edge for all the edges defined below
    # i.e, top to down processing
    edge @{ style='dashed'; color = 'black';} 
    Edge -From father -To uncle
} | Export-PSGraph

# ranking nodes
graph 'myfamily' {
    node @{ shape= 'diamond'; style= 'filled'; color = 'grey'; comment ='test'} 
    node mother -Attributes @{
        shape="rect"
        color='yellowgreen'
    }
    Edge -From father -To daughter, son -Attributes @{color='blue'}
    Edge -From mother -To daughter, son -Attributes @{color='magenta'}
    edge @{ style='dashed'; color = 'black';} 
    Edge -From father -To uncle

    # rank them on same level
    rank -Nodes mother, father, uncle
} | Export-PSGraph

# graph attributes like, rankdir and label
graph 'myfamily' @{rankdir="LR";label='family tree'} {
    node @{ shape= 'diamond'; style= 'filled'; color = 'grey'; comment ='test'} 
    node mother -Attributes @{
        shape="rect"
        color='yellowgreen'
    }
    Edge -From father -To daughter, son -Attributes @{color='blue'}
    Edge -From mother -To daughter, son -Attributes @{color='magenta'}
    edge @{ style='dashed'; color = 'black';} 
    Edge -From father -To uncle
    rank -Nodes mother, father, uncle
} | Export-PSGraph

# graph and subgraphs
graph 'biggerfamily' @{label='bigger family'} {
    SubGraph myfamily @{label='My family'} {
        Edge -From father -To daughter, son
        Edge -From mother -To daughter, son
    }
    SubGraph unclefamily @{label="Uncle's family"} {
        Edge -From uncle, aunty -To cousin
    }
    
    edge @{constraint=$false}
    Edge -From father -To uncle @{style='dashed'}
} | Export-PSGraph
#endregion simple-family-tree

break;

#region simple-usecases

# a simple expression in Abstract Syntax tree
Import-Module PSGraphPlus # import this helper module
$expression = {(2*15)/3}
# $expression = {((2*15/(1+7))/3)*(11+5)}
Show-AstGraph -ScriptBlock $expression -Raw | Export-PSGraph

break;

# directory tree
. .\demo\src\Get-FolderSize.ps1

$directory = 'D:\Workspace\Repository\PSCognitiveService'
$heatmapcolors = "#FF0000","#FF0500","#FF1000","#FF2000","#FF2500","#FF3000","#FF3500","#FF4000","#FF4500","#FF5000","#FF5500","#FF6000","#FF6500","#FF7000","#FF7500","#FF8000","#FF8500","#FF9000","#FF9500","#FFA000","#FFA800","#FFB000","#FFB800","#FFC000","#FFC800","#FFD000","#FFD800","#FFE000","#FFE800","#FFF000","#FFF800","#FFFF00", "#F5FF00","#F0FF00","#E5FF00","#E0FF00","#D5FF00","#D0FF00","#C5FF00","#C0FF00","#B5FF00","#B0FF00","#A5FF00","#A0FF00","#95FF00","#90FF00","#95FF00","#85FF00","#80FF00","#75FF00","#70FF00","#65FF00","#60FF00","#55FF00","#50FF00","#45FF00","#40FF00","#35FF00","#30FF00","#25FF00","#20FF00","#15FF00","#10FF00"
$folders = Get-ChildItem -Path $directory `
                         -Recurse `
                         -ErrorAction SilentlyContinue -Depth 2|
            Where-Object PSIsContainer |
            Select-Object *, @{
                n='Size'
                e={
                    [int](Get-FolderSize $_.fullname).size
                }
            } |
            Sort-Object Size -Descending

$i=0
$Step = [math]::Ceiling(($heatmapcolors.count/$folders.Count))
graph TreeSize @{fontname = "verdana" } {
    node @{shape = 'folder' }
    # node $folders -NodeScript { $_.fullname } @{label = {$_.basename}} 
    node $folders -NodeScript { $_.fullname } @{
        label = {
            $SizeUnit = ''
            if ($_.Size -ge 1GB) {
                 $SizeUnit = 'Gb'
            }
            elseif ($_.Size -ge 1Mb) { 
                $SizeUnit = 'Mb'
            }
            elseif ($_.Size -ge 1kb) {
                 $SizeUnit = 'Kb'
                }
            if($SizeUnit){
                "{2}\n[{0:N2} {1}]" -f ($_.Size/(Invoke-Expression "1$SizeUnit")), $SizeUnit, $_.basename
            }
            else{
                "{1}\n[{0} Bytes]" -f $_.Size, $_.basename
            }    
        }
        style='filled'
        color={$heatmapcolors[$i];$i=$i+$Step}
        fontname = "verdana, bold" ;
        fontsize = 11
    } 
    edge $folders `
        -FromScript { split-path $_.fullname } `
        -ToScript { $_.fullname } 
} | ForEach-Object { $_.replace('\', '\\').replace('\\n', '\n') } |
Export-PSGraph

break;

# Network connections - Local to Remote
$netstat = Get-NetTCPConnection -State Established|
           Where-Object LocalAddress -NotIn ':','127.0.0.1'

graph network @{rankdir = 'LR'; label = 'Network Connections' } {
    Node @{shape = 'rect' }
    Edge -Node $netstat `
         -FromScript { $_.LocalAddress} `
         -ToScript   { $_.RemoteAddress} `
         -Attributes @{label = {
             '{0}:{1}\n[{2}]' -f $_.LocalPort, $_.RemotePort, (Get-Process -id $_.OwningProcess).name
            }
        }
    $netstat.LocalAddress+$netstat.RemoteAddress |
    Select-Object -Unique|
    Select-Object -First 5 |
    ForEach-Object {
        Write-Host "Resolving DNS Name for: $($_)" -ForegroundColor Yellow -NoNewline
        $Name = (Resolve-DnsName $_ -ErrorAction SilentlyContinue).namehost |
                Select-Object -First 1
        if($Name){
            Write-Host " [$name]" -ForegroundColor Green
            Node $_ @{label={"{0}\n[{1}]" -f $_, $name}}
        }
        else{
            Write-Host " [None]" -ForegroundColor Red
            Node $_ @{label={"{0}" -f $_}}
        }
    }
} | Export-PSGraph

#endregion simple-usecases