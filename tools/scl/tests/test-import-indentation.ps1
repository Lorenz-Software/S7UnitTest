$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../convert-import-indentation.ps1')

$source = "BEGIN`r`n`tREGION Example`r`n`t`tIF #Enabled THEN`r`n`t`t`t#Value := 'a`tb'; // keep`tcomment`r`n`t`tEND_IF;`r`n`tEND_REGION`r`nEND_FUNCTION`r`n"
$expected = "BEGIN`r`n`tREGION Example`r`n`t    IF #Enabled THEN`r`n`t        #Value := 'a`tb'; // keep`tcomment`r`n`t    END_IF;`r`n`tEND_REGION`r`nEND_FUNCTION`r`n"
$actual = ConvertTo-TiaImportIndentation $source
if ($actual -cne $expected) { throw 'Incorrect indentation conversion or non-leading text changed.' }
if ((ConvertTo-TiaImportIndentation $actual) -cne $actual) { throw 'Preparation is not idempotent.' }
$unicode = [string][char]0xFEFF + "`t`t// " + [string][char]0x00E4 + "`r`n"
if ((ConvertTo-TiaImportIndentation $unicode) -cne $unicode) { throw 'BOM-prefixed first line must not be rewritten.' }
if ((ConvertTo-TiaImportIndentation '') -cne '') { throw 'Empty source changed.' }
Write-Output 'Passed: structural tabs, closing alignment, literal/comment tabs, CRLF, idempotence, BOM and Unicode preservation.'
