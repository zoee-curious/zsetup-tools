function Get-Shortcut {
    param (
        [string]$Path,
        [string]$Name
    )

    $WshShell = New-Object -ComObject WScript.Shell
    $DesktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
    $ShortcutPath = Join-Path $DesktopPath "$Name.lnk"
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $Path
    $Shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($Path)
    $Shortcut.Save()
}
