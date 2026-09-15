function Invoke-Extract {
    param (
        [string]$Method,
        [string]$Archive,
        [string]$OutDir,
        [psobject]$Password
    )

    function Expand-WithTar {
        tar -xf $Archive -C $OutDir | Out-Null
    }

    function Expand-With7z {
        if ($Password) {
            7z x $Archive -o"$OutDir" -p"$Password" -y | Out-Null
        }
        else {
            7z x $Archive -o"$OutDir" -y | Out-Null
        }
    }

    New-Dirs -Paths $OutDir
    switch ($Method) {
        'tar' {
            Expand-WithTar
        }

        '7z' {
            try {
                Expand-With7z
            }
            catch {
                Expand-WithTar
            }
        }

    }
    return
}
