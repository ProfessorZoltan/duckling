# Duckling (working title Cygnet) — project conventions

Godot 4.7.2, GDScript. Design doc: `docs/design/cygnet-design-doc-v0.1.md`. Game project: `game/`.

## Rules that came from playtesting

- **Size gates must match what the eye sees.** A `SizeGate` is a scale check, not a physical fit, so the visual opening must be sized so the blocked stage visibly does not fit and the allowed stage visibly does. Player heights at scale 1.0: head top ≈ 0.67 m, body width ≈ 0.44 m. Multiply by `Globals.STAGE_SCALE` for each stage (Duckling 1.25 → 0.84 m tall). Give the physical collision a little more room than the visual so the allowed stage never snags. When a gate opens, change the visual too (reeds part, etc.), never just the collision.
- **Flight is fun as tuned.** Don't retune `glide_sink_degrees`, `flap_lift`, `flap_cost`, `air_drag`, or `landing_speed` without the user asking.

## Structural rules

- Everything that should shrink in a Growth Spurt lives under a scene's `World` node. Player, lights and sky stay outside it.
- All scale-dependent values key off `Globals.player_scale` via `player_scale_changed`. Never hard-code a stage's size.
- Story beats call `Globals.request_growth_spurt()`; never timers.
- Commit `.uid` sidecar files for every new script so the user's editor never has to generate its own.
- `project.godot` and `*.import` get rewritten by the user's editor; that is expected noise, not a change to preserve.

## Verification before every push

Run from `game/` with a Godot 4.7.2 binary:

```
godot --headless --path . --import
godot --headless --path . tests/smoke_test.tscn
godot --headless --path . tests/flight_smoke_test.tscn
godot --headless --path . tests/growth_smoke_test.tscn
```

Screenshots without a GPU: `LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 --resolution 1600x900 tests/<tour>.tscn -- --out=<dir>`. Look at them before sharing; lighting and ratios only show up in pixels.
