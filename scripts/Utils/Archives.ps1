function Get-Archive {
    param (
        [string]$Source,
        [string]$Method,
        [string]$Uri,
        [string]$OutDir,
        [string]$OutName
    )
    
    switch ($Method) {
        'invoke' {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $Uri -OutFile (Join-Path $OutDir $OutName) -Headers (Get-Headers -Source $Source)
            $ProgressPreference = 'Continue'
        }

        'aria2' {
            try {
                aria2c -s 16 -x 16 -k 1M `
                    --allow-overwrite=true `
                (Get-Aria2Headers -Source $Source) `
                    -d $OutDir -o $OutName `
                    $Uri | Out-Null
            }
            catch {
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $Uri -OutFile (Join-Path $OutDir $OutName) -Headers (Get-Headers -Source $Source)
                $ProgressPreference = 'Continue'
            }
        }
    }
}

function Expand-Archive {
    param (
        [string]$Method,
        [string]$Archive,
        [string]$OutDir,
        [psobject]$Password    
    )
    
    New-Dir -Paths $OutDir
    switch ($Method) {
        'tar' {
            tar -xf $Archive -C $OutDir | Out-Null
        }

        '7z' {
            try {
                if ($Password) {
                    7z x $Archive -o"$OutDir" -p"$Password" -y | Out-Null
                }
                else {
                    7z x $Archive -o"$OutDir" -y | Out-Null
                }
            }
            catch {
                tar -xf $Archive -C $OutDir | Out-Null
            }
        }
    }
}
