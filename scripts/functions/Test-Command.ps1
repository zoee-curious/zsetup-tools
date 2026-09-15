function Test-Command {
    param (
        [string]$Action,
        [string]$Name,
        [switch]$Help
    )

    $invalidAction = [string]::IsNullOrWhiteSpace($Action)
    $invalidName = [string]::IsNullOrWhiteSpace($Name)

    if ($invalidAction -and $invalidName) { Show-Help exit }
    if ($Help) { Show-Help exit }
}
