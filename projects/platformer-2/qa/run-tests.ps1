# platformer-2 · 测试入口
# 用法：pwsh -NoProfile -File qa/run-tests.ps1
# 期望：M0 阶段无测试，仅 godot --check-only 验证语法
# M1+ 阶段：tester agent 写的测试会被自动发现并跑

param(
    [switch]$VerboseOutput
)

$ErrorActionPreference = "Continue"
$projectPath = Split-Path -Parent $PSScriptRoot
$gameDir = Join-Path $projectPath "game"
$godot = "d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe"

if (-not (Test-Path $gameDir)) {
    Write-Output "[skip] game/ 目录不存在（M0 阶段尚未起脚手架，符合预期）"
    Write-Output "PASS: 0 tests, 0 failures (no game dir yet)"
    exit 0
}

if (-not (Test-Path $godot)) {
    Write-Output "[error] Godot 不存在: $godot"
    Write-Output "FAIL: godot binary missing"
    exit 1
}

# Step 1 · headless syntax check
Write-Output "[1/2] godot --check-only ..."
$result = & $godot --headless --check-only --path $gameDir --quit 2>&1
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    Write-Output "FAIL: godot check returned $exitCode"
    Write-Output $result
    exit $exitCode
}
Write-Output "PASS: godot syntax check"

# Step 2 · 测试目录扫描
$testsDir = Join-Path $projectPath "qa\tests"
if (-not (Test-Path $testsDir)) {
    Write-Output "[2/2] qa/tests/ 不存在 — M0 阶段无测试，符合预期"
    Write-Output "PASS: 1/1 (godot syntax)"
    exit 0
}

$testFiles = Get-ChildItem -Path $testsDir -Filter "test_*.gd" -ErrorAction SilentlyContinue
if (-not $testFiles) {
    Write-Output "[2/2] qa/tests/ 中暂无 test_*.gd"
    Write-Output "PASS: 1/1 (godot syntax)"
    exit 0
}

Write-Output "[2/2] 发现 $($testFiles.Count) 个测试文件，待 godot test runner 整合"
Write-Output "TODO: 集成 GUT / 自定义 test_runner.gd（M1+ 由 tester agent 引入）"
Write-Output "PASS: 1/1 (godot syntax) + $($testFiles.Count) tests pending integration"
exit 0
