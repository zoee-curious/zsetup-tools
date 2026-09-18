function Get-Headers {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $headers = @{}
    $configFile = Join-Path $HOME ".zsetup"

    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile -Raw | ConvertFrom-Json
            if ($config.apiKey) {
                $headers["x-api-key"] = $config.apiKey
            }

            if ($Public) {
                $headers["x-scope"] = 'public'
            }
            elseif ($Private) {
                $headers["x-scope"] = 'private'
            }
            elseif ($config.scope) {
                $headers["x-scope"] = $config.scope
            }

            if ($NoCache -or $config.noCache) {
                $headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
                $headers["Pragma"] = "no-cache"
            }
            else {
                $headers["Cache-Control"] = "public, max-age=3600"
            }      
        }
        catch {
            Write-FormattedRow -Text "Failed parsed", ": $configFile" -Color Yellow
        }
    }
    return $headers
}
