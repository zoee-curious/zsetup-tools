function Get-Manifest {
    param (
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $uri = "$BaseUrl/getManifest/$Name"
    $headers = Get-Headers @PSBoundParameters

    try {
        $manifest = Invoke-RestMethod -Uri $uri -Headers $headers
        return Expand-Manifest -Manifest $manifest
    }
    catch {
        return $null
    }
}
