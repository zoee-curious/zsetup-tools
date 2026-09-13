function Get-Modules {
    param (
        [string]$BaseUrl,
        [string]$RootPath
    )
    
    $RequireScripts = @(
        "Helpers/Command.ps1"
        "Helpers/Logger.ps1"
        "Utils/Archives.ps1"
        "Utils/Directories.ps1"
        "Utils/Headers.ps1"
        "Utils/Manifests.ps1"
        "Utils/Paths.ps1"
        "Utils/Shims.ps1"
        "Utils/Shortcuts.ps1"
    )

    try {
        foreach ($Script in $RequireScripts) {
            $LocalPath = Join-Path $RootPath ($Script -replace '/', '\')
            . $LocalPath
        }
    }
    catch {
        $ProgressPreference = 'SilentlyContinue'
        foreach ($Script in $RequireScripts) {
            $ScriptUrl = "$BaseUrl/getScript/$Script"
            Invoke-Expression (Invoke-RestMethod -Uri $ScriptUrl)
        }
        $ProgressPreference = 'Continue'
    }
}

function Get-Required {
    param (
        [string]$BaseUrl
    )

    $BaseDir = Join-Path $HOME "zsetup"
    $ShimsDir = Join-Path $BaseDir "shims"

    $Paths = @(
        Join-Path $HOME "zsetup"
        Join-Path $BaseDir "shims"
        Join-Path $BaseDir "scripts"
        Join-Path $BaseDir "apps"
        Join-Path $BaseDir "temp"
    )
    New-Dir -Paths $Paths

    if (-not(Get-Command 7z -ErrorAction SilentlyContinue)) {
        Get-Install -BaseUrl $BaseUrl -Name '7z'
    }

    if (-not(Get-Command aria2c -ErrorAction SilentlyContinue)) {
        Get-Install -BaseUrl $BaseUrl -Name 'aria2'
    }

    $env:PATH += ";$ShimsDir"
    $OldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($OldPath -notlike "*$ShimsDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$OldPath;$ShimsDir", "User")
    }
}

function Get-Installing {
    param (
        [string]$BaseUrl
    )

    Get-Required -BaseUrl $BaseUrl

    $BaseDir = Join-Path $HOME "zsetup"
    $ScriptsDir = Join-Path $BaseDir "scripts"

    $RequireScripts = @(
        "Main.ps1"
        "Helpers/Command.ps1"
        "Helpers/Logger.ps1"
        "Utils/Archives.ps1"
        "Utils/Directories.ps1"
        "Utils/Headers.ps1"
        "Utils/Manifests.ps1"
        "Utils/Paths.ps1"
        "Utils/Shims.ps1"
        "Utils/Shortcuts.ps1"
    )
    
    $ProgressPreference = 'SilentlyContinue'
    foreach ($Script in $RequireScripts) {
        $LocalPath = Join-Path $ScriptsDir ($Script -replace '/', '\')
        $ScriptUrl = "$BaseUrl/getScript/$Script"
        $ParentDir = Split-Path $LocalPath -Parent
        New-Dir -Paths $ParentDir
        Invoke-RestMethod -Uri $ScriptUrl -OutFile $LocalPath
    }
    $ProgressPreference = 'Continue'

    Get-Shim -Path (Join-Path $ScriptsDir "Main.ps1") -Name 'zst'
    Write-FormattedRow -Text "Successfully installed the latest version!" -Color Yellow
    Show-Help
}
