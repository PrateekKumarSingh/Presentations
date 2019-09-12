Using module Polaris

# load modules
Import-Module -Name Polaris, PSHTML, pscognitiveservice
Add-Type -AssemblyName System.Web
$Url = "http://localhost:8080"

New-PolarisStaticRoute -RoutePath "css/" -FolderPath "./src/css"
New-PolarisStaticRoute -RoutePath "js/" -FolderPath "./src/js"

#region iterate-through-each-topic-generated-csv-file

# 1. get topics from file names
# 2. create a dynamic html file
# 3. create new polaris page\routes for each topic

$Topics = Get-ChildItem .\data\ | ForEach-Object BaseName

ForEach ($Topic in $Topics) {
    $Script = @"
`$html =    html {
    `$tweets = Import-Csv ".\Data\$Topic.csv"
        head {
            meta -charset 'utf-8'
            # '<meta http-equiv="refresh" content="10">'
            Title "$Topic [`$(`$Tweets.count)]"
            link -rel "stylesheet" -type "text/css" -href "css/jquery.dataTables.css"
            link -rel "stylesheet" -type "text/css" -href "css/dataTables.material.min.css"
            link -rel "stylesheet" -type "text/css" -href "css/material.min.css"
            link -rel "stylesheet" -type "text/css" -href "css/bootstrap.css"
            style -Content {
@'
input {
        float: right;
        }
        .dataTables_wrapper .dataTables_filter {
        float: right;
        text-align: left;
        }
'@
            }
            
            script -type "text/javascript" -src "js/jquery-3.3.1.js" -Attributes @{charset = "utf8" }
            script -type "text/javascript" -src "js/jquery.dataTables.js" -Attributes @{charset = "utf8" }
            script -type "text/javascript" -src "js/jquery.dataTables.min.js" -Attributes @{charset = "utf8" }
            script -content {
@`'
`$(document).ready(function() {
`$('#$Topic').DataTable({
    scrollY:        '60vh',
    paging:         false
});
} );

`'@
            }
        } -Class 'init'
        body {
            '<center>'
            h1 -class "display-4" -content { "Live Twitter Feed for: $topic"}
            '</center>'
            ol -Class breadcrumb -Content {
                li -Class breadcrumb-item -Content {
                    a -href $Url -Content {'Home'}
                }

                foreach(`$item in $($topics.foreach({"`'$_`'"}) -join ',')){
                    li -Class breadcrumb-item -Content {
                        a -href "`$Url/`$(`$item.tolower())" -Content {`$item}
            
                    }
                }
            }
            Table {
                Thead -Content {
                    tr -Content {
                        # Th -class "Sorting" -Content "#" -Style "text-align: center; font-size: 16px; color: black"
                        Th -class "Sorting" -Content "Date" -Style "text-align: center; font-size: 16px; color: black"
                        Th -Content "Picture" -Style "text-align: center; font-size: 16px; color: black"
                        Th -class "Sorting" -Content "User" -Style "text-align: center; font-size: 16px; color: black"
                        Th -class "Sorting" -Content "Emotion Detection" -Style "text-align: center; font-size: 16px; color"
                        Th -class "Sorting" -Content "Text" -Style "text-align: center; font-size: 16px; color: black; max-width: 200px"
                        Th -class "Sorting" -Content "Content Moderation" -Style "text-align: center; font-size: 16px; color: black"
                        Th -class "Sorting" -Content "Retweets" -Style "text-align: center; font-size: 16px; color: black; min-width: 0px"
                        Th -class "Sorting" -Content "Favorites" -Style "text-align: center; font-size: 16px; color: black; min-width: 0px"
                        Th -class "Sorting" -Content "Sentiment Analysis" -Style "text-align: center; font-size: 16px; color: black; min-width: 0px"
                    }
                }
                Tbody -Content {
                    # `$tweets = Import-Csv ".\Data\$Topic.csv"
                    `$i = 1
                    foreach (`$item in `$Tweets) {                        
                        tr -Content {
                            # td -Content { `$i } 
                            td -Content { `$item.date } 
                            td -Content {
                                img -src `$item.user_profile_image_url.replace('normal', '200x200') -width 100 -height 100
                            }
                            td -Content {
                                # br
                                `$item.user_name
                                br
                                a -href "https://twitter.com/`$(`$item.screen_name)" -Content { "@" + `$item.screen_name }
                            }   
                            td -Content {
                                `$Emotions = `$item.Emotion
                                if(`$Emotions -notlike "*No face*" -and ![String]::IsNullorWhitespace(`$Emotions)){
                                    Foreach(`$emotion in `$Emotions.Split(';') ) {
                                        `$name, `$percentage =  (`$Emotion -split ':').trim()
                                        `$percentage= "{0:P}" -f [double]`$percentage
                                        div -Class "progress" -Style "Width:130px;height:20px" -Content {
                                            div -Class "progress-bar bg-success" -Attributes @{role = "progressbar";style="width: `$percentage; height:20px; font-size: 15px;" ;'aria-valuemax' = "100"} -Content {
                                                "<font color='black' Style='font-weight:bold'>`$name `$percentage</font>"
                                            }
                                        }
                                    }
                                }
                                else{
                                    `$Emotions
                                }
                            }   
                            td -Content { 
                                `$text = `$item.text
                                `$URLPattern = "(?i)\b((?:[a-z][\w-]+:(?:/{1,3}|[a-z0-9%])|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:']))"
                                `$HashtagPattern = "#[A-Za-z0-9]+"
                                `$AtPattern = "@[A-Za-z0-9]+"
                                `$URL = select-string -InputObject `$text -Pattern `$URLPattern -AllMatches
                                `$Hashtag = select-string -InputObject `$text -Pattern `$HashtagPattern -AllMatches
                                `$Ats = select-string -InputObject `$text -Pattern `$AtPattern -AllMatches
            
                                if ((`$u = `$url.Matches)) {
                                    `$u.ForEach( {
                                            `$a = a -href `$_.value -Content { `$_.value }
                                            `$text = `$text.Replace(`$_.value, `$a)
                                        })
                                }
            
                                if ((`$h = `$Hashtag.Matches)) {
                                    `$h.ForEach( {
                                            `$a = a -href "https://twitter.com/hashtag/`$(`$_.value.replace('#',''))" -Content { `$_.value }
                                            `$text = `$text.Replace(`$_.value, `$a)
                                        })
                                }
            
                                if ((`$at = `$Ats.Matches)) {
                                    `$at.ForEach( {
                                            `$a = a -href "https://twitter.com/`$(`$_.value.replace('@',''))" -Content { `$_.value }
                                            `$text = `$text.Replace(`$_.value, `$a)
                                        })
                                }
            
                                `$text
            
                            }
            
                            td -Content {
                                `$item.ContentModeration
                            }
                                
                            td -Content { 
                                `$item.retweet_count
                            }
                                
                            td -Content { 
                                `$item.favorite_count
                            }
                            if (`$item.Sentiments -gt 0.7) {
                                `$color = 'bg-success'
                                `$name = 'Positive'
                                `$fontcolor = 'black'
                            }
                            elseif (`$item.Sentiments -le 0.7 -and `$item.Sentiments -gt 0.4) {
                                `$color = 'bg-warning'
                                `$name = 'Neutral'
                                `$fontcolor = 'black'
                                `$fontcolor = 'black'
                            }
                            else {
                                `$color = 'bg-danger'
                                `$name = 'Negative'
                                `$fontcolor = 'black'
                            }    
                            `$percentage = "{0:P}" -f [double]`$item.Sentiments
                            td -Content { 
                                div -Class "progress" -Style "Width:130px;height:20px" -Content {
                                    div -Class "progress-bar `$color" -Attributes @{role = "progressbar";style="width: `$percentage; height:20px; font-size: 15px;" ;'aria-valuemax' = "100"} -Content {
                                        "<font color=`$FontColor Style='font-weight:bold'>`$name `$Percentage`</font>"
                                    }
                                }
                            }
                        }
                    }
                }
            } -Class "table hover row-border" -Id $Topic
            # } 
        }
    }

    `$Response.SetContentType('text/html')
    `$Response.Send(`$Html)
"@
    $scriptblock = [scriptblock]::Create($Script)

    New-PolarisGetRoute -Path "/$Topic".ToLower() -Scriptblock $scriptblock
}
#endregion iterate-through-each-topic-generated-csv-file

#region create-home-page

New-PolarisGetRoute -Path "/" -Scriptblock {
    $radarCanvas0 = "radarcanvas0"
    
    #region html
    $HTMLDocument = html { 
        head {
            title 'Home - Stats'
            link -rel "stylesheet" -type "text/css" -href "css/jquery.dataTables.css"
            link -rel "stylesheet" -type "text/css" -href "css/dataTables.material.min.css"
            link -rel "stylesheet" -type "text/css" -href "css/material.min.css"
            link -rel "stylesheet" -type "text/css" -href "css/bootstrap.css"
        }
        body {
            #region add-heading-an-braed-crumbs
            '<center>'
            h1 -class "display-4" -content { "Statistics" }
            '</center>'
            ol -Class breadcrumb -Content {
                li -Class breadcrumb-item -Content {
                    a -href "http://localhost:8080" -Content { 'Home' }
                }
                $Topics = Get-ChildItem .\data\
                foreach ($item in $($topics.BaseName)) {
                    li -Class breadcrumb-item -Content {
                        a -href "http://localhost:8080/$($item.tolower())" -Content { $item }
        
                    }
                }
            }
            #endregion add-heading-an-braed-crumbs

            #region add-heading-an-braed-crumbs      
            div {
                $canvas = @()
                $canvas += canvas -Height 300px -Width 300px -Id $radarCanvas0 { }
                $Topics = Get-ChildItem .\data\
                $Topics.BaseName | ForEach-Object {
                    $canvas += canvas -Height 300px -Width 300px -Id $_ { }
                }

                table {
                    tr {
                        $canvas | ForEach-Object {
                            td {
                                $_
                            }
                        }
                    }
                }
            }
            script -src "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.3/Chart.min.js" -type "text/javascript"
            script -type "text/javascript" -src "js/jquery-3.3.1.js" -Attributes @{charset = "utf8" }
            script -type "text/javascript" -src "js/jquery.dataTables.js" -Attributes @{charset = "utf8" }
            script -type "text/javascript" -src "js/jquery.dataTables.min.js" -Attributes @{charset = "utf8" }
            script -content {
                $Topics = Get-ChildItem .\data\
                $Labels = $Topics.BaseName
                $dataset_radarchart = @() 

                # get tweets captured data
                $data = Foreach ($topic in $Topics) {
                    (Import-Csv $topic.FullName).count
                }
                $dataset_radarchart += New-PSHTMLChartBarDataSet -Data $Data -label 'Tweets Captured' -borderColor (get-pshtmlColor -color 'blue') -backgroundColor "transparent" -hoverBackgroundColor (get-pshtmlColor -color 'Red')
                
                # get content length data
                $data = Foreach ($topic in $Topics) {
                    [int]((Get-Item  $topic.FullName).length / 1kb)
                }
                $dataset_radarchart += New-PSHTMLChartBarDataSet -Data $Data -label 'Data [kb]' -borderColor (get-pshtmlColor -color 'Green') -backgroundColor "transparent" -hoverBackgroundColor (get-pshtmlColor -color 'olive')
                New-PSHTMLChart -type radar -DataSet $dataset_radarchart -title "Radar Chart Example" -Labels $Labels -CanvasID $radarCanvas0 
                
                Foreach ($topic in $Topics) {
                    $data = @()
                    $hash = @{
                        Surprise  = 0
                        Sadness   = 0
                        Happiness = 0
                        Neutral   = 0
                        Fear      = 0
                        Anger     = 0
                        Disgust   = 0
                        Contempt  = 0
                    }
                    $counter = 0
                    Foreach ($Emotions in (Import-Csv $topic.FullName).Emotion.where( { $_ -notlike "*no face*" })) {                    
                        if ($Emotions -notlike "*No face*" -and ![String]::IsNullorWhitespace($Emotions)) {
                            Foreach ($emotion in $Emotions.Split(';') ) {
                                $name, $value = ($Emotion -split ':').trim()
                                $hash[$name] += $(([int]$value) * 100)
                                # $Name, 
                            }
                        }
                        $counter = $counter + 1
                    }
                    $Labels = 'Fear', 'Anger', 'Sadness', 'Contempt', 'Disgust', 'Neutral', 'Happiness', 'Surprise'
                    $Colors = @('Grey', 'red', 'DarkCyan', 'green', 'DarkGreen', 'yellow', 'Orange', 'grey'       )
                    $HoverColors = @('black', 'darkred', 'Orange', 'grey', 'DarkGrey', 'blue', 'Magenta', 'DarkMagenta')
                    
                    $data = $hash.GetEnumerator().ForEach( {
                            if ($_.value) {
                                [int]($_.value / $counter)
                            }
                            else {
                                $_.value
                            }
                        })
                    # "$data"
                    $dsb1 = New-PSHTMLChartPolarAreaDataSet -Data $data -BackgroundColor $Colors -hoverBackgroundColor $HoverColors
                    if ($dsb1) {
                        New-PSHTMLChart -type polarArea -DataSet $dsb1 -title "Emotions [$($topic.BaseName)]" -Labels $Labels  -CanvasID $($topic.BaseName)
                    }
                }
            }
        }
    }
    # $OutPath = "$Home/RadarChart1.html"
    # Out-PSHTMLDocument -HTMLDocument $HTMLDocument -OutPath $OutPath -Show
    
    #endregion html

    $Response.SetContentType('text/html')
    $Response.Send($HTMLDocument)
}
#endregion create-home-page


# start polaris web server
$Polaris = Start-Polaris -Port 8080
Write-Host "`n[+] Web server listening on : http://localhost:$($Polaris.Port)" -ForegroundColor Yellow
Get-PolarisRoute | Select-Object Path, Method | Sort-Object

<# 
cd D:\Workspace\Repository\Presentations\Power-of-the-Console\demo-2-Twitter-Dashboard; .\webserver.ps1
#>