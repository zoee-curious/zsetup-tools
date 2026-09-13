function Expand-Path {
    param (
        [string]$Path
    )
    
    $BaseDir = Join-Path $HOME "zsetup"
    $Paths = @{
        '<BaseDir>'    = $BaseDir
        '<ShimsDir>'   = Join-Path $BaseDir "shims"
        '<ScriptsDir>' = Join-Path $BaseDir "scripts"
        '<LocalDir>'   = Join-Path $BaseDir "apps"
        '<TempDir>'    = Join-Path $BaseDir "temp"
    }

    foreach ($Key in $Paths.Keys) {
        $Path = $Path.Replace($Key, $Paths[$Key])
    }
    return $Path
}
