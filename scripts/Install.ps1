$BaseUrl = "https://zoee.fun"

$ProgressPreference = 'SilentlyContinue'
Invoke-Expression (Invoke-RestMethod -Uri "$BaseUrl/getScript/Remotes/Modules.ps1")
$ProgressPreference = 'Continue'

if ($PSScriptRoot) {
    . Get-Modules -BaseUrl $BaseUrl -RootPath $PSScriptRoot
}
else {
    . Get-Modules -BaseUrl $BaseUrl
}

Get-Installing -BaseUrl $BaseUrl
