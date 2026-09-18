param(
    [string]$Action,
    [string]$Name,
    [switch]$Public,
    [switch]$Private,
    [switch]$Cache,
    [switch]$NoCache,
    [switch]$Help
)

$BaseUrl = "https://zoee.fun"

$BaseDir = Join-Path $HOME "zsetup"
$ShimsDir = Join-Path $BaseDir "shims"
$ScriptsDir = Join-Path $BaseDir "scripts"
$LocalDir = Join-Path $BaseDir "apps"
$TempDir = Join-Path $BaseDir "temp"

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

$BaseParams = @{
    Action  = $Action
    Name    = $Name
    Public  = [bool]$Public
    Private = [bool]$Private
    Cache   = [bool]$Cache
    NoCache = [bool]$NoCache
    Help    = [bool]$Help
}
