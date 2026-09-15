function Invoke-Required {
    $paths = @(
        $BaseDir
        $ShimsDir
        $ScriptsDir
        $LocalDir
        $TempDir
    )
    
    New-Dirs -Paths $paths
    $env:PATH += ";$ShimsDir"
    $oldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($oldPath -notlike "*$ShimsDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$oldPath;$ShimsDir", "User")
    }
    return
}
