Using module Polaris
Import-Module -Name Polaris, PSHTML, pscognitiveservice
Add-Type -AssemblyName System.Web
$Url = "http://localhost:8080"

New-PolarisStaticRoute -RoutePath "css/" -FolderPath "./src/css"
New-PolarisStaticRoute -RoutePath "js/" -FolderPath "./src/js"

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
                        Th -class "Sorting" -Content "#" -Style "text-align: center; font-size: 16px; color: black"
                        Th -class "Sorting" -Content "Date" -Style "text-align: center; font-size: 16px; color: black"
                        Th -Content "Picture" -Style "text-align: center; font-size: 16px; color: black"
                        Th -class "Sorting" -Content "User" -Style "text-align: center; font-size: 16px; color: black"
                        Th -class "Sorting" -Content "Emotion" -Style "text-align: center; font-size: 16px; color"
                        Th -class "Sorting" -Content "Text" -Style "text-align: center; font-size: 16px; color: black; max-width: 200px"
                        Th -class "Sorting" -Content "Content Moderation" -Style "text-align: center; font-size: 16px; color: black; max-width: 200px"
                        Th -class "Sorting" -Content "Retweets" -Style "text-align: center; font-size: 16px; color: black; min-width: 0px"
                        Th -class "Sorting" -Content "Favorites" -Style "text-align: center; font-size: 16px; color: black; min-width: 0px"
                        Th -class "Sorting" -Content "Positive Sentiment" -Style "text-align: center; font-size: 16px; color: black; min-width: 0px"
                    }
                }
                Tbody -Content {
                    # `$tweets = Import-Csv ".\Data\$Topic.csv"
                    `$i = 1
                    foreach (`$item in `$Tweets) {                        
                        tr -Content {
                            td -Content { `$i } 
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
                                `$item.Emotion
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
                                `$color = 'Green'
                            }
                            elseif (`$item.Sentiments -le 0.7 -and `$item.Sentiments -gt 0.4) {
                                `$color = 'Yellow'
                            }
                            else {
                                `$color = 'Red'
                            }    
                            td -Content { 
                                "{0:P}" -f [double]`$item.Sentiments
                            } -Attributes @{bgcolor = `$color }
                        }
                        `$i = `$i + 1
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
#>

$Polaris = Start-Polaris -Port 8080
Write-Host "`n[+] Web server listening on : http://localhost:$($Polaris.Port)" -ForegroundColor Yellow
Get-PolarisRoute | Select-Object Path, Method | Sort-Object

<# 
cd D:\Workspace\Repository\Presentations\Power-of-the-Console\demo-2-Twitter-Dashboard; .\webserver.ps1
#>