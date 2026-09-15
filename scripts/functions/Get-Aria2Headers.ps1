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
