param(
	[string]$ToolsDir = "$env:TEMP\luau-tools",
	[string]$Rojo = "..\DharmaSanctuary\rojo.exe"
)
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
$rojo = Join-Path $root $Rojo
$tmp = Join-Path $env:TEMP "bladestorm-verify"
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force "$tmp\shared" | Out-Null

$shim = 'local Color3 = { fromRGB = function(r, g, b) return { r = r, g = g, b = b } end }; local Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z } end }'
Get-ChildItem "$root\src\shared\*.luau" | ForEach-Object {
	$lines = Get-Content $_.FullName
	$text = ($lines | Select-Object -Skip 1) -join "`n"
	$text = [regex]::Replace($text, 'require\(script\.Parent\.(\w+)\)', 'require("./$1")')
	Set-Content -Path (Join-Path "$tmp\shared" $_.Name) -Value ($lines[0] + "`n" + $shim + "`n" + $text) -NoNewline
}
Copy-Item "$root\tests\logic.test.luau" "$tmp\logic.test.luau"

Write-Host "== 1/3 logic tests =="
Push-Location $tmp
& "$ToolsDir\luau.exe" logic.test.luau 2>&1 | ForEach-Object { "$_" }
$logicExit = $LASTEXITCODE
Pop-Location

Write-Host "== 2/3 luau-lsp analyze =="
$sourcemap = Join-Path $tmp "sourcemap.json"
& $rojo sourcemap "$root\default.project.json" -o $sourcemap 2>&1 | ForEach-Object { "$_" }
Push-Location $root
& "$ToolsDir\luau-lsp.exe" analyze --sourcemap $sourcemap --definitions "$ToolsDir\globalTypes.d.luau" --base-luaurc "$root\.luaurc" src 2>&1 | ForEach-Object { "$_" }
$analyzeExit = $LASTEXITCODE
Pop-Location

Write-Host "== 3/3 rojo build =="
$pubDir = Join-Path $root "publish"
New-Item -ItemType Directory -Force $pubDir | Out-Null
$out = Join-Path $pubDir "Blade-Storm-RNG-Tycoon.rbxl"
& $rojo build "$root\default.project.json" -o $out 2>&1 | ForEach-Object { "$_" }
$rojoExit = $LASTEXITCODE

Write-Host ""
Write-Host ("logic tests : " + $(if ($logicExit -eq 0) { "PASS" } else { "FAIL" }))
Write-Host ("analyzer    : " + $(if ($analyzeExit -eq 0) { "PASS" } else { "FAIL" }))
Write-Host ("rojo build  : " + $(if ($rojoExit -eq 0) { "PASS ($out)" } else { "FAIL" }))
if ($logicExit -ne 0 -or $analyzeExit -ne 0 -or $rojoExit -ne 0) { exit 1 }
