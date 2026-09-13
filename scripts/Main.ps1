param (
    [string]$Action = "{{ACTION}}",
    [string]$Name = "{{NAME}}",
    [string]$Source
)

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

Clear-Shims
Test-Command -Action $Action -Name $Name

switch ($Action) {
    'search' {
        Get-Search -BaseUrl $BaseUrl -Name $Name -Source $Source
    }

    'source' {
        Set-Source -Name $Name
    }

    'show' {
        Get-Show -BaseUrl $BaseUrl -Name $Name -Source $Source
    }

    'install' {
        Get-Required -BaseUrl $BaseUrl
        Get-Install -BaseUrl $BaseUrl -Name $Name -Source $Source
    }
}
