function Test-Command {
    param (
        [string]$Action,
        [string]$Name
    )

    $invalidAction = [string]::IsNullOrWhiteSpace($Action) -or ($Action -eq "{{ACTION}}")
    $invalidName = [string]::IsNullOrWhiteSpace($Name) -or ($Name -eq "{{NAME}}")

    if ($invalidAction -or $invalidName) {
        Show-Help
        exit 0
    }
}

function Show-Help {
    Write-Host
    Write-FormattedRow -Text "Usage:" -Color Yellow
    Write-FormattedRow -Text "zst", "<action>", "<name>" -Color Gray, DarkGray, DarkGray -Width 4, 9 -Indent 2

    Write-Host
    Write-FormattedRow -Text "Action:" -Color Yellow
    Write-FormattedRow -Text "install", "<name>", ": Install a package (e.g., zst install aria2)" -Color Gray, DarkGray, Gray -Width 8, 14 -Indent 2
    Write-FormattedRow -Text "search", "<name>", ": Search available manifests" -Color Gray, DarkGray, Gray -Width 8, 14 -Indent 2
    Write-FormattedRow -Text "show", "<name>", ": Display manifest details" -Color Gray, DarkGray, Gray -Width 8, 14 -Indent 2
    Write-FormattedRow -Text "source", "<name>", ": Set manifest repository source" -Color Gray, DarkGray, Gray -Width 8, 14 -Indent 2

    Write-Host
    Write-FormattedRow -Text "System Commands:" -Color Yellow
    Write-FormattedRow -Text "install", "update", ": Update CLI scripts to the latest version" -Color Gray, Gray, Gray -Width 8, 14 -Indent 2
    Write-Host
}

function Get-Search {
    param (
        [string]$BaseUrl,
        [string]$Name,
        [string]$Source
    )

    try {
        $Index = Get-Manifest -Uri "$BaseUrl/getIndexManifest" -Source $Source
    }
    catch {
        Write-FormattedRow -Text "Not found!", ": $Name" -Color Yellow
        exit 1
    }

    $Results = $Index | Where-Object {
        $_.id -like "*$Name*" -or
        $_.name -like "*$Name*" -or
        ($_.aliases | Where-Object { $_ -like "*$Name*" })
    }

    if (-not $Results -or $Results.Count -eq 0) {
        Write-FormattedRow -Text "Not found!", ": $Name" -Color Yellow
        exit 1
    }

    $Widths = @(25, 18, 10, 40)
    $TotalWidth = ($Widths | Measure-Object -Sum).Sum

    Write-FormattedRow -Text "ID", "Name", "Version", "Description" -Width $Widths
    Write-Host ("-" * $TotalWidth ) -ForegroundColor DarkGray

    foreach ($item in $Results) {
        $rawDesc = if ($item.Description) { $item.Description } else { "-" }
        $Description = if ($rawDesc.Length -gt 40) {
            $rawDesc.Substring(0, 37) + "..."
        }
        else {
            $rawDesc
        }

        Write-FormattedRow -Text $item.Id, $item.Name, $item.Version, $Description -Width $Widths
    } 
}

function Set-Source {
    param (
        [string]$Name
    )
    
    $Config = @{}
    $ConfigFile = Join-Path $HOME ".zsetup"
    if (Test-Path $ConfigFile) {
        $Json = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        if ($Json) {
            foreach ($Prop in $Json.psobject.properties) {
                $Config[$Prop.Name] = $Prop.Value
            }
        }
    }

    function Set-State {
        param (
            [string]$State
        )
        
        $Config["source"] = $Name
        $Config | ConvertTo-Json | Set-Content $ConfigFile
        Write-FormattedRow -Text "Switch source", ": $Name"
    }

    switch ($Name) {
        'public' {
            Set-State -State $Name
            return
        }

        'private' {
            Set-State -State $Name
            return
        }
    }
    Write-FormattedRow -Text "Not found!", ": $Name" -Color Yellow
    exit 1
}

