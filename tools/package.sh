#!/usr/bin/env bash
# Build a shareable Cygnet zip. Usage:
#
#   tools/package.sh [windows|linux|web|all] [path/to/godot]
#
# Exports through the presets in game/export_presets.cfg, drops the player
# README and the credits in beside the binary, and zips the result into
# build/. Needs the 4.7.2 export templates installed (see docs/PACKAGING.md).
#
# Godot is found automatically: first on the PATH, then in the usual install
# and download folders. Pass a path as the second argument if it lives
# somewhere unusual.
set -euo pipefail

target="${1:-windows}"
hint="${2:-}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stamp="$(date +%Y%m%d)"
rev="$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo nogit)"

resolve_godot() {
	# An explicit path wins, and a wrong one is an error rather than a silent
	# fallback to something else on the machine.
	if [[ -n "$hint" ]]; then
		if [[ -x "$hint" ]]; then echo "$hint"; return; fi
		if command -v "$hint" >/dev/null 2>&1; then command -v "$hint"; return; fi
		echo "error: '$hint' is not executable and is not on your PATH." >&2
		exit 1
	fi

	local name
	for name in godot godot4 Godot_v4.7.2-stable_linux.x86_64; do
		if command -v "$name" >/dev/null 2>&1; then command -v "$name"; return; fi
	done

	# Not on the PATH, which is normal — the Linux build of Godot is a bare
	# binary you unzip wherever, so look where it usually lands.
	local dir found
	for dir in "$HOME/Downloads" "$HOME/Desktop" "$HOME/bin" "$HOME/.local/bin" \
		"/opt" "/usr/local/bin" "$HOME/Applications"; do
		[[ -d "$dir" ]] || continue
		found="$(find "$dir" -maxdepth 3 -type f -name 'Godot*' -perm -u+x 2>/dev/null \
			| grep -v '_console' | sort -r | head -n 1)"
		[[ -n "$found" ]] && { echo "$found"; return; }
	done

	cat >&2 <<-MSG
	error: could not find Godot.

	Looked on your PATH and under ~/Downloads, ~/Desktop, ~/bin, ~/.local/bin,
	/opt, /usr/local/bin and ~/Applications.

	Run it again pointing at the editor binary, for example:
	  tools/package.sh windows ~/Downloads/Godot_v4.7.2-stable_linux.x86_64
	MSG
	exit 1
}

godot="$(resolve_godot)"
echo "Godot: $godot"
case "$godot" in
	*4.7.2*) ;;
	*) echo "warning: that does not look like Godot 4.7.2. The project needs 4.7.2;" >&2
	   echo "         a different version may fail to export or produce a broken build." >&2 ;;
esac

package() {
	local preset="$1" dir="$2" binary="$3"
	local out="$root/build/$dir"
	rm -rf "$out"
	mkdir -p "$out"
	echo "==> exporting $preset"
	# Always reimport first. A stale .godot cache keeps the OLD property list
	# for a changed script, and the export then silently drops scene values it
	# no longer recognises — which is how a build shipped with every duck
	# reading the same placeholder line. Cheap insurance.
	"$godot" --headless --path "$root/game" --import >/dev/null 2>&1 || true
	if ! "$godot" --headless --path "$root/game" --export-release "$preset" "$out/$binary" \
		|| [[ ! -e "$out/$binary" ]]; then
		cat >&2 <<-MSG

		error: export failed for '$preset'.

		The usual cause is missing export templates. In the Godot editor:
		  Editor -> Manage Export Templates... -> Download and Install
		It has to say 4.7.2.stable when it finishes.
		MSG
		exit 1
	fi
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
