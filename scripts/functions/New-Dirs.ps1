function New-Dirs {
    param (
        [array]$Paths = @()
    )

    foreach ($path in $Paths) {
        if (-not(Test-Path $path -ErrorAction SilentlyContinue)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    return
}
