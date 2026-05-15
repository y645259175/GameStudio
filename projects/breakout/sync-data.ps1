# 同步 data/ 主本 → game/data/ 副本
# 用法：在项目根目录运行 powershell -File sync-data.ps1

$src = Join-Path $PSScriptRoot "data"
$dst = Join-Path $PSScriptRoot "game\data"

Get-ChildItem $src -Filter "*.json" | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $dst $_.Name) -Force
    Write-Host "synced: $($_.Name)"
}
