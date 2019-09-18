Function Get-FolderSize{
    param(
        [Parameter(ValueFromPipeline)] [String] $Path
    )
    BEGIN { $fso = New-Object -comobject Scripting.FileSystemObject }
    PROCESS {
        $folder = $fso.GetFolder($Path)
        $size = $folder.size
        [PSCustomObject]@{
            fullname = $path
            basename = $folder.ShortName
            Size = "{0}" -f [int]($size/1kb)
        } 
    } 
} 