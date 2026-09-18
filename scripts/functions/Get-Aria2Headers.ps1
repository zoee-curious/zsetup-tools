function Get-Aria2Headers {
    param (
        [switch]$Public,
        [switch]$Private,
        [switch]$Cache,
        [switch]$NoCache
    )

    $aria2Headers = @()
    $headers = Get-Headers @PSBoundParameters
    foreach ($header in $headers.GetEnumerator()) {
        $aria2Headers += "--header=$($header.Key):$($header.Value)"
    }
    return $aria2Headers
}
