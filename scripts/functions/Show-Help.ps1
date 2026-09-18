function Show-Help {
    Write-Host
    Write-FormattedRow -Text "Usage:" -Color Yellow
    Write-FormattedRow -Text "zst", "<action>", "<name>" -Color Gray, DarkGray, DarkGray -Width 4, 9 -Indent 2

    Write-Host
    Write-FormattedRow -Text "Action:" -Color Yellow
    Write-FormattedRow -Text "install", "<name>", ": Install a package (e.g., zst install aria2)" -Color Gray, DarkGray, Gray -Width 8, 10 -Indent 2
    Write-FormattedRow -Text "search", "<name>", ": Search available manifests" -Color Gray, DarkGray, Gray -Width 8, 10 -Indent 2
    Write-FormattedRow -Text "show", "<name>", ": Display manifest details" -Color Gray, DarkGray, Gray -Width 8, 10 -Indent 2
    Write-FormattedRow -Text "source", "<name>", ": Set manifest repository source" -Color Gray, DarkGray, Gray -Width 8, 10 -Indent 2

    Write-Host
    Write-FormattedRow -Text "System Commands:" -Color Yellow
    Write-FormattedRow -Text "install", "update", ": Update CLI scripts to the latest version" -Color Gray, Gray, Gray -Width 8, 10 -Indent 2
    Write-Host
}
