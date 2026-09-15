function Show-Manifest {
    param (
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $getManifestParams = @{
        Name    = $Name
        Public  = $Public
        Private = $Private
        Cache   = $Cache
        NoCache = $NoCache
    }

    $manifest = Get-Manifest @getManifestParams
    if (-not $manifest) { 
        Invoke-Search @getManifestParams
        return
    }
    
    Write-Manifest -Manifest $manifest
    return
}
