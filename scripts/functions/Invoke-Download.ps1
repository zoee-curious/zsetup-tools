function Invoke-Download {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache,

        [string]$Method,
        [string]$Uri,
        [string]$OutDir,
        [string]$OutName
    )

    $outPath = Join-Path $OutDir $OutName
    if (Test-Path $outPath) {
        Remove-Items -Paths $outPath
    }

    function Invoke-WebDownload {
        $headers = Get-Headers @PSBoundParameters
        Invoke-WebRequest -Uri $Uri -Headers $headers -OutFile $outPath
    }

    function Invoke-Aria2Download {
        $headers = Get-Aria2Headers @PSBoundParameters
        aria2c -s 16 -x 16 -k 1M --allow-overwrite=true `
            -d $OutDir -o $OutName $headers $Uri | Out-Null
    }

    switch ($Method) {
        'invoke' {
            Invoke-WebDownload
        }

        'aria2' {
            try {
                Invoke-Aria2Download
            }
            catch {
                Invoke-WebDownload
            }
        }
    }
}
