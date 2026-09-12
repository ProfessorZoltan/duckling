# Packaging a build to share

Everything here is already set up — `game/export_presets.cfg` is committed, so
your editor will show the presets as soon as you pull. The only thing that is
not in the repo is the export templates, which are a ~1.3 GB download and have
to be installed once per Godot version.

## One-time: install the export templates

In the Godot editor: **Editor → Manage Export Templates… → Download and
Install**. It must say `4.7.2.stable` when it finishes; a mismatched version
is the usual cause of "No export template found at the expected path".

## The quick way (one command)

From the repo root:

```powershell
.\tools\package.ps1
```

It finds Godot itself — first on your PATH, then under `Program Files`,
`%LOCALAPPDATA%\Programs`, `Downloads`, `Desktop`, `Documents` and `C:\Godot`,
preferring a 4.7.2 build and warning if all it can find is another version. The
Windows download is a bare `.exe` you unzip wherever, so it is normal for it not
to be on the PATH. If yours lives somewhere else, say so:

```powershell
.\tools\package.ps1 -Godot "C:\Godot\Godot_v4.7.2-stable_win64.exe"
```

That exports the Windows build, copies `dist\README.txt` and
`dist\CREDITS.txt` in beside it, and writes
`build\Cygnet-windows-<date>-<commit>.zip`. Send that one file.

`-Target linux`, `-Target web` and `-Target all` do the other presets.
On Mac or Linux the same thing is `tools/package.sh windows`.

## The manual way (through the editor)

1. **Project → Export…**
2. Pick **Windows**, check the export path, press **Export Project…**
3. Leave **Export With Debug** unticked — a debug build prints to a console
   window and runs slower.
4. Copy `dist/README.txt` and `dist/CREDITS.txt` next to the `.exe` and zip
   the folder.

## What the presets do

| Preset | Output | Notes |
|---|---|---|
| Windows | one `Cygnet.exe`, ~146 MB, ~72 MB zipped | PCK embedded, so there is no loose `.pck` to lose |
| Linux | one `Cygnet.x86_64` | recipient needs `chmod +x` |
| Web | `build/web/` | see the caveat below |

All three exclude `tests/*` (the smoke tests and screenshot tours) and the
`.md` files, so only the game ships.

## Sending it

72 MB is past what email will take. A Drive/Dropbox link or WeTransfer is the
path of least resistance. Windows SmartScreen will warn that the publisher is
unknown, because the build is not code-signed — `README.txt` tells the player
to click **More info → Run anyway**, but it is worth saying in your message
too, because an unexplained SmartScreen box is where playtesters give up.

The web build is the one that needs no explaining — but it cannot be opened
from a local file or a plain static host: Godot 4 needs `Cross-Origin-Opener-
Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers.
itch.io sets them for you and is the usual answer; GitHub Pages does not.

## Before it goes anywhere public

`dist/CREDITS.txt` ships with the build and carries the CC BY 4.0 attribution
lines the character models require, so private playtesting is covered.

Four Freesound sounds (both piano layers, the quacks, the squeaks) still have
**unconfirmed licences** — see the note in `game/assets/audio/CREDITS.md`. Any
of them could turn out to be CC BY-NC, which cannot be used in a game that is
sold. Until each one is checked on its Freesound page, keep the build to
private playtesting: no storefront, no public download page.

There is also no in-game credits screen yet. One is required before release,
not just the text file in the zip.
