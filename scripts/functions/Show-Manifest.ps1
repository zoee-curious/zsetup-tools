function Show-Manifest {
    param (
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

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
}
