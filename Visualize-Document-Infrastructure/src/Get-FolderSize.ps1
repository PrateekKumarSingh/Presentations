Function Get-FolderSize {
    param(
        $Path = 'c:\',
        $Top = 10,
        [Switch] $ShowErrors,
        [Switch] $ShowStats
    )
    $Start = Get-Date
    $FSO = New-Object -ComObject Scripting.FileSystemObject -ErrorAction Stop
    $Folders = Get-ChildItem $Path -ea Silentlycontinue -ErrorVariable +err | Where-Object { $_.PSIscontainer } | Select-Object -ExpandProperty fullname
    $Objs = Foreach ($Folder in $Folders) {
        $FSO.GetFolder($Folder)
    }
    Write-host "Top $Top Folder sizes" -Foreground Yellow
    $data = $Objs | Select-Object path, size | Sort-Object Size -Descending
    $data | Select-Object Path, @{n='FolderSize';e={
        $Size = $_.Size
        if($Size -ge 1GB){ $SizeWithUnit = "{0:N2} GB" -f ($Size/1gb) }elseif($Size -ge 1Mb){ $SizeWithUnit = "{0:N2} MB" -f ($Size/1mb)  }else{$SizeWithUnit = "{0:N2} KB" -f ($Size/1kb)} 
        $SizeWithUnit
    }} -f $Top | Out-Host
    
    if ($ShowErrors) {
        if ($err) {
            Write-host "Errors Encountered`n" -Foreground Yellow
            $err | foreach{$_.exception}
        }
    }
    
    if($ShowStats){
        Write-host "`nStatistics`n" -Foreground Yellow
        $Time = (Get-Date)-$Start
        "Total execution time: {0} mins {1} secs" -f $Time.Minutes, $Time.Seconds
        "Folders scanned: $($Folders.count)"
    }
}

Get-FolderSize C:\ -Top 5 -ShowStats