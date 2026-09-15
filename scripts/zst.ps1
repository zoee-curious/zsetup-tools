param(
    [string]$Action,
    [string]$Name,
    [switch]$Public,
    [switch]$Private,
    [switch]$Cache,
    [switch]$NoCache
)

$BaseUrl = "https://zoee.fun"

$BaseDir = Join-Path $HOME "zsetup"
$ShimsDir = Join-Path $BaseDir "shims"
$ScriptsDir = Join-Path $BaseDir "scripts"
$LocalDir = Join-Path $BaseDir "apps"
$TempDir = Join-Path $BaseDir "temp"

$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'


function Clear-Shims {
    Get-ChildItem -Path (Join-Path $ShimsDir "*.cmd") -ErrorAction SilentlyContinue | ForEach-Object {
        if ((Get-Content $_.FullName -Raw) -match '"([^"]+\.exe)"' -and -not (Test-Path $Matches[1])) {
            Remove-Items -Paths $_.FullName
        }
    }
    return
}


function Copy-Items {
    param (
        [hashtable]$Paths = @{}
    )
    
    foreach ($path in $Paths.GetEnumerator()) {
        New-Dirs -Paths $path.Value
        Copy-Item -Path $path.Key -Destination $path.Value -Recurse -Force | Out-Null        
    }
    return
}


function Expand-Path {
    param (
        [psobject]$Path
    )

    $maps = @{
        '<BaseDir>'    = $BaseDir
        '<ShimsDir>'   = $ShimsDir
        '<ScriptsDir>' = $ScriptsDir
        '<LocalDir>'   = $LocalDir
        '<TempDir>'    = $TempDir
    }

    foreach ($map in $maps.GetEnumerator()) {
        $Path = $Path.Replace($map.key, $map.Value)
    }
    return $Path
}


function Get-Aria2Headers {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $getHeadersParams = @{
        Public  = $Public
        Private = $Private
        Cache   = $Cache
        NoCache = $NoCache
    }

    $aria2Headers = @{}
    $headers = Get-Headers @getHeadersParams
    foreach ($header in $headers.GetEnumerator()) {
        $aria2Headers += "--header=$($header.Key): $($header.Value)"
    }
    return $aria2Headers
}


function Get-Headers {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $headers = @{}
    $configFile = Join-Path $HOME ".zsetup"

    if (Test-Path $configFile) {
        try {
            $config = Get-Content $configFile -Raw | ConvertFrom-Json
            if ($config.apiKey) {
                $headers["x-api-key"] = $config.apiKey
            }

            if ($Public) {
                $headers["x-scope"] = 'public'
            }
            elseif ($Private) {
                $headers["x-scope"] = 'private'
            }
            elseif ($config.scope) {
                $headers["x-scope"] = $config.scope
            }

            if ($Cache) {
                $headers["Cache-Control"] = "public, max-age=3600"
            }
            elseif ($NoCache -or $config.noCache) {
                $headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
                $headers["Pragma"] = "no-cache"
            }            
        }
        catch {
            Write-FormattedRow -Text "Failed parsed", ": $configFile" -Color Yellow
        }
    }
    return $headers
}


function Get-IndexManifest {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $getHeadersParams = @{
        Public  = $Public
        Private = $Private
        Cache   = $Cache
        NoCache = $NoCache
    }

    try {
        $uri = "$BaseUrl/getIndexManifest"
        $headers = Get-Headers @getHeadersParams
        Invoke-RestMethod -Uri $uri -Headers $headers
    }
    catch {
        return $null
    }
}


