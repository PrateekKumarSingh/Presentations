$RootFolder = (Get-Location).Path
$MediaFolder = Join-Path $RootFolder 'demo-1-Az-Cognitive-Service\Media'

# install module
Install-Module PSCognitiveService -Force -Verbose

# import module
Import-Module PSCognitiveService -Force -Verbose

# get module
Get-Command -Module PSCognitiveService

# check Azure login
if(!(Get-AzContext)){
    Connect-AzAccount -Verbose
}
else{
    Write-Host "Already logged-in to Azure" -ForegroundColor Green
}

# create cognitive service accounts in azure
$ResourceGroup = 'demo-resource-group'
$Location = 'CentralIndia'
$CognitiveServices = 'ComputerVision','ContentModerator','Face','TextAnalytics','Bing.EntitySearch','Bing.Search.v7'

$CognitiveServices | ForEach-Object {
    $splat = @{
        AccountType       = $_ 
        ResourceGroupName = $ResourceGroup 
        SKUName           = 'F0' 
        Location          = if($_ -like "Bing*"){'Global'}else{$Location}
    }
    New-CognitiveServiceAccount @splat | Out-Null
} 

# add subscription key & location from azure to $profile 
# as $env variable and load them in them in current session
New-LocalConfiguration -FromAzure -AddKeysToProfile -Verbose | Out-Null

# face, age, gender detection & emotion recognition
$ImagePath = "$MediaFolder\Billgates.jpg"
# Invoke-Item $ImagePath
(Get-Face -Path $ImagePath). faceAttributes| Format-List *

# image description
(Get-ImageDescription -Path $ImagePath).Description | Format-List

# tag image and convert to hashtags
Get-ImageTag -URL https://goo.gl/Q73Qtw | 
    ForEach-Object{$_.tags.name.foreach({"#"+$_})} 

# optical character recognition
Get-ImageText -URL https://goo.gl/XyP6LJ |
    ForEach-Object {$_.regions.lines} | 
    ForEach-Object { $_.words.text -join " "}

# convert to thumbnail 
ConvertTo-Thumbnail -URL https://goo.gl/XyP6LJ `
                    -SmartCropping -OutVariable tn
Invoke-Item $tn.OutputFile

# web search keywords
Search-Web "powershell 7" -Verbose |
    ForEach-Object {$_.webpages.value} | 
    Format-List name, url, snippet 

# entity search
Search-Entity -Text "ISRO" | 
    ForEach-Object {$_.entities.value} | 
    Format-List name, description, image, webSearchUrl

# image search
Search-Image -Text 'Jeffery Snover' -Count 5 | ForEach-Object {
    Foreach($Url in $_.value.contenturl){
        Start-Process $url -WindowStyle Minimized
        Start-Sleep -Seconds 1
    }
}

# capture and store images from a web search
$Keyword = 'Bangalore'
$Results = (Search-Image -Text $Keyword -Count 20 -SafeSearch strict)
$Results.value.contenturl | ForEach-Object {
    try {
        Start-Sleep -Seconds 1
        # analyze image and get a caption
        $caption = (Get-ImageDescription -URL $_).description.captions.text

        # creates a logical file name
        $filename = if ($caption) { $caption }else { 'untitled' }

        # add numbering in file name if captions are same
        $path = "c:\temp\$filename.jpg"
        $i = 1
        while(Test-Path $path){
            if($filename -like "*(*)*"){
                $OpenBraces = $filename.IndexOf('(')
                $filename = $($filename[0..($OpenBraces-1)] -join '') +" ($i)"
            }
            else{ $filename = $filename+" ($i)" }
            $path = "c:\temp\$filename.jpg"; $i++
        }
        Write-Host "Downloading image as: $path" -ForegroundColor Cyan
        
        # download the images
        Invoke-WebRequest "$_" -OutFile $path 
    }
    catch {
        $_.exception.message
    }
}

# sentiment analysis
Get-Sentiment -Text "I don't write pester tests!" | ForEach-Object { 
    if($_.documents.score -lt 0.5){
        Write-Host 'Negative Sentiment' -ForegroundColor Red
    }else{
        Write-Host 'Positive Sentiment' -ForegroundColor Green
    }
}

$sentences = "Morning! Such a wonderful day", "I feel sad for the poor" 
Get-Sentiment -Text $sentences | ForEach-Object {
    Foreach($item in $_.documents){
        [PSCustomObject]@{
            Text = $sentences[$($item.id-1)]
            "Positivity" = "{0:P2}" -f $item.score
            Sentiment = if($item.score -lt 0.5){'Negative'}else{'Positive'}
        }
    }
}

# indentify key phrases
Get-KeyPhrase -Text "Such a wonderful day", "I feel sad about these poor people" | ForEach-Object documents

$sentences = @'
Welcome to the PowerShell GitHub Community!
PowerShell Core is a cross-platform (Windows, Linux, and macOS) automation and configuration tool/framework that works well with your existing tools and is optimized
for dealing with structured data (e.g. JSON, CSV, XML, etc.), REST APIs, and object models.
'@ -split [System.Environment]::NewLine

Get-KeyPhrase -Text $sentences | ForEach-Object {
    Foreach($item in $_.documents){
        [PSCustomObject]@{
            Text = $sentences[$($item.id-1)]
            KeyPhrases = $item.keyPhrases
        }
    }
} | Format-List

# web search a keyword to get snippets
# extract key phrases from snippets
# build a word cloud from these key phrases
$Snippets = Search-Web "PowerShell Core" |
    ForEach-Object {$_.webpages.value.snippet} 

$Phrases = (Get-KeyPhrase -Text $Snippets).documents.keyphrases.split(' ') 

$Path = "$env:TEMP\cloud.svg"
$splat = @{
    Path = $Path
    Typeface = 'Consolas'
    ImageSize = '5000x3000'
    AllowRotation = 'None'
}
$Phrases | New-WordCloud @splat -Verbose
Invoke-Item $Path


# detect langauge
$Languages = "Esto es en espanol","C'est en francais"    
Trace-Language -Text $Languages |
    ForEach-Object {$_.documents.detectedlanguages}

# moderate content - text, image (path/url)
Test-AdultRacyContent -Text "Hello World" | 
    ForEach-Object Classification

Test-AdultRacyContent -Path $ImagePath


# create a WebClient instance that will handle Network communications 
$Website = "http://www.ridicurious.com"
$webclient = New-Object System.Net.WebClient
$webpage = $webclient.DownloadString($Website)
$regex = "[(http(s)?):\/\/(www\.)?a-z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-z0-9@:%_\+.~#?&//=]*)((.jpg(\/)?)|(.png(\/)?)){1}(?!([\w\/]+))"

$ImgUrls = $webpage | 
            Select-String -pattern $regex -Allmatches | 
            ForEach-Object {$_.Matches} | 
            Select-Object $_.Value -Unique | 
            Where-Object {$_ -like "http*"} |
            Select-Object -First 10 

ForEach($url in $ImgUrls.value) {
    Test-AdultRacyContent -URL $url -ea SilentlyContinue | 
    Select-Object @{n='URL';e={$URL}},*classified |
    Format-List

    Start-Sleep -Seconds 1
}



# What's next
* ticketing System
* notes to speechs