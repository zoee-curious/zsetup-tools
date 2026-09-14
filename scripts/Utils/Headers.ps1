function Get-Headers {
    param (
        [switch]$Private,
        [switch]$NoCache
    )

    $Headers = @{}
    $ConfigFile = Join-Path $HOME ".zsetup"

    if (Test-Path $ConfigFile) {
        try {
            $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
            if ($Config.apiKey) { $Headers["x-api-key"] = $Config.apiKey }

            if ($Private) { $Headers["x-scope"] = 'private' }
            elseif ($Config.scope) { $Headers["x-scope"] = $Config.scope }

            if ($NoCache) {
                $Headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
                $Headers["Pragma"] = "no-cache"
            }
            elseif ($Config.noCache) {
                $Headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
                $Headers["Pragma"] = "no-cache"
            } 
        }
        catch {}
    }
    return $Headers
}

function Get-Aria2Headers {
    param (
        [switch]$Private,
        [switch]$NoCache
    )
    
    $AriaHeaders = @()
    $Headers = Get-Headers -Private:$Private -NoCache:$NoCache

    try {
        foreach ($Key in $Headers.Keys) {
            $AriaHeaders += "--header=`"${Key}: $($Headers[$Key])`""
        }
    }
    catch {}
    return $AriaHeaders
}
