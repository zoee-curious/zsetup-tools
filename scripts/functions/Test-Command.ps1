function Test-Command {
    param (
        [string]$Action,
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache,
        [switch]$Help
    )

    if (-not $Action) {
        Show-Help
        exit
    }
        
    if ($Help) {
        Show-Help
        exit
    }
}
