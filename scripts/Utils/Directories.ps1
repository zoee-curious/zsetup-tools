function New-Dir {
    param (
        [psobject]$Paths
    )
        
    foreach ($Path in $Paths) {
        if (-not(Test-Path $Path -ErrorAction SilentlyContinue)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }
}

function Copy-Dir {
    param (
        [string]$Path,
        [string]$Destination
    )
    
    New-Dir -Paths $Destination
    Copy-Item -Path $Path -Destination $Destination -Recurse -Force | Out-Null
}

function Remove-Dir {
    param (
        [string]$Path
    )
    
    Remove-Item -Path $Path -Recurse -Force | Out-Null
}
