. (Join-Path $PSScriptRoot "start.ps1")
Get-ChildItem -Path (Join-Path $PSScriptRoot "functions") -Filter "*.ps1" | ForEach-Object {
    . $_.FullName
}
