#region Demo-2.1-One-to-Many-Port-Connectivity
$Scriptblock = {
    # list all computers in a domain
    $destination = Get-ADComputer -Filter * -Properties * |
    Where-Object DistinguishedName -NotLike "*Domain*Controllers*" |
    Select-Object name, IPV4Address

    $ports = 80, 139, 445
  
    # test ports from source machine to the destination machines
    Foreach ($port in $ports) {
        Foreach ($target in $destination.Name) {
            Write-host "Testing Port:`"$port`" Source:`"$env:COMPUTERNAME`" to Destination:`"$($Target)`"" -ForegroundColor Yellow -NoNewline
            Test-NetConnection $target -Port $port  -WarningAction SilentlyContinue -OutVariable conn
            If($Conn.TcpTestSucceeded){
                Write-Host " [Passed]" -ForegroundColor Green
            }
            else{
                Write-Host " [Failed]" -ForegroundColor Red
            }
        }
    }
}

$Net = Invoke-Command -ComputerName DC1 -ScriptBlock $Scriptblock

graph network @{rankdir = 'LR' } {
    node @{shape = 'rect' }
    edge $Net -FromScript { $_.PSComputerName } `
        -ToScript { $_.ComputerName } `
        -Attributes @{
        label     = { $_.RemotePort }
        fontcolor = {
            if ($_.TcpTestSucceeded) {
                'Green'
            }
            else {
                'Red'
            }
        }
    }  
} | Export-PSGraph

#endregion Demo-2.1-One-to-Many-Port-Connectivity

break;
#region Demo-2.2-Many-to-Many-Port-Connectivity

$Servers = 'dc1', 'srv1', 'srv2'
$results = @() # empty array to store telnet results

# create a array of [PSCustomObject] with many-to-many server mappings
$Map = For ($i = 0; $i -lt $Servers.Count; $i++) {
    [PSCustomObject]@{
        Source      = $Servers[$i]
        Destination = For ($j = 0; $j -lt $Servers.Count; $j++) {
            if ($i -ne $j) {
                $Servers[$j]
            }
        }
    }
}

# iterate through all objects 
# and perform telnet from each 'source' to 'destination'
# for a specific port
Foreach ($Item in $Map) {
    $Scriptblock = {
        $Ports = 80, 139, 445, 3389
        # test ports from source machine to the destination machines
        Foreach ($port in $ports) {
            Foreach ($destination in $Using:Item.Destination) {
                Write-host "Testing Port:`"$port`" Source:`"$env:COMPUTERNAME`" to Destination:`"$($Destination)`"" -ForegroundColor Yellow -NoNewline
                Test-NetConnection $destination -Port $port -WarningAction SilentlyContinue -OutVariable conn
                If($Conn.TcpTestSucceeded){
                    Write-Host " [Passed]" -ForegroundColor Green
                }
                else{
                    Write-Host " [Failed]" -ForegroundColor Red
                }
            }
        }
    }
    $Temp = Invoke-Command -ComputerName $Item.Source `
    -ScriptBlock $Scriptblock
    $results += $temp             
}

<#
$results | 
    Sort-Object PSComputerName | 
    Format-Table PSComputerName, `
                 ComputerName, `
                 RemotePort, `
                 TcpTestSucceeded
#>

$colors = 'grey', 'black', 'cornflowerblue'
$i = 0
graph network {
    node @{shape = 'rect' }
    Foreach ($Item in ($results | Group-Object PSComputerName)) {
        $Group = $Item.Group
        $Color = $colors[$i]
        ForEach ($GroupItem in $Group) {

            Edge -From $GroupItem.PSComputerName `
                -To $GroupItem.ComputerName -Attributes @{
                Label     = " $($GroupItem.RemotePort)"
                fontcolor = {
                    if ($GroupItem.TcpTestSucceeded) {
                        'DarkGreen'
                    }
                    else {
                        'Red'
                    }
                }
                Color     = $Color
            }
        }
        $i++
    }
} | Export-PSGraph
#endregion Demo-2.2-Many-to-Many-Port-Connectivity