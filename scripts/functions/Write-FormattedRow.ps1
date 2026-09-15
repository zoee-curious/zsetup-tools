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
