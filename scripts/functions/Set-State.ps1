function Set-State {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $config = @{}
    $configFile = Join-Path $HOME ".zsetup"

    if (Test-Path $configFile) {
        $jsonContents = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($jsonContents) {
            foreach ($content in $jsonContents.psobject.properties) {
                $config[$content.Name] = $content.Value
            }
        }
    }

    if ($Public) {
        $config["scope"] = 'public' 
    }
    elseif ($Private) {
        $config["scope"] = 'private' 
    }

    if ($Cache) {
        $config["noCache"] = $false 
    }
    elseif ($NoCache) {
        $config["noCache"] = $true 
    }

    $config | ConvertTo-Json | Set-Content $configFile
}
