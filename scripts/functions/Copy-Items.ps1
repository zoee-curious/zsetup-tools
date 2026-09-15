function Copy-Items {
    param (
        [hashtable]$Paths = @{}
    )
    
    foreach ($path in $Paths.GetEnumerator()) {
        New-Dirs -Paths $path.Value
        Copy-Item -Path $path.Key -Destination $path.Value -Recurse -Force | Out-Null        
    }
    return
}
