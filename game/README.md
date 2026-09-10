# Cygnet — Godot project

Prototype **P1 — Duckling**: a grey-box pond you can waddle, paddle, and hop around in. Built for **Godot 4.7.2** (the project's feature tag is 4.7; 4.7.x or newer opens it directly).

## Run it

1. Open Godot 4.7.2, click **Import**, and pick `game/project.godot`.
2. Press **F5**. You spawn on the shore next to the nest.

## Controls

| Action | Keyboard / Mouse | Gamepad |
|---|---|---|
| Move | WASD | Left stick |
| Camera | Mouse | Right stick |
| Hop | Space | A / Cross |
| Action (unused in P1) | E / Left click | X / Square |
| Release / recapture mouse | Esc / click | Start |
| Debug: growth stage down / up | `[` / `]` | — |

## Layout

| Path | What it is |
|---|---|
| `autoload/globals.gd` | `Globals` singleton: growth `stage`, `player_scale`, `heart`, and their change signals. Everything scale-related listens to `player_scale_changed`. |
| `player/player.tscn` | The duck: `CharacterBody3D` root, primitive-mesh body under `Body`, and the camera rig under `CameraPivot`. |
| `player/player.gd` | Walk / Swim / Air state machine. Wobble walk (input smoothing plus body roll), buoyant swimming with a spring-damper, hop from ground or water. Scales speeds, capsule, and model from `Globals.player_scale`. |
| `player/third_person_camera.gd` | Orbit camera on a `SpringArm3D`. Arm length and pivot height scale with the player, which is what makes the world feel like it shrinks. |
| `world/pond_greybox.tscn` | Home Pond grey-box: CSG ground with a spherical basin, transparent water plane, `WaterVolume`, reeds, logs, rocks, lily pads, nest, sun, sky. The `Environment` has `adjustment_saturation` enabled so P3 can drive it from `Heart`. |
| `world/water_volume.gd` | `Area3D` whose origin marks the water surface. Tells the player when it enters or leaves water. |
| `ui/debug_hud.gd` | On-screen state, stage, scale, heart, and speed. Handles the `[` `]` stage keys. Delete before shipping. |
| `tests/smoke_test.tscn` | Headless check that walks the duck into the pond, hops, grows, and reaches the far shore. |
| `tests/screenshot_tour.tscn` | Drives the duck through the pond and saves PNGs, for sharing progress without a GPU (see below). |

## Smoke test

```
cd game
godot --headless --path . tests/smoke_test.tscn
```

Exit code 0 means every check passed. Run it after touching the player, water, or scale code.

## Screenshots without a GPU

```
cd game
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
  godot --path . --rendering-driver opengl3 --resolution 1600x900 \
  tests/screenshot_tour.tscn -- --out=/path/to/output
```

## Tuning knobs

All feel values are exported on the `Player` node and the `CameraPivot` node, so they can be tweaked live in the editor while the game runs. Start with `input_smoothing`, `wobble_roll_degrees`, `walk_speed`, and the camera's `base_arm_length`.

## What P1 does not do yet

- No tumble when bumping into things (doc §7.1). The state machine has room for it.
- No run, dive, glide, or flight. Those are P4 (`flight`) and Stage 3+ abilities.
- No Growth Spurt cutscene: stages switch instantly. The world-root tween is P2.
- Water is a flat tinted plane. A noise-driven normal map shader can replace it later without touching gameplay.
