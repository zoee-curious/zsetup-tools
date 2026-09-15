function Get-Manifest {
    param (
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $getHeadersParams = @{
        Public  = $Public
        Private = $Private
        Cache   = $Cache
        NoCache = $NoCache
    }

    try {
        $uri = "$BaseUrl/getManifest/$Name"
        $headers = Get-Headers @getHeadersParams
        $manifest = Invoke-RestMethod -Uri $uri -Headers $headers
        $manifestData = Expand-Manifest -Manifest $manifest
        return $manifestData
    }
    catch {
        return $null
    }
}
