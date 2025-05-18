#region simple-static-organization-chart
# a simple (static) org tree

Graph org {
    # malissa, Bob report to John
    edge -From John -to Malissa, Bob
    edge -From Malissa -to Rakesh, Sam, Joanah
    edge -From Bob -to Charlie, Mandie, Joel
} | Export-PSGraph 

#endregion simple-static-organization-chart

break; 

#region active-directory-organizational-tree
# get user information from active directory
# organization hierarchy generation usig GraphViz
# cluster user in departments, like Finance, HR, Tech etc

$data = Import-Csv .\demo\src\org.csv

Graph orgchart @{fontname = "verdana" } {
    # create records with details: title, department and city
    Foreach ($d in $data ) {
        $Manager = $d.name
        Node -Name $Manager
        # Record -Name $Manager {
        #     row -Label "Title: $($d.title)"
        #     row -Label "Department: $($d.department)"
        #     row -Label "City: $($d.city)"
        # }
        # create a edge from each manager to his/her direct reports
        foreach ($reports in $d.directreports.split(';')) {
            $Report = $reports.split(',')[0].replace('CN=', '')
            if ($Report) {
                Edge -From $Manager -to $Report 
            }
        }
    }

    # cluster records by department like finance, HR, and tech
    $colors = 'blue', 'darkgreen', 'red', 'magenta', 'gray', 'orange', 'maroon'
    $i = 0
    Foreach ($Cluster in $($data | Group-Object Department)) {
        SubGraph $Cluster.name @{Style = 'dashed'; Label = "Department: $($Cluster.Name)"; labelloc = 'l'; color = $colors[$i]; fontname = "verdana" } {
            foreach ($item in $Cluster.group) {
                Node $($Item.name)
            }
        }
        $i = $i + 1
    }
} | Export-PSGraph

#endregion active-directory-organizational-tree

break; 

