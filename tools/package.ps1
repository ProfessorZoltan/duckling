<#
.SYNOPSIS
  Build a shareable Cygnet zip on Windows.

.EXAMPLE
  .\tools\package.ps1
  .\tools\package.ps1 -Target all
  .\tools\package.ps1 -Godot "C:\Godot\Godot_v4.7.2-stable_win64.exe"

  Exports through the presets in game\export_presets.cfg, drops the player
  README and the credits in beside the binary, and zips the result into
  build\. Needs the 4.7.2 export templates installed — see docs\PACKAGING.md.

  Godot is found automatically: first on your PATH, then in the usual install
  and download folders. Pass -Godot if it lives somewhere unusual.
#>
param(
	[ValidateSet('windows', 'linux', 'web', 'all')]
	[string]$Target = 'windows',
	[string]$Godot = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd'
$rev = (git -C $root rev-parse --short HEAD 2>$null)
if (-not $rev) { $rev = 'nogit' }

function Resolve-Godot([string]$hint) {
	# An explicit path wins, and a wrong one is an error rather than a
	# silent fallback to something else on the machine.
	if ($hint) {
		if (Test-Path -LiteralPath $hint) { return (Resolve-Path -LiteralPath $hint).Path }
		$onPath = Get-Command $hint -ErrorAction SilentlyContinue
		if ($onPath) { return $onPath.Source }
		throw "-Godot '$hint' is not a file and is not on your PATH."
	}

	foreach ($name in 'godot', 'godot4', 'Godot_v4.7.2-stable_win64') {
		$cmd = Get-Command $name -ErrorAction SilentlyContinue
		if ($cmd) { return $cmd.Source }
	}

	# Not on the PATH, which is normal — the Windows build of Godot is a bare
	# .exe you unzip wherever, so look in the places it usually lands.
	$roots = @(
		"$env:LOCALAPPDATA\Programs",
		"$env:ProgramFiles",
		${env:ProgramFiles(x86)},
		"$env:USERPROFILE\Downloads",
		"$env:USERPROFILE\Desktop",
		"$env:USERPROFILE\Documents",
		'C:\Godot'
	) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

	$found = @()
	foreach ($r in $roots) {
		$found += Get-ChildItem -LiteralPath $r -Filter 'Godot*.exe' -File -Recurse -Depth 2 -ErrorAction SilentlyContinue
	}
	# The _console.exe is a wrapper, not the editor.
	$found = $found | Where-Object { $_.Name -notlike '*_console.exe' }

	if (-not $found) {
		throw @"
Could not find Godot.

Looked on your PATH and under:
$($roots -join "`n")

Run it again pointing at the editor executable, for example:
  .\tools\package.ps1 -Godot "C:\Godot\Godot_v4.7.2-stable_win64.exe"

(In the Godot editor, Help -> About shows nothing useful for this; the path
is wherever you unzipped the download.)
"@
	}

	$best = $found | Where-Object { $_.Name -like '*4.7.2*' } | Select-Object -First 1
	if (-not $best) { $best = $found | Sort-Object Name -Descending | Select-Object -First 1 }
	return $best.FullName
}

$godotExe = Resolve-Godot $Godot
Write-Host "Godot: $godotExe"
if ($godotExe -notlike '*4.7.2*') {
	Write-Warning "That does not look like Godot 4.7.2. The project needs 4.7.2; a different version may fail to export or produce a broken build."
}

function Build-Package($preset, $dir, $binary) {
	$out = Join-Path $root "build\$dir"
	if (Test-Path $out) { Remove-Item $out -Recurse -Force }
	New-Item -ItemType Directory -Path $out -Force | Out-Null

	Write-Host "==> exporting $preset"
	# Always reimport first. A stale .godot cache keeps the OLD property list
	# for a changed script, and the export then silently drops scene values it
	# no longer recognises — which is how a build shipped with every duck
	# reading the same placeholder line. Cheap insurance.
	& $godotExe --headless --path (Join-Path $root 'game') --import 2>&1 | Out-Null

	& $godotExe --headless --path (Join-Path $root 'game') --export-release $preset (Join-Path $out $binary)
	$code = $LASTEXITCODE
	if ($code -ne 0 -or -not (Test-Path (Join-Path $out $binary))) {
		throw @"
Export failed for '$preset' (exit $code).

The usual cause is missing export templates. In the Godot editor:
  Editor -> Manage Export Templates... -> Download and Install
It has to say 4.7.2.stable when it finishes.
"@
	}

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
