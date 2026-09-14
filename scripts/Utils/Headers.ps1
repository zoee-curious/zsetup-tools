function Get-Headers {
    param (
        [string]$Source
    )

    $Headers = @{}
    $ConfigFile = Join-Path $HOME ".zsetup"

    if (Test-Path $ConfigFile) {
        $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        
        if ($Config.ignoreCache) {
            $Headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
            $Headers["Pragma"] = "no-cache"
        }

        if ($Config.apiKey) {
            $Headers["x-api-key"] = $Config.apiKey
        }

        if ($Source) {
            $Headers["x-visability"] = $Source
        }
        elseif ($Config.source) {
            $Headers["x-visability"] = $Config.source
        }
    }
    return $Headers
}

function Get-Aria2Headers {
    param (
        [string]$Source
    )

    $Headers = Get-Headers -Source $Source
    $AriaHeaders = @()

    foreach ($Key in $Headers.Keys) {
        $AriaHeaders += "--header=`"${Key}: $($Headers[$Key])`""
    }
    return $AriaHeaders
}
