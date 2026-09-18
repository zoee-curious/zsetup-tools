function Invoke-Shim {
    param (
        [string]$Path,
        [string]$Name
    )

    if (-not (Test-Path $Path)) {
        Write-FormattedRow -Text "Not found!", ": $Path" -Color Yellow
        return
    }
    
    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    $shimPath = Join-Path $ShimsDir "$Name.cmd"
    $exec = switch ($ext) {
        '.ps1' { "powershell -ExecutionPolicy Bypass -NoProfile -File ""$Path"" %*" }
        '.py' { "python ""$Path"" %*" }
        default { """$Path"" %*" }
    }

    Set-Content -Path $shimPath -Value "@echo off`n$exec" -Encoding ASCII -Force
}
