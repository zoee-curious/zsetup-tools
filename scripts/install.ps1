function Invoke-LocalInstall {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    Invoke-Required @PSBoundParameters

    $uri = "$BaseUrl/getScript"
    $headers = Get-Headers @PSBoundParameters
    $outputScript = Join-Path $ScriptsDir "zst.ps1"

    try {
        Invoke-RestMethod -Uri $uri -Headers $headers -OutFile $outputScript
    }
    catch {
        Write-FormattedRow -Text "Failed writing script, may access danied!" -Color Yellow
        return
    }

    Invoke-Shim -Path $outputScript -Name "zst"
    Write-FormattedRow -Text "Successfuly install latest version!" -Color Yellow
}
