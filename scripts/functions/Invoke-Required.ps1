function Invoke-Required {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $paths = @(
        $BaseDir
        $ShimsDir
        $ScriptsDir
        $LocalDir
        $TempDir
    )
    
    New-Dirs -Paths $paths

    if (-not(Get-Command 7z -ErrorAction SilentlyContinue)) {
        Invoke-Install @PSBoundParameters -Name '7z'
    }

    if (-not(Get-Command aria2c -ErrorAction SilentlyContinue)) {
        Invoke-Install @PSBoundParameters -Name 'aria2'
    }

    $env:PATH += ";$ShimsDir"
    $oldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($oldPath -notlike "*$ShimsDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$oldPath;$ShimsDir", "User")
    }
}
