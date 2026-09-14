param (
    [string]$Action = "{{ACTION}}",
    [string]$Name = "{{NAME}}",
    [switch]$Private,
    [switch]$NoCache,
    [switch]$Help
)

$BaseUrl = "https://zoee.fun"

function Get-BootstrapHeaders {
    $Headers = @{}
    $ConfigFile = Join-Path $HOME ".zsetup"
    if (Test-Path $ConfigFile) {
        try {
            $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
            if ($Config.apiKey) { $Headers["x-api-key"] = $Config.apiKey }

            if ($Private) { $Headers["x-scope"] = 'private' }
            elseif ($Config.scope) { $Headers["x-scope"] = $Config.scope }

            if ($NoCache) {
                $Headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
                $Headers["Pragma"] = "no-cache"
            }
            elseif ($Config.noCache) {
                $Headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
                $Headers["Pragma"] = "no-cache"
            } 
        }
        catch {}
    }
    return $Headers
}

$ProgressPreference = 'SilentlyContinue'
Invoke-Expression (Invoke-RestMethod -Uri "$BaseUrl/getScript/Remotes/Modules.ps1" -Headers (Get-BootstrapHeaders))
$ProgressPreference = 'Continue'

if ($PSScriptRoot) {
    . Get-Modules -BaseUrl $BaseUrl -RootPath $PSScriptRoot -Headers (Get-BootstrapHeaders)
}
else {
    . Get-Modules -BaseUrl $BaseUrl -Headers (Get-BootstrapHeaders)
}

Clear-Shims
Test-Command -Action $Action -Name $Name -Help:$Help

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
        Get-Install -BaseUrl $BaseUrl -Name $Name -Source $Source -Headers (Get-BootstrapHeaders)
    }
}
