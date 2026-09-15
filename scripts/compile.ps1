param(
    [switch]$Run
)

function Invoke-ScriptCompile {
    param (
        [switch]$Run
    )

    $RootPath = $PSScriptRoot
    
    $startScript = Join-Path $RootPath "start.ps1"
    $functionsDir = Join-Path $RootPath "functions"
    $mainScript = Join-Path $RootPath "main.ps1"

    $startContent = Get-Content -Path $startScript -Raw
    $functionsContent = (Get-ChildItem -Path $functionsDir -Filter "*.ps1" -File | ForEach-Object {
            Get-Content -Path $_.FullName -Raw
        }) -join "`n`n"
    $mainContent = Get-Content -Path $mainScript -Raw
    $scriptContent = @($startContent, $functionsContent, $mainContent) -join "`n`n"

    $outputScript = Join-Path $RootPath "zst.ps1"
    Set-Content -Path $outputScript -Value $scriptContent

    if ($Run) {
        & $outputScript
    }
}

Invoke-ScriptCompile -Run:$Run
