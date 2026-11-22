# SCL Import Indentation

`convert-import-indentation.ps1` provides `ConvertTo-TiaImportIndentation` for
preparing structurally tab-indented SCL before TIA Portal V21 source generation.
V21 consumes the first leading body tab and stores further tabs as single blanks.
The function retains the first tab and replaces each subsequent leading tab with
four spaces, preserving readable nesting after import.

## Usage

Run in PowerShell 7.2 or newer from the publication directory. Use a separate,
new output file; do not overwrite the original source:

```powershell
. ./tools/scl/convert-import-indentation.ps1
$source = [IO.File]::ReadAllText('input.scl', [Text.UTF8Encoding]::new($false, $true))
$prepared = ConvertTo-TiaImportIndentation -Source $source
$output = [IO.File]::Open('prepared.scl', [IO.FileMode]::CreateNew)
try {
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($prepared)
    $output.Write($bytes, 0, $bytes.Length)
} finally { $output.Dispose() }
```

The function returns text only. It does not import, compile or save a TIA project,
or access a PLC. Import the prepared copy through your chosen TIA workflow and
check the stored source and compiler diagnostics.

## Scope And Test

Only consecutive tab characters at the beginning of a line are converted.
Existing spaces and tabs after other characters, including inside literals and
comments, are unchanged. This is not a general SCL formatter, syntax validator
or conversion of arbitrary indentation styles. Use it for the structural-tab
source representation described above, not as a reformatter for stored exports.

```powershell
pwsh -NoProfile -File ./tools/scl/tests/test-import-indentation.ps1
```

The focused test checks structural indentation, closing alignment, embedded tabs,
line endings, repeated application, BOM handling and Unicode preservation.
It runs without TIA Portal. It does not replace native import/readback checks.
