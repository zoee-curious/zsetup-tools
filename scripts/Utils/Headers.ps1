function Get-Headers {
    param (
        [string]$Source
    )

    $Headers = @{}
    $ConfigFile = Join-Path $HOME ".zsetup"

    if (Test-Path $ConfigFile) {
        $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        
        if ($Config.PSObject.Properties['cache'] -and $Config.cache -eq $false) {
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

    if ($Source -eq 'public') {
        return
    }

    $AriaHeaders = @()
    $ConfigFile = Join-Path $HOME ".zsetup"

    if (Test-Path $ConfigFile) {
        $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        
        if ($Config.apiKey) {
            $AriaHeaders += "--header=x-api-key: $($Config.apiKey)"
        }

        if ($Source) {
            $AriaHeaders += "--header=x-visability: $($Source)"
        }
        else {
            if ($Config.source) {
                $AriaHeaders += "--header=x-visability: $($Config.source)"
            }
        }
    }
    return $AriaHeaders
}
