function Invoke-Shortcut {
    param (
        [string]$Path,
        [string]$Name
    )

    $wshShell = New-Object -ComObject WScript.Shell
    $desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
    $shortcutPath = Join-Path $desktopPath "$Name.lnk"
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $Path
    $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($Path)
    $shortcut.Save()
}
