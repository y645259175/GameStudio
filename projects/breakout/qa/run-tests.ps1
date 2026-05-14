# Breakout QA Suite Runner
# Run from anywhere; uses absolute paths.
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File projects\breakout\qa\run-tests.ps1

$ErrorActionPreference = "Stop"

$Godot = "d:\AI\GameStudio\engine\Godot\Godot_v4.6.2-stable_win64.exe"
$ProjectPath = "d:\AI\GameStudio\projects\breakout\game"

$Tests = @(
    @{ Name = "Levels Data";       Script = "res://tests/test_levels.gd" }
    @{ Name = "GameManager";       Script = "res://tests/test_game_manager.gd" }
    @{ Name = "PowerupManager";    Script = "res://tests/test_powerup_manager.gd" }
)

$totalPass = 0
$totalFail = 0
$suiteFail = 0

foreach ($t in $Tests) {
    Write-Host "`n=== $($t.Name) ===" -ForegroundColor Cyan
    $outFile = "$env:TEMP\bk_test_out.txt"
    $errFile = "$env:TEMP\bk_test_err.txt"
    $proc = Start-Process -FilePath $Godot `
        -ArgumentList "--headless", "--path", $ProjectPath, "-s", $t.Script, "--quit" `
        -NoNewWindow -PassThru `
        -RedirectStandardOutput $outFile `
        -RedirectStandardError $errFile
    $null = $proc | Wait-Process -Timeout 60 -ErrorAction SilentlyContinue
    if (!$proc.HasExited) {
        $proc.Kill()
        Write-Host "TIMEOUT" -ForegroundColor Red
        $suiteFail += 1
        continue
    }

    $out = Get-Content $outFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    Write-Host $out

    if ($proc.ExitCode -ne 0) {
        $err = Get-Content $errFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($err) { Write-Host $err -ForegroundColor Yellow }
        $suiteFail += 1
    }

    # 解析 PASS / FAIL 计数
    if ($out -match "(\d+) passed, (\d+) failed") {
        $totalPass += [int]$matches[1]
        $totalFail += [int]$matches[2]
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TOTAL: $totalPass passed, $totalFail failed across $($Tests.Count) suites" -ForegroundColor $(if ($totalFail -eq 0 -and $suiteFail -eq 0) { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan

if ($totalFail -gt 0 -or $suiteFail -gt 0) { exit 1 } else { exit 0 }
