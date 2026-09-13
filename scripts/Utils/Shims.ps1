function Get-Shim {
    param (
        [string]$Path,
        [string]$Name
    )
    
    $BaseDir = Join-Path $HOME "zsetup"
    $ShimsDir = Join-Path $BaseDir "shims"
    
    if (-not (Test-Path $Path)) {
        return 
    }
    
    $Ext = [System.IO.Path]::GetExtension($Path).ToLower()
    $ShimPath = Join-Path $ShimsDir "$Name.cmd"
    $Exec = switch ($Ext) {
        '.ps1' { "powershell -ExecutionPolicy Bypass -NoProfile -File ""$Path"" %*" }
        '.py' { "python ""$Path"" %*" }
        default { """$Path"" %*" }
    }
    Set-Content -Path $ShimPath -Value "@echo off`n$Exec" -Encoding ASCII -Force
}

function Clear-Shims {
    Get-ChildItem -Path "$HOME\zsetup\shims\*.cmd" -ErrorAction SilentlyContinue | ForEach-Object {
        if ((Get-Content $_.FullName -Raw) -match '"([^"]+\.exe)"' -and -not (Test-Path $Matches[1])) {
            Remove-Item $_.FullName -Force
            Write-FormattedRow -Text "Successfully cleaned the shims!"
        }
    }
}
