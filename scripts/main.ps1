Clear-Shims
Test-Command @BaseParams

switch ($Action) {
    'state' {
        Set-State @BaseParams
    }

    'search' {
        Invoke-Search @BaseParams
    }

    'show' {
        Show-Manifest @BaseParams
    }

    'install' {
        Invoke-Required @BaseParams
        Invoke-Install @BaseParams
    }
}
