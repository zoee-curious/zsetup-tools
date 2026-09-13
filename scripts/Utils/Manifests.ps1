function Write-Manifest {
    param (
        [psobject]$Manifest
    )
    
    $ManifestMap = [ordered]@{
        "ID"               = $Manifest.Id
        "Name"             = $Manifest.Name
        "Version"          = $Manifest.Version
        "Publisher"        = $Manifest.Publisher
        "Description"      = $Manifest.Description
        "Aliases"          = $Manifest.Aliases
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

    Write-Host
    if ($Manifest) {
        foreach ($item in $ManifestMap.GetEnumerator()) {
            if ($item.Value) {
                Write-FormattedRow -Text $item.Key, ": $(Expand-Path -Path $item.Value)" -Width 20
            }
        }
    }
    Write-Host
    return
}

function Get-Manifest {
    param (
        [string]$Uri,
        [string]$Source
    )
    
    $ProgressPreference = 'SilentlyContinue'
    Invoke-RestMethod -Uri $Uri -Headers (Get-Headers -Source $Source) -ErrorAction Stop        
    $ProgressPreference = 'Continue'
}
