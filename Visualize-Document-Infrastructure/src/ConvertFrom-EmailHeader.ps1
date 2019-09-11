Function ConvertFrom-EmailHeader {
    Param($Header)
    $Pattern = 'Received: from([\s\S]*?)by([\s\S]*?)with([\s\S]*?);([(\s\S)*]{32,36})(?:\s\S*?)'
    $fromMatches = $Header | Select-String -Pattern $Pattern -AllMatches
    if ($fromMatches) {
        $fromMatches.Matches | ForEach-Object {
            $from = $_.groups[1].value.trim()
            $by = $_.groups[2].value.trim()
            $with = $_.groups[3].value.trim()
            Switch -wildcard ($with) {
                "SMTP*" { $with = "SMTP" }
                "ESMTP*" { $with = "ESMTP" }
                default { }
            }
            $time = $_.groups[4].value.trim()
            [PSCustomObject] @{
                ReceivedFromFrom = $from
                ReceivedFromBy   = $by
                ReceivedFromWith = $with
                ReceivedFromTime = [Datetime]$time
            }                               
        }
    }
    else {
        return $null
    }
}