param([string]$startCommitID)

$files = git diff --name-only --diff-filter=d $StartCommitID timesheet.DB/*.sql
if ($files) {
    Get-Content -Encoding UTF8 -LiteralPath $files | Set-Content -Encoding UTF8 ./DiffScript.sql
}else{
    Write-Host "nessuna differenza SQL trovata."
}
