function Invoke-Install {
    param (
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    if ($Name -eq "update") {
        Invoke-LocalInstall @PSBoundParameters
        Show-Help
        return
    }
    
    $manifest = Get-Manifest @PSBoundParameters
    if (-not $manifest) {
        Invoke-Search @PSBoundParameters
        return
    }
    
    Write-Host
    foreach ($entry in $manifest.GetEnumerator()) {
        if ($entry.Value) {
            Write-FormattedRow -Text $entry.Key, ": $($entry.Value)"
        }
    }
    Write-Host

    $startProcessParams = @{
        FilePath = $manifest.ExecutablePath
    }

    $invokeDownloadParams = @{
        Method  = $manifest.DownloadMethod
        Uri     = $manifest.Url
        OutDir  = $manifest.OutDir
        OutName = $manifest.OutName
    }

    $invokeExtractParams = @{
        Method     = $manifest.ExtractMethod
        Archive    = $manifest.OutPath
        OutDir     = $manifest.ExtractDir
        ExtractDir = $manifest.ExtractDir
        Password   = $manifest.ExtractPassword
    }

    switch ($manifest.ArchiveType) {
        'none' {
            try {
                if (-not $NoCache) {
                    Start-Process @startProcessParams
                    return
                }
                else {
                    Invoke-Download @PSBoundParameters @invokeDownloadParams
                }
            }
            catch {
                Invoke-Download @PSBoundParameters @invokeDownloadParams
            }
        }

        'flat' {
            try {
                if (-not $NoCache) {
                    Invoke-Extract @invokeExtractParams
                }
                else {
                    Invoke-Download @PSBoundParameters @invokeDownloadParams
                    Invoke-Extract @invokeExtractParams
                }
            }
            catch {
                Invoke-Download @PSBoundParameters @invokeDownloadParams
                Invoke-Extract @invokeExtractParams
            }
        }

        'nested' {
            $invokeExtractParams.OutDir = $manifest.OutDir

            try {
                if (-not $NoCache) {
                    Invoke-Extract @invokeExtractParams
                }
                else {
                    Invoke-Download @PSBoundParameters @invokeDownloadParams
                    Invoke-Extract @invokeExtractParams
                }
            }
            catch {
                Invoke-Download @PSBoundParameters @invokeDownloadParams
                Invoke-Extract @invokeExtractParams
            }
        }
    }

    $copyItemsParams = @{
        Paths = @{
            "$($manifest.ExtractDir)\*" = "$($manifest.InstallDir)\"
        }
    }

    $removeItemsParams = @(
        $manifest.ExtractDir
    )

    switch ($manifest.InstallType) {
        'installer' {
            try {
                Start-Process @startProcessParams
            }
            catch {
                Write-FormattedRow -Text "Failed start process, may need admin privilage or installer corrupt, try -nocache" -Color Yellow
            }
        }

        'portable' {
            try {
                Copy-Items @copyItemsParams
                Remove-Items @removeItemsParams
            }
            catch {
                Write-FormattedRow -Text "Failed copy from temp to install dir, may access danied!" -Color Yellow                
            }
        }

        'portableAutorun' {
            try {
                Copy-Items @copyItemsParams
                Remove-Items @removeItemsParams
                Start-Process @startProcessParams
            }
            catch {
                Write-FormattedRow -Text "Failed copy from temp to install dir, may access danied!" -Color Yellow                
            }
        }
    }

    $invokeShortcutParams = @{
        Path = $manifest.ExecutablePath
        Name = $manifest.ShortcutName
    }

    switch ($manifest.ShortcutType) {
        'shim' {
            try {
                Invoke-Shim @invokeShortcutParams
            }
            catch {
                Write-FormattedRow -Text "Failed creating shim, may access danied!" -Color Yellow
            }
        }

        'desktop' {
            try {
                Invoke-Shortcut @invokeShortcutParams                
            }
            catch {
                Write-FormattedRow -Text "Failed creating desktop shortcut, may access danied!" -Color Yellow
            }
        }
    }
}
