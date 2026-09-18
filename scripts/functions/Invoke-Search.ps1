function Invoke-Search {
    param (
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $uri = "$BaseUrl/getSearchIndexManifest"
    $headers = Get-Headers @PSBoundParameters

    try {
        $indexManifest = Invoke-RestMethod -Uri $uri -Headers $headers
    }
    catch {
        Write-FormattedRow -Text "Not found!", ": manifests-search-index.json" -Color Yellow
        return
    }

    $results = $indexManifest | Where-Object {
        $_.id -like "*$Name*" -or
        $_.name -like "*$Name*" -or
        ($_.aliases | Where-Object { $_ -like "*$Name*" })
    }

    if (-not $results -or $results.Count -eq 0) {
        Write-FormattedRow -Text "Not found!", ": $Name" -Color Yellow
        return
    }

    $widths = @(35, 24, 10, 40)
    $totalWidth = ($widths | Measure-Object -Sum).Sum

    Write-FormattedRow -Text "ID", "Name", "Version", "Description" -Width $widths
    Write-Host ("-" * $totalWidth ) -ForegroundColor DarkGray

    foreach ($result in $results) {
        if ($result.description) {
            $findDescription = $result.description
            if ($findDescription.Length -gt 40) {
                $description = $findDescription.Substring(0, 37) + "..."
            }
            else {
                $description = $findDescription 
            }
        }
        else { 
            $description = "-" 
        }

        Write-FormattedRow -Text $result.id, $result.name, $result.version, $description -Width $widths
    }
}
