function Copy-Items {
    param (
        [hashtable]$Paths = @{}
    )
    
    foreach ($path in $Paths.GetEnumerator()) {
        $source = $path.Key
        $target = $path.Value
        
        $childItem = Get-ChildItem -Path $source -ErrorAction SilentlyContinue
        if (-not (Test-Path $source) -or (-not $childItem)) {
            throw
        }
        
        Remove-Items -Paths $target
        New-Dirs -Paths $target
        Copy-Item -Path $source -Destination $target -Recurse -Force | Out-Null
    }
}
