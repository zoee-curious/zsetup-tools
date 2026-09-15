function Invoke-Download {
    param (
        [string]$Method,
        [string]$Uri,
        [string]$OutDir,
        [string]$OutName,
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

    function Invoke-Download {
        $outPath = Join-Path $OutDir $OutName
        $headers = Get-Headers @getHeadersParams
        Invoke-WebRequest -Uri $Uri -Headers $headers -OutFile $outPath
    }

    function Invoke-Aria2Download {
        $headers = Get-Aria2Headers @getHeadersParams
        aria2c -s 16 -x 16 -K 1M --allow-overwrite=true `
            -d $OutDir -o $OutName $headers $Uri | Out-Null
    }

    switch ($Method) {
        'invoke' {
            Invoke-Download
        }

        'aria2' {
            try {
                Invoke-Aria2Download
            }
            catch {
                Invoke-Download
            }
        }
    }
    return
}
