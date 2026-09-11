# Duckling (working title Cygnet) — project conventions

Godot 4.7.2, GDScript. Design doc: `docs/design/cygnet-design-doc-v0.1.md`. Game project: `game/`.

## Rules that came from playtesting

- **Size gates must match what the eye sees.** A `SizeGate` is a scale check, not a physical fit, so the visual opening must be sized so the blocked stage visibly does not fit and the allowed stage visibly does. Player heights at scale 1.0: head top ≈ 0.67 m, body width ≈ 0.44 m. Multiply by `Globals.STAGE_SCALE` for each stage (Duckling 1.25 → 0.84 m tall). Give the physical collision a little more room than the visual so the allowed stage never snags. When a gate opens, change the visual too (reeds part, etc.), never just the collision.
- **Hazards never kill, and they never miss by accident.** The hawk aims its line at the player so hiding is the only thing that matters; being caught is a knockback into water, nothing more. Keep any new hazard on the same terms.
- **Marra waits.** The family is faster than the player but pauses at every waypoint until the player is close (or `max_wait`). Tension without punishment; never let the flock strand the player.
- **Quest counters count what you already had.** A beat that asks for N of something must credit what the player collected before the beat started (seeds found before meeting Nib, family greeted during Keep Up) and finish immediately if the quota is already met. Never reset a count to zero when a quest opens.
- **One talk target.** NPCs never read input themselves. They register with the player while in range; the player picks the nearest, the prompt names it, and E talks to exactly that one. Overlapping talk circles must never grab the key.
- **Flock members follow the real ground.** Height comes from a raycast under each member (waterline where the ground dips below it), never from waypoint heights. After a wait ends, the frame must return without stepping on the stale target or a waypoint gets skipped.
- **Losing color is slow, regaining it is quick.** `drain_time` 15 s, `recover_time` 3 s on both HeartRegion and HeartEnvironment. The drain will sit under the music dropping to one instrument.
- **Flight is fun as tuned.** Don't retune `glide_sink_degrees`, `flap_lift`, `flap_cost`, `air_drag`, or `landing_speed` without the user asking.

## Art assets

- `game/assets/nature_kit/` is the Stylized Nature MegaKit (Quaternius, CC0), glTF only. Instance the `.gltf` files directly as PackedScenes; never edit the imported resources.
- Kit models are at human scale with the base at y≈0 (trees and rocks sink 0.1–0.3 m; place them slightly below ground). Grass_Common_Tall is 1.9 m, CommonTree 7–9 m, Rock_Medium 2–3 m. `Plant_7` is a purple flower, not a lily pad.
- Textured materials cannot be tinted; `HeartRegion` swaps them for `HeartMaterial` shader copies. Anything textured that should lose color must be under `visuals_root`.
- Collision comes from a `StaticBody3D` wrapper (trees, boulders, lilies) or from an invisible CSG shape, never from the visual mesh. Ground clutter (grass, flowers, pebbles) has no collision.

## Models

- Characters are `AnimalModel` nodes (`world/animal_model.gd`), never hand-built primitives. Give it a species, a palette and a height in metres; it measures and scales itself.
- Never edit an imported material or mesh in place: every instance shares it. Recolour by duplicating the material onto a surface override, which is what `AnimalModel` does.
- Measure a model in its own space (`global_transform.affine_inverse()`), never world space, or a parent's scale corrupts the result. Skinned meshes report a bind-pose AABB, so walk the vertices through the skeleton.
- `AnimationPlayer.pause()` in 4.7 drops the animation and snaps the model to its bind pose. Hold a frame with `speed_scale = 0.0` instead.
- Everything in the game faces -Z. Models disagree, so every species needs a `FACING` entry in `AnimalModel`; without one a character steered by its heading walks backwards, which no still render will reveal.
- Model licences are CC BY 4.0: the credit lines in `assets/models/CREDITS.md` must reach a credits screen before release.

## Audio

- `game/assets/audio/CREDITS.md` records every source and its licence. Four Freesound sounds still have unconfirmed licences; anything new must be logged there before it is used, and CC BY-NC is unusable in a game that is sold.
- Music is two piano layers crossfaded on `Globals.heart` with the same `drain_time` / `recover_time` as the colour. Never fade them independently of the Heart.
- Sound effects go through `Audio.play` (flat) or `Audio.play_at` (positioned). Effects are mono so they can be spatialised; music is stereo Ogg with a three-second tail-to-head crossfade so it loops seamlessly.
- `Audio.played` is a signal for tests; assert on it rather than on a player's `playing` flag, which is unreliable under the headless dummy driver.

## Structural rules

- Everything that should shrink in a Growth Spurt lives under a scene's `World` node. Player, lights and sky stay outside it.
- All scale-dependent values key off `Globals.player_scale` via `player_scale_changed`. Never hard-code a stage's size.
- Story beats call `Globals.request_growth_spurt()`; never timers.
- Heart recovery is monotonic: quests call `Globals.add_region_heart()`. Only scripted story beats may call `set_region_heart()` to lower it.
- Anything that should lose and regain color must sit under the scene's `HeartRegion.visuals_root` (the `World` node in the pond).
- The game opens inside the egg. Any test or tour that loads the pond and expects to move must set `Globals.start_in_egg = false` before instantiating it.
- Nodes under `World` are ready before `Player`; a director that touches the player's `@onready` fields must `await player.ready` first.
- Tests that simulate a key an `_input`/`_unhandled_input` handler listens for must dispatch an `InputEventAction` via `Input.parse_input_event()`; `Input.action_press()` only sets polling state.
- Commit `.uid` sidecar files for every new script so the user's editor never has to generate its own.
- `project.godot` and `*.import` get rewritten by the user's editor; that is expected noise, not a change to preserve.

## Verification before every push

Run from `game/` with a Godot 4.7.2 binary:

```
godot --headless --path . --import
godot --headless --path . tests/smoke_test.tscn
godot --headless --path . tests/flight_smoke_test.tscn
godot --headless --path . tests/growth_smoke_test.tscn
godot --headless --path . tests/heart_smoke_test.tscn
godot --headless --path . tests/egg_smoke_test.tscn
godot --headless --path . tests/act1_smoke_test.tscn
godot --headless --path . tests/audio_smoke_test.tscn
```

Screenshots without a GPU: `LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 --resolution 1600x900 tests/<tour>.tscn -- --out=<dir>`. Look at them before sharing; lighting and ratios only show up in pixels.
