# prerequisites
# Install-Module -Name PowerShellForGitHub -Verbose -Scope CurrentUser -Force -Confirm:$false
# Set-GitHubConfiguration -DisableTelemetry

Import-Module -Name PowerShellForGitHub -Verbose
$Token = Get-Content .\src\tokens.txt # https://github.com/settings/tokens/new

#region Github-Repositories
# Parsing Github Repositories on an Owner
# Grouping them by Langauage type = PowerShell, C# etc
# Plotting Repositories in language clusters
# Highlight Respositories with more 'Open Issues' more than a defined Threshold

$Owner = 'PowerShell'
$Cluster = Get-GitHubRepository -Uri "https://github.com/$Owner" -AccessToken $Token -Verbose | 
Where-Object { $_.name -notlike "x*" } |
Select -f 30 |
Select-Object name, stargazers_count, watchers, forks, language, open_issues -OutVariable all |
Group-Object language | 
Sort-Object count -Descending 

$Threshold = 20
$colors = 'blue', 'darkgreen', 'red', 'magenta', 'gray', 'orange', 'maroon'
$ColorCounter = 0

Graph g @{overlap='false';splines='true'} {
    Record -Name "[Owner] $Owner" {
        row -Label "Total Repositories : $($All.count)"
        row -Label "Total Stars        : $(($all.stargazers_count.Foreach({$_ -as [int]}) | Measure-Object -Sum).sum)"
        row -Label "Total Forks        : $(($all.Forks.Foreach({$_ -as [int]}) | Measure-Object -Sum).sum)"
        row -Label "Total Open Issues  : $(($all.Open_Issues.Foreach({$_ -as [int]}) | Measure-Object -Sum).sum)"
        row -Label "Languages          : $($($Cluster.Name.Where({![string]::IsNullOrEmpty($_)}) -join ","))" 
    }
    $Global:Records = @()
    for ($i = 0; $i -lt $Cluster.count; $i++) {
        $name = $Cluster[$i].name
        SubGraph $i @{color = "$($colors[$ColorCounter])"; label = "Language: $(if($name){$name}else{'None'})"; labelloc = 'b'; style = 'dashed' } {
            node @{style = 'filled'; color = 'grey'; shape = 'record' }
            ForEach ($Repository in ($Cluster[$i].Group)) {
                $Global:Records = $Global:Records + "$($Repository.name)"   
                Record -Name "$($Repository.name)" @{ranked = $Cluster.count } {
                    row -Label "Stars: $($Repository.stargazers_count)"
                    row -Label "Watchers: $($Repository.watchers)"
                    if ($Repository.open_issues -gt $Threshold) {
                        row -Label "<b><font color='red'>Issues: $($Repository.open_issues)</font></b>"
                    }
                    else {
                        row -Label "<b><font color='darkgreen'>Issues: $($Repository.open_issues)</font></b>"
                    }
                    row -Label "Forks: $($Repository.forks)"
                }
            }
        }

        # draw an edge from 'Owner' to 'language Subgraph'
        # edge "[Owner] $Owner" "$i"
        $ColorCounter++ # increment color counter
    }
    edge "[Owner] $Owner" $Records
} | Export-PSGraph -LayoutEngine fdp

#endregion Github-Repositories

break; 

#region Demo-6.2-Github-Comments
# Parsing Github Repositories for comments
# Grouping them by usernames
# Plotting usernames and issues they have commented on
# Highlight Respositories with more 'Open Issues' more than a defined Threshold

$Owner = 'PowerShell'
$Repository = 'PowerShell'
$hours = 20
$comments = Get-GitHubComment -OwnerName $Owner -RepositoryName $Repository -AccessToken $Token -Verbose -Since ((Get-Date).addHours(-$hours))
Set-Location .\src\WSL -ErrorAction SilentlyContinue
Remove-Item .\img\*.png -Force

$path = "Comments.dot"

# create Dot file for graph
Graph c @{Rankdir = "LR" } {
    # clean comment objects
    $comments | Foreach-Object {
        $TempPath = ".\img\$($_.user.login).png"
        Invoke-WebRequest $_.user.avatar_url -OutFile $TempPath -Verbose
        [PSCustomObject]@{
            'User'   = $_.user.Login
            'Avatar' = $TempPath -replace "\\", '/'
            'Issue'  = Split-path $_.issue_url -leaf
        }
    } -OutVariable comments | Out-Null

    # group comments per user and sort them by count
    $Group = $comments | Group-Object user | Sort-Object count -Descending 

    # return issues on the repository as dot notations
    $Group.Group.issue | 
    Get-Unique | 
    ForEach-Object {
        $issue = Get-GitHubIssue -OwnerName $Owner -RepositoryName $Repository -Issue $_ -AccessToken $token -Verbose
        Record -Name $issue.number {
            row -Label "Title: $($issue.Title)" -HtmlEncode
            if ($issue.State -eq 'Closed') {
                row -Label "<b>Status: <font color='red'>$($issue.State)</font></b>"
            }
            else {
                row -Label "<b>Status: <font color='darkgreen'>$($issue.State)</font></b>"
            }
            row -Label "Assignee: $($issue.assignee.login)"
            row -Label "Comments: $($issue.comments)"
            row -Label "Labels: $($issue.Labels.Name -join ', ')"
        }
        # Edge $_.name $_.group.issue
    } 

    # return users and issues they have commented on as dot notations
    $Group | ForEach-Object {
        '"{0}" [label=<<TABLE CELLBORDER="1" BORDER="0" CELLSPACING="0"><TR><TD bgcolor="black" align="center"><font color="white"><B>{0}</B></font></TD></TR><TR><TD PORT="c98dcb61-1689-4e72-bc70-61fde0097796" ALIGN="LEFT" fixedsize="true" width="130" height="130"><img src="{1}"/></TD></TR></TABLE>>;fillcolor="white";shape="none";style="filled";penwidth="1";fontname="Courier New";]' -f $($_.group.user | Select-Object -f 1), $($_.group.avatar | Select-Object -f 1)    
        Edge $_.name $_.group.issue
    } 
} | Out-File $path -Encoding utf8 -Force

# execute the dot file on GraphViz on WSL (Windows Subsystem for Linux)
wsl dot -Tpng $path -o Comments.png *>&1 
Invoke-Item .\Comments.png
Set-Location ..\..
#endregion Demo-6.2-Github-Comments 