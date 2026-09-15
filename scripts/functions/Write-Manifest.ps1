function Write-Manifest {
    param (
        [psobject]$Manifest
    )
    
    $manifestMap = [ordered]@{
        "ID"               = $Manifest.Id
        "Name"             = $Manifest.Name
        "Version"          = $Manifest.Version
        "Publisher"        = $Manifest.Publisher
        "Description"      = $Manifest.Description
        "Aliases"          = ($Manifest.Aliases -join ", ")
        "URL"              = $Manifest.Url
        "Archive Type"     = $Manifest.ArchiveType
        "Output Name"      = $Manifest.OutName
        "Output Dir"       = $Manifest.OutDir
        "Output Path"      = $Manifest.OutPath
        "Download Method"  = $Manifest.DownloadMethod
        "Extract Method"   = $Manifest.ExtractMethod
        "Extract Password" = $Manifest.ExtractPassword
        "Install Type"     = $Manifest.InstallType
        "Extract Dir"      = $Manifest.ExtractDir
        "Install Dir"      = $Manifest.InstallDir
        "Executable Path"  = $Manifest.ExecutablePath
        "Shortcut Type"    = $Manifest.ShortcutType
        "Shortcut Name"    = $Manifest.ShortcutName
    }
    
    if ($Manifest) {
        Write-Host
        foreach ($obj in $manifestMap.GetEnumerator()) {
            if ($obj.Value) {
                Write-FormattedRow -Text $obj.Key, ": $(Expand-Path -Path $obj.Value)"
            }
        }
        Write-Host
    }
    return
}
