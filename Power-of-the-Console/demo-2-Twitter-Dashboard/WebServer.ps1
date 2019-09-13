Using module Polaris

# load modules
Import-Module -Name Polaris, PSHTML, pscognitiveservice
Add-Type -AssemblyName System.Web
$Url = "http://localhost:8080"

# load source files - javascript and style sheets
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
            meta -httpequiv 'refresh' -content { 60 }
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

            script -content {
@`'
                         var countDownDate = new Date();
                         countDownDate.setMinutes( countDownDate.getMinutes() + 1 );
                
                // Update the count down every 1 second
                var x = setInterval(function() {
                
                  // Get today's date and time
                  var now = new Date().getTime();
                    
                  // Find the distance between now and the count down date
                  var distance = countDownDate - now;
                    
                  // Time calculations for days, hours, minutes and seconds
                  var days = Math.floor(distance / (1000 * 60 * 60 * 24));
                  var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
                  var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
                  var seconds = Math.floor((distance % (1000 * 60)) / 1000);
                    
                  // Output the result in an element with id="demo"
                  document.getElementById("demo").innerHTML = "Refresh: " + seconds + " Secs";
                    
                  // If the count down is over, write some text 
                  if (distance < 0) {
                    clearInterval(x);
                    document.getElementById("demo").innerHTML = "EXPIRED";
                  }
                }, 1000);
`'@
                            }            
            
        } -Class 'init'
        body {
            '<center>'
            h1 -class "display-5" -content { "Live Twitter Feed for: <b><i><font color='ROYALBLUE'> $topic</font></b></i>"}
            p -id 'demo'
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
                                p -content {
                                    if(`$item.ContentModerationStatus){
                                        "<b>Text:</b><br>`$(`$item.ContentModerationStatus)"
                                    }
                                    else{
                                        "<b>Text:</b><br> No Data"
                                    }
                                    "<br>"
                                    if(`$item.ContentModerationPicture){
                                        "<b>Picture:</b><br>`$(`$item.ContentModerationPicture.Replace(';',' '))"
                                    }
                                    else{
                                        "<b>Picture:</b><br> No Data"
                                    }
                                }
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
    
    #region html
    $radarCanvas0 = "radarcanvas0"
    $radarCanvas1 = "radarcanvas1"
    $radarCanvas2 = "radarcanvas2"

    $HTMLDocument = html { 
        head {
            title 'Home - Stats'
            meta -httpequiv 'refresh' -content { 60 }
            link -rel "stylesheet" -type "text/css" -href "css/jquery.dataTables.css"
            link -rel "stylesheet" -type "text/css" -href "css/dataTables.material.min.css"
            link -rel "stylesheet" -type "text/css" -href "css/material.min.css"
            link -rel "stylesheet" -type "text/css" -href "css/bootstrap.css"
            script -type "text/javascript" -src "https://canvasjs.com/assets/script/canvasjs.min.js"
        }
        body {
            #region add-heading-and-bread-crumbs
            '<center>'
            h1 -class "display-4" -content { "Statistics" }
            p -Id 'demo' # adds a refresh timer
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
            #endregion add-heading-and-bread-crumbs

            #region add-canvas-and-charts  
            div {
                # canvas placeholders
                $canvas = @()
                $canvas += canvas -Style "width: 30%; height: 300px ;display: inline-block;" -Id $radarCanvas0 { }
                $canvas += canvas -Style "width: 30%; height: 300px ;display: inline-block;" -Id $radarCanvas1 { }
                $canvas += canvas -Style "width: 30%; height: 300px ;display: inline-block;" -Id $radarCanvas2 { }

                $Topics = Get-ChildItem .\data\
                $Topics.BaseName | ForEach-Object {
                    $canvas += canvas -Id $_ { } -Style "width: 30%; height: 300px ;display: inline-block;"
                }
                '<center>'
                $canvas
                '</center>'
            }
            script -src "https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.3/Chart.min.js" -type "text/javascript"
            script -type "text/javascript" -src "js/jquery-3.3.1.js" -Attributes @{charset = "utf8" }
            script -type "text/javascript" -src "js/jquery.dataTables.js" -Attributes @{charset = "utf8" }
            script -type "text/javascript" -src "js/jquery.dataTables.min.js" -Attributes @{charset = "utf8" }
            script -content {
                $Topics = Get-ChildItem .\data\
                $Labels = $Topics.BaseName
                $dataset_radarchart = @() 

                # get number tweets captured data
                $CurrenTweetCount = Foreach ($topic in $Topics) {
                    (Import-Csv $topic.FullName).count
                }
                # get content data length
                $DataLength = Foreach ($topic in $Topics) {
                    [int]((Get-Item  $topic.FullName).length / 1kb)
                }

                # radar chart
                $dataset_radarchart += New-PSHTMLChartBarDataSet -Data $CurrenTweetCount -label '# Tweets Captured' -borderColor (get-pshtmlColor -color 'Blue') -backgroundColor "transparent" -hoverBackgroundColor (get-pshtmlColor -color 'Red') -borderWidth 2
                $dataset_radarchart += New-PSHTMLChartBarDataSet -Data $DataLength -label 'Data [kb]' -borderColor (get-pshtmlColor -color 'DarkRed') -backgroundColor "transparent" -hoverBackgroundColor (get-pshtmlColor -color 'olive') -borderWidth 2
                New-PSHTMLChart -type radar -DataSet $dataset_radarchart -title "Total Tweets and Data Collected" -Labels $Labels -CanvasID $radarCanvas0 
                
                # manages tweet count history
                $PrevTweetCount = Get-Content $env:TEMP\numberoftweets.txt -ErrorAction SilentlyContinue
                $CurrenTweetCount | Out-File $env:TEMP\numberoftweets.txt
                
                # pie chart - tweet distribution
                $Data_PieChart = $CurrenTweetCount
                $colors = @("LightSalmon", "DarkRed", "Purple", "Navy", "Teal", "DodgerBlue", "MediumVioletRed", "LightGreen")
                $DataSet_PieChart = New-PSHTMLChartPieDataSet -Data $Data_PieChart -label "Tweets per Topic" -BackgroundColor $Colors
                New-PSHTMLChart -type Pie -DataSet $Dataset_PieChart -title "Topic distribution" -Labels $Labels -CanvasID $radarCanvas1
    
                # line chart - number of tweets per 10 seconds
                $Data_LineChart = For ($n = 0; $n -lt $PrevTweetCount.count; $n++) {
                    $diff = $($CurrenTweetCount[$n]) - $($PrevTweetCount[$n])
                    if ($diff -lt 0) {
                        0
                    }
                    else {
                        $diff
                    }
                }
                $DataSet_LineChart = New-PSHTMLChartLineDataSet -Data $Data_LineChart -FillbackgroundColor ([color]::new(32, 178, 170)) -LineColor 'DarkGreen' -LineWidth 3
                New-PSHTMLChart -type line -DataSet $Dataset_LineChart -title "Tweet Captured / Minute" -Labels $Labels -CanvasID $radarCanvas2
    
                # get emotion data for each topic
                Foreach ($topic in $Topics) {
                    $data = @()
                    $hash = [Ordered] @{
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
                    # $EmotionLabels = 'Surprise','Sadness','Happiness','Neutral','Fear', 'Anger', 'Disgust','Contempt'
                    $EmotionLabels = $hash.Keys
                    $Colors = @('OrangeRed', 'LightSalmon', 'Green', 'LightSteelBlue ', 'SteelBlue', 'DarkRed', 'pink', 'MediumOrchid' )
                    $HoverColors = @('LightSalmon', 'OrangeRed', 'LightSeaGreen', 'SteelBlue', 'LightSteelBlue', 'tomato', 'Magenta', 'MediumVioletRed ')
                    
                    $data = $hash.GetEnumerator().ForEach( {
                            if ($_.value) {
                                [int]($_.value / $counter)
                            }
                            else {
                                $_.value
                            }
                        })
                    $dataset_polarareachart = New-PSHTMLChartPolarAreaDataSet -Data $data -BackgroundColor $Colors -hoverBackgroundColor $HoverColors
                    if ($dataset_polarareachart) {
                        New-PSHTMLChart -type polarArea -DataSet $dataset_polarareachart -title "Emotions [$($topic.BaseName)]" -Labels $EmotionLabels  -CanvasID $($topic.BaseName)
                    }
                }


            }
            #endregion add-canvas-and-charts
            
            #region javascript-for-refresh-timer
            script -content {
                @"
         var countDownDate = new Date();
         countDownDate.setMinutes( countDownDate.getMinutes() + 1 );

// Update the count down every 1 second
var x = setInterval(function() {

  // Get today's date and time
  var now = new Date().getTime();
    
  // Find the distance between now and the count down date
  var distance = countDownDate - now;
    
  // Time calculations for days, hours, minutes and seconds
  var days = Math.floor(distance / (1000 * 60 * 60 * 24));
  var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
  var seconds = Math.floor((distance % (1000 * 60)) / 1000);
    
  // Output the result in an element with id="demo"
  document.getElementById("demo").innerHTML = "Refresh: " + seconds + " Secs";
    
  // If the count down is over, write some text 
  if (distance < 0) {
    clearInterval(x);
    document.getElementById("demo").innerHTML = "EXPIRED";
  }
}, 1000);
"@
            }
            #endregion javascript-for-refresh-timer

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