function Get-Show {
    param (
        [string]$BaseUrl,
        [string]$Name,
        [string]$Source
    )

    try {
        Write-Manifest -Manifest (Get-Manifest -Uri "$BaseUrl/getManifest/$Name" -Source $Source)
    }
    catch {
        Get-Search -BaseUrl $BaseUrl -Name $Name
        return
    }
}

function Get-Install {
    param (
        [string]$BaseUrl,
        [string]$Name,
        [string]$Source
    )

    switch ($Name) {
        'update' {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-Expression (Invoke-RestMethod -Uri "$BaseUrl/install")
            $ProgressPreference = 'Continue'
            return
        }
    }
    
    try {
        $Manifest = Get-Manifest -Uri "$BaseUrl/getManifest/$Name" -Source $Source
        Write-Manifest -Manifest $Manifest
    }
    catch {
        Get-Search -BaseUrl $BaseUrl -Name $Name -Source $Source
        return
    }

    switch ($Manifest.ArchiveType) {
        'none' {
            Get-Archive -Source $Source -Method $Manifest.DownloadMethod -Uri $Manifest.Url -OutDir (Expand-Path $Manifest.OutDir) -OutName $Manifest.OutName
        }

        'flat' {
            Get-Archive -Source $Source -Method $Manifest.DownloadMethod -Uri $Manifest.Url -OutDir (Expand-Path $Manifest.OutDir) -OutName $Manifest.OutName
            Expand-Archive -Method $Manifest.ExtractMethod -Archive (Expand-Path $Manifest.OutPath) -OutDir (Expand-Path $Manifest.ExtractDir)
        }

        'nested' {
            Get-Archive -Source $Source -Method $Manifest.DownloadMethod -Uri $Manifest.Url -OutDir (Expand-Path $Manifest.OutDir) -OutName $Manifest.OutName
            Expand-Archive -Method $Manifest.ExtractMethod -Archive (Expand-Path $Manifest.OutPath) -OutDir (Expand-Path $Manifest.OutDir)
        }

        'flatPassword' {
            Get-Archive -Source $Source -Method $Manifest.DownloadMethod -Uri $Manifest.Url -OutDir (Expand-Path $Manifest.OutDir) -OutName $Manifest.OutName
            Expand-Archive -Method $Manifest.ExtractMethod -Archive (Expand-Path $Manifest.OutPath) -OutDir (Expand-Path $Manifest.ExtractDir) -Password $Manifest.ExtractPassword
        }

        'nestedPassword' {
            Get-Archive -Source $Source -Method $Manifest.DownloadMethod -Uri $Manifest.Url -OutDir (Expand-Path $Manifest.OutDir) -OutName $Manifest.OutName
            Expand-Archive -Method $Manifest.ExtractMethod -Archive (Expand-Path $Manifest.OutPath) -OutDir (Expand-Path $Manifest.OutDir) -Password $Manifest.ExtractPassword
        }
    }

    switch ($Manifest.InstallType) {
        'installer' {
            Start-Process (Expand-Path $Manifest.ExecutablePath)
        }

        'portable' {
            Copy-Dir -Path "$(Expand-Path $Manifest.ExtractDir)\*" -Destination "$(Expand-Path $Manifest.InstallDir)\"
            Remove-Dir -Path (Expand-Path $Manifest.ExtractDir)
        }

        'portableAutorun' {
            Copy-Dir -Path "$(Expand-Path $Manifest.ExtractDir)\*" -Destination "$(Expand-Path $Manifest.InstallDir)\"
            Remove-Dir -Path (Expand-Path $Manifest.ExtractDir)
            Start-Process (Expand-Path $Manifest.ExecutablePath)
        }
    }

    switch ($Manifest.ShortcutType) {
        'desktop' {
            Get-Shortcut -Path (Expand-Path $Manifest.ExecutablePath) -Name $Manifest.ShortcutName
        }

        'shim' {
            Get-Shim -Path (Expand-Path $Manifest.ExecutablePath) -Name $Manifest.ShortcutName
        }
    }
}
