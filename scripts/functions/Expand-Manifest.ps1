function Expand-Manifest {
    param (
        [psobject]$Manifest
    )
    
    $replacements = @{
        '<BaseDir>'    = $BaseDir
        '<ShimsDir>'   = $ShimsDir
        '<ScriptsDir>' = $ScriptsDir
        '<LocalDir>'   = $LocalDir
        '<TempDir>'    = $TempDir
    }

    $clone = $Manifest.psobject.Copy()
    foreach ($prop in $clone.psobject.properties) {
        if ($prop.Value -is [string]) {
            $val = $prop.Value
            
            foreach ($entry in $replacements.GetEnumerator()) {
                if ($null -ne $entry.Value) {
                    $val = $val.Replace($entry.Key, $entry.Value)
                }
            }
            $prop.Value = $val
        }
    }
    return $clone
}
