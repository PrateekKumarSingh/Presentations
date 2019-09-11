[cmdletbinding()]
param(
    $Search = '#powershell',
    $Count = 10,
    $ResultType = "recent",
    $Mins = 1
)

$filepath = ".\data\{0}.csv" -f $Search.Replace('#', '')
If (Test-Path $filepath) {
    $Content = Import-Csv $filepath -ErrorAction SilentlyContinue
}

$Host.UI.RawUI.WindowTitle = "Search: $Search | Count: $(if($content){$Content.count}else{0})" 
if ($Content) {
    $Max_Id = ($Content | Sort-Object ID -Descending | Select-Object -First 1).id
}
else {
    $Max_Id = 0
}

$modules = 'pscognitiveservice', 'PSTwitterAPI'
Write-Host " [+] Importing required modules: $($modules -join ', ')" -ForegroundColor Green
Import-Module $modules -PassThru | Format-Table Name, Version -AutoSize

while ($true) {
    # try {
    function Get-CustomDate {
        param(
            [Parameter(Mandatory = $true)]
            [string]$DateString,
            [string]$DateFormat = 'ddd MMM dd HH:mm:ss yyyy',
            [cultureinfo]$Culture = $(Get-UICulture)
        )
        # replace double space by a single one
        $DateString = $DateString -replace '\s+', ' '
        [Datetime]::ParseExact($DateString, $DateFormat, $Culture)
    }

    $configs = @{ }
    # Get-Content $PSScriptRoot/config.txt | ForEach-Object {
    Get-Content .\config.txt | ForEach-Object {
        $key, $value = $_.split('=')    
        $configs[$key] = $value
    }

    Set-TwitterOAuthSettings -ApiKey $configs['consumer_key'] -ApiSecret  $configs['consumer_secret'] -AccessToken $configs['token'] -AccessTokenSecret $configs['token_secret'] -Force
    # Get-TwitterOAuthSettings
    Start-Sleep -Seconds 2 -Verbose
    $splat = @{
        Count       = $Count
        q           = $Search
        result_type = $ResultType
        lang        = "en"
        since_id    = $Max_Id
    }
    Write-Host " [+] Fetching Recent Tweets: $Search" -ForegroundColor Green
    $Results = Get-TwitterSearch_Tweets @splat
    $SearchMetadata = $results.search_metadata
    Write-Host "    [+] Completed in $($SearchMetadata.completed_in)" -ForegroundColor Green
    Write-Host "    [+] Count: $($SearchMetadata.count)" -ForegroundColor Green

    if ($Results) {
        $Max_Id = $SearchMetadata.max_id 
        $Results = $Results.statuses | ForEach-Object {
            [PSCustomObject] @{
                id                     = $_.id
                screen_name            = $_.user.screen_name
                date                   = Get-CustomDate -DateString ($_.created_at -replace " \+0000", "")
                retweet_count          = $_.retweet_count
                favorite_count         = $_.favorite_count
                text                   = $_.text
                url                    = "https://twitter.com/$($_.user.screen_name)/status/$($_.id)"
                user_name              = $_.user.name
                user_screen_name       = $_.user.screen_name
                user_description       = $_.user.description
                user_profile_image_url = $_.user.profile_image_url
                user_followers_count   = $_.user.followers_count
                user_friends_count     = $_.user.friends_count   
                user_favourites_count  = $_.user.favourites_count
                user_statuses_count    = $_.user.statuses_count
                retweeted_status       = $_.retweeted_status
                sensitive              = $_.possibly_sensitive
            }
        } | Sort-Object date -Descending `
        | Where-Object { (-not $_.retweeted_status) } `
        | Sort-Object  retweet_count, favorite_count -Descending `
        | Select-Object *, `
        @{n = 'ContentModeration'; e = {
                $reccomendation = (Test-AdultRacyContent -Text $_.text -ErrorAction SilentlyContinue).classification.ReviewRecommended
                if ($reccomendation -eq 'true') {
                    "Need Review"
                }
                else {
                    "No Review Required"
                }
            }
        }, `
        @{n = 'sentiments'; e = { 
                (Get-Sentiment -Text $_.text -ErrorAction SilentlyContinue).documents.score
            }
        }, `
        @{n = 'Emotion'; e = { 
                $Score = (Get-Face -URL $_.user_profile_image_url.replace('normal', '200x200') -ErrorAction SilentlyContinue).faceattributes.emotion
                $Emotion = @{
                    Anger     = $Score.anger
                    Contempt  = $Score.contempt
                    Disgust   = $Score.disgust
                    Fear      = $Score.fear
                    Happiness = $Score.happiness
                    Neutral   = $Score.neutral
                    Sadness   = $Score.sadness
                    Surprise  = $Score.surprise   
                }

                #Most Significant Emotion = Highest Decimal Value in all Emotion objects
                $StrongestEmotion = $Emotion.GetEnumerator() | Sort-Object value -Descending | Select-Object -First 1

                if ($score) {
                    "{0}, {1:P}" -f $StrongestEmotion.name, $StrongestEmotion.Value
                    # $Score.foreach({"{0:P}" -f [double]$_}) -join  ', '
                }
                else {
                    'No face detected'
                }
                Start-Sleep -Seconds 1
            }
        } 
    
        Write-Host "    [+] Max ID: $Max_Id" -ForegroundColor Green
        Write-Host "    [+] Filtered tweets in last $Mins minutes: $($Results.count)" -ForegroundColor Green
        $Results | Format-List date, screen_name, text, sentiments, happiness, ContentModeration
        
        $Results | Export-Csv $filepath -NoTypeInformation -Verbose -Encoding UTF8 -Append
        $Content = Import-Csv $filepath -ErrorAction SilentlyContinue
        $Host.UI.RawUI.WindowTitle = "Search: $Search | Count: $(if($content){$Content.count}else{0})" 
        Write-Host " [+] Sleeping for $Mins minutes.. `n" -ForegroundColor DarkMagenta

    }
    Start-Sleep -Seconds (60 * $Mins)
    # }
    # catch {
    #     $_
    #     Write-Host " [-] Skipping fetching the tweets" -ForegroundColor Red
    #     Write-Host " [+] Sleeping for $Mins minutes.. `n" -ForegroundColor Magenta
    #     Start-Sleep -Seconds (60 * $Mins)
    # }
}