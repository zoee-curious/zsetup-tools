function Remove-Items {
    param (
        [array]$Paths = @()
    )

    foreach ($path in $Paths) {
        if (Test-Path $path -ErrorAction SilentlyContinue) {
            Remove-Item -Path $path -Recurse -Force | Out-Null
        }
    }
}
