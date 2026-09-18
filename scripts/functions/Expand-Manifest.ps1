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

    foreach ($prop in $Manifest.psobject.properties) {
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

    return [ordered]@{
        Id              = $Manifest.Id
        Name            = $Manifest.Name
        Version         = $Manifest.Version
        Publisher       = $Manifest.Publisher
        Description     = $Manifest.Description
        Aliases         = $Manifest.Aliases
        Url             = $Manifest.Url
        ArchiveType     = $Manifest.ArchiveType
        OutName         = $Manifest.OutName
        OutDir          = $Manifest.OutDir
        OutPath         = $Manifest.OutPath
        DownloadMethod  = $Manifest.DownloadMethod
        ExtractMethod   = $Manifest.ExtractMethod
        ExtractPassword = $Manifest.ExtractPassword
        InstallType     = $Manifest.InstallType
        ExtractDir      = $Manifest.ExtractDir
        InstallDir      = $Manifest.InstallDir
        ExecutablePath  = $Manifest.ExecutablePath
        ShortcutType    = $Manifest.ShortcutType
        ShortcutName    = $Manifest.ShortcutName
    }
}