function Get-Manifest {
    param (
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $getHeadersParams = @{
        Public  = $Public
        Private = $Private
        Cache   = $Cache
        NoCache = $NoCache
    }

    try {
        $uri = "$BaseUrl/getManifest/$Name"
        $headers = Get-Headers @getHeadersParams
        Invoke-RestMethod -Uri $uri -Headers $headers
    }
    catch {
        return $null
    }
}


function Invoke-Download {
    param (
        [string]$Method,
        [string]$Uri,
        [string]$OutDir,
        [string]$OutName,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $getHeadersParams = @{
        Public  = $Public
        Private = $Private
        Cache   = $Cache
        NoCache = $NoCache
    }

    function Invoke-Download {
        $outPath = Join-Path $OutDir $OutName
        $headers = Get-Headers @getHeadersParams
        Invoke-WebRequest -Uri $Uri -Headers $headers -OutFile $outPath
    }

    function Invoke-Aria2Download {
        $headers = Get-Aria2Headers @getHeadersParams
        aria2c -s 16 -x 16 -K 1M --allow-overwrite=true `
            -d $OutDir -o $OutName $headers $Uri | Out-Null
    }

    switch ($Method) {
        'invoke' {
            Invoke-Download
        }

        'aria2' {
            try {
                Invoke-Aria2Download
            }
            catch {
                Invoke-Download
            }
        }
    }
    return
}


function Invoke-Extract {
    param (
        [string]$Method,
        [string]$Archive,
        [string]$OutDir,
        [psobject]$Password
    )

    function Expand-WithTar {
        tar -xf $Archive -C $OutDir | Out-Null
    }

    function Expand-With7z {
        if ($Password) {
            7z x $Archive -o"$OutDir" -p"$Password" -y | Out-Null
        }
        else {
            7z x $Archive -o"$OutDir" -y | Out-Null
        }
    }

    New-Dirs -Paths $OutDir
    switch ($Method) {
        'tar' {
            Expand-WithTar
        }

        '7z' {
            try {
                Expand-With7z
            }
            catch {
                Expand-WithTar
            }
        }

    }
    return
}


function Invoke-Required {
    $paths = @(
        $BaseDir
        $ShimsDir
        $ScriptsDir
        $LocalDir
        $TempDir
    )
    
    New-Dirs -Paths $paths
    $env:PATH += ";$ShimsDir"
    $oldPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($oldPath -notlike "*$ShimsDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$oldPath;$ShimsDir", "User")
    }
    return
}


function Invoke-Search {
    param (
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $getIndexManifestParams = @{
        Public  = $Public
        Private = $Private
        Cache   = $Cache
        NoCache = $NoCache
    }
    
    $indexManifest = Get-IndexManifest @getIndexManifestParams
    if (-not $indexManifest) {
        Write-FormattedRow -Text "Not found!", ": manifests-index.json" -Color Yellow
        return
    }

    $results = $indexManifest | Where-Object {
        $_.id -like "*$Name*" -or
        $_.name -like "*$Name*" -or
        ($_.aliases | Where-Object { $_ -like "*$Name*" })
    }

    if (-not $results -or $results.Count -eq 0) {
        Write-FormattedRow -Text "Not found!", ": $Name" -Color Yellow
        return
    }

    $widths = @(35, 24, 10, 40)
    $totalWidth = ($widths | Measure-Object -Sum).Sum

    Write-FormattedRow -Text "ID", "Name", "Version", "Description" -Width $widths
    Write-Host ("-" * $totalWidth ) -ForegroundColor DarkGray

    foreach ($result in $results) {
        if ($result.description) {
            $findDescription = $result.description
            if ($findDescription.Length -gt 40) {
                $description = $findDescription.Substring(0, 37) + "..."
            }
            else {
                $description = $findDescription 
            }
        }
        else { 
            $description = "-" 
        }

        Write-FormattedRow -Text $result.id, $result.name, $result.version, $description -Width $widths
    }
    return
}


function Invoke-Shim {
    param (
        [string]$Path,
        [string]$Name
    )

    if (-not (Test-Path $Path)) {
        Write-FormattedRow -Text "Not found!", ": $Path" -Color Yellow
        return
    }
    
    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    $shimPath = Join-Path $ShimsDir "$Name.cmd"
    $exec = switch ($ext) {
        '.ps1' { "powershell -ExecutionPolicy Bypass -NoProfile -File ""$Path"" %*" }
        '.py' { "python ""$Path"" %*" }
        default { """$Path"" %*" }
    }

    Set-Content -Path $shimPath -Value "@echo off`n$exec" -Encoding ASCII -Force
    return
}


function Invoke-Shortcut {
    param (
        [string]$Path,
        [string]$Name
    )

    $wshShell = New-Object -ComObject WScript.Shell
    $desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
    $shortcutPath = Join-Path $desktopPath "$Name.lnk"
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $Path
    $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($Path)
    $shortcut.Save()
    return
}


function New-Dirs {
    param (
        [array]$Paths = @()
    )

    foreach ($path in $Paths) {
        if (-not(Test-Path $path -ErrorAction SilentlyContinue)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    return
}


function Remove-Items {
    param (
        [array]$Paths = @()
    )

    foreach ($path in $Paths) {
        if (Test-Path $path -ErrorAction SilentlyContinue) {
            Remove-Item -Path $path -Recurse -Force | Out-Null
        }
    }
    return
}


function Set-State {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $config = @{}
    $configFile = Join-Path $HOME ".zsetup"

    if (Test-Path $configFile) {
        $jsonContents = Get-Content $configFile -Raw | ConvertFrom-Json
        if ($jsonContents) {
            foreach ($content in $jsonContents.psobject.properties) {
                $config[$content.Name] = $content.Value
            }
        }
    }

    if ($Public) {
        $config["scope"] = 'public' 
    }
    elseif ($Private) {
        $config["scope"] = 'private' 
    }

    if ($Cache) {
        $config["noCache"] = $false 
    }
    elseif ($NoCache) {
        $config["noCache"] = $true 
    }

    $config | ConvertTo-Json | Set-Content $configFile
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
    return
}


function Show-Manifest {
    param (
        [string]$Name,
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $getManifestParams = @{
        Name    = $Name
        Public  = $Public
        Private = $Private
        Cache   = $Cache
        NoCache = $NoCache
    }

    $manifest = Get-Manifest @getManifestParams
    if (-not $manifest) { 
        Invoke-Search @getManifestParams
        return
    }
    
    Write-Manifest -Manifest $manifest
    return
}


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


function Write-FormattedRow {
    param(
        [string[]]$Text,
        [ConsoleColor[]]$Color,
        [int[]]$Width,
        [int]$Indent
    )

    if (-not $Color -or $Color.Count -eq 0) { 
        $Color = @('Gray') 
    }

    if (-not $Width -or $Width.Count -eq 0) {
        $Width = @(20) 
    }

    if (-not $Indent) {
        $Indent = 0 
    }

    if ($Indent -gt 0) {
        Write-Host (" " * $Indent) -NoNewline
    }

    for ($i = 0; $i -lt $Text.Count; $i++) {
        $cellText = $Text[$i]
        $cellColor = if ($i -lt $Color.Count) { $Color[$i] } else { $Color[-1] }

        if ($i -eq ($Text.Count - 1)) {
            Write-Host $cellText -ForegroundColor $cellColor
        }
        else {
            $cellWidth = if ($i -lt $Width.Count) { $Width[$i] } else { $Width[-1] }
            $paddedText = "{0,-$cellWidth}" -f $cellText
            Write-Host $paddedText -NoNewline -ForegroundColor $cellColor
        }
    }
    return
}


function Write-Manifest {
    param (
        [psobject]$Manifest
    )
    
    $manifestMap = [ordered]@{
        "ID"               = $Manifest.Id
        "Name"             = $Manifest.Name
        "Version"          = $Manifest.Version
        "Publisher"        = $Manifest.Publisher
        "Description"      = $Manifest.Description
        "Aliases"          = ($Manifest.Aliases -join ", ")
        "URL"              = $Manifest.Url
        "Archive Type"     = $Manifest.ArchiveType
        "Output Name"      = $Manifest.OutName
        "Output Dir"       = $Manifest.OutDir
        "Output Path"      = $Manifest.OutPath
        "Download Method"  = $Manifest.DownloadMethod
        "Extract Method"   = $Manifest.ExtractMethod
        "Extract Password" = $Manifest.ExtractPassword
        "Install Type"     = $Manifest.InstallType
        "Extract Dir"      = $Manifest.ExtractDir
        "Install Dir"      = $Manifest.InstallDir
        "Executable Path"  = $Manifest.ExecutablePath
        "Shortcut Type"    = $Manifest.ShortcutType
        "Shortcut Name"    = $Manifest.ShortcutName
    }
    
    if ($Manifest) {
        Write-Host
        foreach ($obj in $manifestMap.GetEnumerator()) {
            if ($obj.Value) {
                Write-FormattedRow -Text $obj.Key, ": $(Expand-Path -Path $obj.Value)"
            }
        }
        Write-Host
    }
    return
}


$manifest = Get-Manifest -Name 'aria2'
$manifestData = Expand-Path -Path $manifest
Write-Host $manifestData

exit

Clear-Shims
Test-Command -Action $Action -Name $Name -Help:$Help

switch ($Action) {
    'state' {
        $setStateParams = @{
            Public  = $Public
            Private = $Private
            Cache   = $Cache
            NoCache = $NoCache
        }

        Set-State @setStateParams
    }

    'search' {
        $invokeSearchParams = @{
            Name    = $Name
            Public  = $Public
            Private = $Private
            Cache   = $Cache
            NoCache = $NoCache
        }

        Invoke-Search @invokeSearchParams
    }

    'show' {
        $showManifestParams = @{
            Name    = $Name
            Public  = $Public
            Private = $Private
            Cache   = $Cache
            NoCache = $NoCache
        }

        Show-Manifest @showManifestParams
    }
}

