function Expand-Path {
    param (
        [psobject]$Path
    )

    $maps = @{
        '<BaseDir>'    = $BaseDir
        '<ShimsDir>'   = $ShimsDir
        '<ScriptsDir>' = $ScriptsDir
        '<LocalDir>'   = $LocalDir
        '<TempDir>'    = $TempDir
    }

    foreach ($map in $maps.GetEnumerator()) {
        $Path = $Path.Replace($map.key, $map.Value)
    }
    return $Path
}
