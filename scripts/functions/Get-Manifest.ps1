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
        Invoke-RestMethod -Uri $uri -Headers $headers
    }
    catch {
        return $null
    }
}
