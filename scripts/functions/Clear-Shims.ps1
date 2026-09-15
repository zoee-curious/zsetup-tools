function Clear-Shims {
    Get-ChildItem -Path (Join-Path $ShimsDir "*.cmd") -ErrorAction SilentlyContinue | ForEach-Object {
        if ((Get-Content $_.FullName -Raw) -match '"([^"]+\.exe)"' -and -not (Test-Path $Matches[1])) {
            Remove-Items -Paths $_.FullName
        }
    }
    return
}
