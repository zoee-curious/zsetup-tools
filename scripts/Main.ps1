$manifest = Get-Manifest -Name 'aria2'
$manifestData = Expand-Path -Path $manifest
Write-Host $manifestData

exit

Clear-Shims
Test-Command -Action $Action -Name $Name -Help:$Help

switch ($Action) {
    'state' {
        $setStateParams = @{
            Public  = $Public
            Private = $Private
            Cache   = $Cache
            NoCache = $NoCache
        }

        Set-State @setStateParams
    }

    'search' {
        $invokeSearchParams = @{
            Name    = $Name
            Public  = $Public
            Private = $Private
            Cache   = $Cache
            NoCache = $NoCache
        }

        Invoke-Search @invokeSearchParams
    }

    'show' {
        $showManifestParams = @{
            Name    = $Name
            Public  = $Public
            Private = $Private
            Cache   = $Cache
            NoCache = $NoCache
        }

        Show-Manifest @showManifestParams
    }
}
