#!/usr/bin/env bash
# Build a shareable Cygnet zip. Usage:
#
#   tools/package.sh [windows|linux|web|all] [path/to/godot]
#
# Exports through the presets in game/export_presets.cfg, drops the player
# README and the credits in beside the binary, and zips the result into
# build/. Needs the 4.7.2 export templates installed (see docs/PACKAGING.md).
set -euo pipefail

target="${1:-windows}"
godot="${2:-godot}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stamp="$(date +%Y%m%d)"
rev="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo nogit)"

package() {
	local preset="$1" dir="$2" binary="$3"
	local out="$root/build/$dir"
	rm -rf "$out"
	mkdir -p "$out"
	echo "==> exporting $preset"
	"$godot" --headless --path "$root/game" --export-release "$preset" "$out/$binary"
	cp "$root/dist/README.txt" "$root/dist/CREDITS.txt" "$out/"
	local zip="$root/build/Cygnet-$dir-$stamp-$rev.zip"
	rm -f "$zip"
	( cd "$root/build" && zip -qr "$zip" "$dir" )
	echo "    $zip  ($(du -h "$zip" | cut -f1))"
}

case "$target" in
	windows) package "Windows" windows "Cygnet.exe" ;;
	linux)   package "Linux"   linux   "Cygnet.x86_64" ;;
	web)     package "Web"     web     "index.html" ;;
	all)
		package "Windows" windows "Cygnet.exe"
		package "Linux"   linux   "Cygnet.x86_64"
		package "Web"     web     "index.html"
		;;
	*) echo "unknown target: $target (windows|linux|web|all)" >&2; exit 1 ;;
esac
