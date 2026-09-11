<#
.SYNOPSIS
  Build a shareable Cygnet zip on Windows.

.EXAMPLE
  .\tools\package.ps1
  .\tools\package.ps1 -Target all -Godot "C:\Godot\Godot_v4.7.2-stable_win64.exe"

  Exports through the presets in game\export_presets.cfg, drops the player
  README and the credits in beside the binary, and zips the result into
  build\. Needs the 4.7.2 export templates installed — see docs\PACKAGING.md.

  Point -Godot at the *editor* executable (not the _console one). If Godot is
  already on your PATH you can leave it off.
#>
param(
	[ValidateSet('windows', 'linux', 'web', 'all')]
	[string]$Target = 'windows',
	[string]$Godot = 'godot'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd'
$rev = (git -C $root rev-parse --short HEAD 2>$null)
if (-not $rev) { $rev = 'nogit' }

function Build-Package($preset, $dir, $binary) {
	$out = Join-Path $root "build\$dir"
	if (Test-Path $out) { Remove-Item $out -Recurse -Force }
	New-Item -ItemType Directory -Path $out -Force | Out-Null

	Write-Host "==> exporting $preset"
	& $Godot --headless --path (Join-Path $root 'game') --export-release $preset (Join-Path $out $binary)
	if ($LASTEXITCODE -ne 0) { throw "export failed for $preset (exit $LASTEXITCODE)" }

	Copy-Item (Join-Path $root 'dist\README.txt') $out
	Copy-Item (Join-Path $root 'dist\CREDITS.txt') $out

	$zip = Join-Path $root "build\Cygnet-$dir-$stamp-$rev.zip"
	if (Test-Path $zip) { Remove-Item $zip -Force }
	Compress-Archive -Path $out -DestinationPath $zip
	$size = '{0:N0} MB' -f ((Get-Item $zip).Length / 1MB)
	Write-Host "    $zip  ($size)"
}

switch ($Target) {
	'windows' { Build-Package 'Windows' 'windows' 'Cygnet.exe' }
	'linux'   { Build-Package 'Linux'   'linux'   'Cygnet.x86_64' }
	'web'     { Build-Package 'Web'     'web'     'index.html' }
	'all' {
		Build-Package 'Windows' 'windows' 'Cygnet.exe'
		Build-Package 'Linux'   'linux'   'Cygnet.x86_64'
		Build-Package 'Web'     'web'     'index.html'
	}
}
