$colors = 'blue', 'darkgreen', 'magenta', 'gray', 'orange', 'maroon'

# Map the lab enviroment into clusters of related nodes, domains, address space
$Map = 'test', 'demo'| ForEach-Object {
    Import-Lab -Name $_ -NoValidation -NoDisplay
    $Lab = Get-Lab
    [pscustomobject]@{
        Cluster      = $_
        Machines     = $Lab.machines.name
        Domains      = $Lab.Domains
        AddressSpace = $lab.VirtualNetworks.addressspace.tostring()
    } 
} 

#region simple-hyperv-lab-visualization

# Simple graph to visualize labs on my HyperV host
# Get-VM -Name SRV1, SRV2  |select name, state, Notes
graph -Name SimpleHyperV `
    -Attributes @{Label = "HyperV Host [$env:COMPUTERNAME]"; font = 'verdana, bold' } `
    -ScriptBlock {
    for ($i = 0; $i -lt $Map.count; $i++) {
        SubGraph -Name $Map[$i].Cluster `
            -Attributes @{
            color = $colors[$i]
            label = "Name: {0}\nDomain: {1}\nVNet: {2}" -f $Map[$i].Cluster, $Map[$i].domains.name, $Map[$i].AddressSpace
        } `
            -ScriptBlock {
            node @{
                color = 'grey'
                # shape = 'record' 
            }

            ForEach ($machine in ($map[$i].machines)) { 
                $VM = Get-VM $machine -ErrorAction SilentlyContinue              
                if ($VM) {
                    Node -Name $Machine
                    $AssociatedTo = ([xml]$VM.notes).Associated
                    Edge -From $Machine `
                        -To $AssociatedTo
                }
            }
        }
    }
} | Export-PSGraph
#endregion simple-hyperv-lab-visualization

break;

#region hyperv-infra-connectivity
# Testing network reachability between associated nodes
graph -Name SimpleHyperV `
    -Attributes @{Label = "HyperV Host [$env:COMPUTERNAME]"; font = 'verdana, bold' } `
    -ScriptBlock {
    for ($i = 0; $i -lt $Map.count; $i++) {
        SubGraph -Name $Map[$i].Cluster `
            -Attributes @{
            color = $colors[$i]
            label = "Name: {0}\nDomain: {1}\nVNet: {2}" -f $Map[$i].Cluster, $Map[$i].domains.name, $Map[$i].AddressSpace
        } `
            -ScriptBlock {
            node @{
                color = 'grey'
                # shape = 'record' 
            }

            ForEach ($machine in ($map[$i].machines)) { 
                if (Test-Connection $machine -Quiet -Count 1) {
                    node $machine @{
                        style = 'filled'
                        color = 'darkseagreen'
                    }
                }
                else {
                    node $machine @{
                        style = 'filled'
                        color = 'indianred1'
                    }
                }
                $VM = Get-VM $machine -ErrorAction SilentlyContinue              
                # $VM = Get-VM 'democl1' -ErrorAction SilentlyContinue              
                if ($VM) {
                    Node -Name $Machine
                    $AssociatedTo = ([xml]$VM.notes).Associated
                    if ($AssociatedTo) { 
                        Write-Host "Testing connection From:`"$machine`" To:`"$AssociatedTo`"" -ForegroundColor Yellow -NoNewline                       
                        $Ping = Invoke-Command `
                            -ComputerName $machine `
                            -ScriptBlock {
                            Test-Connection $Using:AssociatedTo -Quiet -Count 1 -ErrorAction SilentlyContinue
                        }  `
                            -ErrorAction SilentlyContinue

                        if ($ping) {
                            Write-Host " [Passed]" -ForegroundColor Green
                            $EdgeColor = 'DarkGreen'
                            $EdgeLabel = 'Connected'
                        }
                        else {
                            Write-Host " [Failed]" -ForegroundColor Red
                            $EdgeColor = 'Red'
                            $EdgeLabel = 'Unreachable'                        
                        }
                    }
                    Edge -From $Machine `
                        -To $AssociatedTo `
                        -Attributes @{
                        Color = $EdgeColor
                        Label = $EdgeLabel
                    }
                }
            }
        }
    }
} | Export-PSGraph

<# 
Get-VM democl1 | Stop-VM -Verbose
# Get-VM democl1 | Start-VM -Verbose
#>
#endregion hyperv-infra-connectivity

break;

#region hyperv-infra-detailed
# add more details to the nodes like uptime, state, CPU etc
graph -Name HyperV `
    -Attributes @{Label = "HyperV Host [$env:COMPUTERNAME]" } `
    -ScriptBlock {
    for ($i = 0; $i -lt $Map.count; $i++) {
        SubGraph -Name $Map[$i].Cluster `
            -Attributes @{
            color = $colors[$i]
            label = "Name: {0}\nDomain: {1}\nVNet: {2}" -f $Map[$i].Cluster, $Map[$i].domains.name, $Map[$i].AddressSpace
        } `
            -ScriptBlock {
            ForEach ($machine in ($map[$i].machines)) { 
                $VM = Get-VM $machine -ErrorAction SilentlyContinue              
                if ($VM) {
                    Record -Name $Machine -Rows @(
                        "Cores  : {0}" -f $VM.ProcessorCount
                        "Memory : {0} GB" -f ($VM.MemoryAssigned /1gb)
                        "Uptime : {0} hours" -f $VM.Uptime.hours
                        'State  : {0}' -f $VM.State
                        # 'NetworkAdapters: {0}' -f $VM.NetworkAdapters
                    )
                    $AssociatedTo = ([xml]$VM.notes).Associated
                    if ($AssociatedTo) {   
                        Write-Host "Testing connection From:`"$machine`" To:`"$AssociatedTo`"" -ForegroundColor Yellow -NoNewline                                            
                        $Ping = Invoke-Command -ComputerName $machine -ScriptBlock {
                            Test-Connection $Using:AssociatedTo -Quiet -Count 1 -ErrorAction SilentlyContinue
                        }  -ErrorAction SilentlyContinue
                        if ($ping) {
                            Write-Host " [Passed]" -ForegroundColor Green
                            $EdgeColor = 'DarkGreen'
                            $EdgeLabel = 'Connected'
                        }
                        else {
                            Write-Host " [Failed]" -ForegroundColor Red
                            $EdgeColor = 'Red'
                            $EdgeLabel = 'Unreachable'                        
                        }
                    }
                    Edge -From $Machine `
                        -To $AssociatedTo `
                        -Attributes @{
                        Color = $EdgeColor
                        Label = $EdgeLabel
                    }
                }
            }
        }
    }
} | Export-PSGraph
#endregion hyperv-infra-detailed
