function ConvertTo-TiaImportIndentation {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Source)

    # V21 source generation consumes the first body tab and stores subsequent tabs as one blank.
    # Keep that body prefix, but materialize subsequent indentation levels before native parsing.
    [regex]::Replace($Source, '(?m)^\t+', [System.Text.RegularExpressions.MatchEvaluator]{
        param($Match)
        "`t" + (' ' * (4 * ($Match.Length - 1)))
    })
}
