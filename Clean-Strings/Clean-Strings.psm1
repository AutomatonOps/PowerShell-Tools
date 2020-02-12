function Convert-MixedLineEndingToNewLine {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace "(\n|\r)+","`n")
}

function Remove-MultipleEmptyLines {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace "(\n|\r){2,}","`n")
}

function Remove-LeadingEmptyLines {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace "^(\n|\r)+","")
}

function Remove-TrailingEmptyLines {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace "(\n|\r)+$","")
}

function Remove-MultipleSpaces {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace " {2,}"," ")
}

function Remove-TrailingSpaces {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace "\n +", "`n")
}

function Remove-SpacesThatPrecedeNewlines {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace " +\n", "`n")
}

function Remove-WhiteSpaceFromTheStart {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace "^\s+","")
}

function Remove-WhiteSpaceFromTheEnd {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace "\s+$","")
}

function Remove-NonPrintingCharacters {
    param(
        [parameter(ValueFromPipeline, Mandatory = $true)][string]$String
    )

    Write-Output ($String -replace "[\u0000-\u001F|\u0080-\u00FF|\u2028|\u2029]","")
}