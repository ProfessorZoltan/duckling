# Cygnet — Godot project

Prototypes **P1 — Duckling** (grey-box pond: waddle, paddle, hop), **P2 — Growth** (Growth Spurt cutscene and size gates), **P3 — Heart** (the pond drains to gray when the siblings leave and recolors as you befriend Nib), and **P4 — Flight** (cliff test course: flap, glide, dive, thermals, rings). Built for **Godot 4.7.2** (the project's feature tag is 4.7; 4.7.x or newer opens it directly).

## Run it

1. Open Godot 4.7.2, click **Import**, and pick `game/project.godot`.
2. Press **F5**. You spawn on the shore next to the nest and your siblings. Eat five water bugs to trigger the first Growth Spurt, or press **G** to force one. Watch the siblings leave, then push through the reeds to the east, talk to Nib with **E**, and bring back eight seeds. Press **F2** to jump to the cliff flight course, **F1** to come back.

The window opens at 1280×720 and the UI scales with it (design resolution 1600×900), so it fits laptop screens and high-DPI displays. Resize or maximise freely.

## Controls

| Action | Keyboard / Mouse | Gamepad |
|---|---|---|
| Move | WASD | Left stick |
| Camera | Mouse | Right stick |
| Hop, and in the air: flap | Space | A / Cross |
| Glide (from a hop, Juvenile+) | Hold Space past the apex | Hold A |
| Pull up / dive (flying) | W / S | Left stick up / down |
| Turn (flying) | A / D | Left stick left / right |
| Talk, advance dialogue | E / Left click | X / Square |
| Release / recapture mouse | Esc / click | Start |
| Debug: growth spurt cutscene | G | — |
| Debug: growth stage down / up (instant) | `[` / `]` | — |
| Debug: pond / cliff scene | F1 / F2 | — |

## Layout

| Path | What it is |
|---|---|
| `autoload/globals.gd` | `Globals` singleton: growth `stage`, `player_scale`, `heart`, and their change signals. Everything scale-related listens to `player_scale_changed`. `request_growth_spurt()` asks the scene's director to play the cutscene; `notify()` sends a HUD message. |
| `player/player.tscn` | The duck: `CharacterBody3D` root, primitive-mesh body under `Body`, and the camera rig under `CameraPivot`. |
| `player/player.gd` | Walk / Swim / Air / Fly state machine. Wobble walk (input smoothing plus body roll), buoyant swimming with a spring-damper, hop from ground or water. Flight is an energy model: nose down trades height for speed, nose up trades it back, a flap adds a decaying burst of lift and costs stamina, hands-off settles into a sinking glide. Water is always a safe landing; ground only below `landing_speed`, otherwise you bounce. Scales everything from `Globals.player_scale`. |
| `player/third_person_camera.gd` | Orbit camera on a `SpringArm3D`. Arm length and pivot height scale with the player, which is what makes the world feel like it shrinks. In flight it drifts in behind the heading when you aren't steering it and pulls back with speed. |
| `world/pond_greybox.tscn` | Home Pond grey-box. Everything that should shrink during a Growth Spurt lives under the `World` node: terrain, water, props, siblings, gates, bugs. The player, sun and sky sit outside it. East: a reed wall you can push through once you're a Duckling, hiding two bonus bugs. West: a culvert only a Hatchling fits through, with a sibling already on the far side. The `Environment` has `adjustment_saturation` enabled so P3 can drive it from `Heart`. |
| `world/pond_greybox.gd` | Stand-ins for the Act 1–3 beats: five bugs trigger Growth Spurt 1; after it the siblings walk a path through the culvert and the region drops to Heart 10; meeting Nib gives +25; eight seeds for Nib's Pantry restore 100. |
| `world/heart_region.gd` | One region's Heart sub-value made visible: every material under its `visuals_root` desaturates toward gray as the value falls and recovers as it rises, blending over 3 s. |
| `world/heart_environment.gd` | On the `WorldEnvironment`: drives post-process saturation, sky colors, sun color and ambient energy from the global Heart. |
| `world/npc.gd`, `world/nib.tscn` | Talkable animal: prompt when near, `E` opens a dialogue of short subtitle lines, `first_talk` signal for quest hooks. Nib is a field mouse in the reed pocket. |
| `world/pickup.gd`, `world/water_bug.tscn`, `world/seed.tscn` | Collectibles with a `kind`. Scenes count them by group. |
| `world/growth_spurt_director.gd` | The Growth Spurt cutscene: freezes the player, tweens `World` down around the player's feet for 2.5 s with a flash and a body puff, then snaps the world back to 1.0 and bumps the stage in the same frame. The swap is invisible because camera boom and player scale both key off PlayerScale. |
| `world/size_gate.gd` | `StaticBody3D` whose collision only exists while the player is outside `[min_scale, max_scale]`. A scale check, not a physical fit (doc §7.2), so the visual opening must be sized to match: the blocked stage must visibly not fit, and the blocker sits at the mouth, never deep inside. Shows a hint and wobbles its reeds when bumped; parts the reeds when it opens. |
| `world/water_bug.tscn` | Collectible snack. Bobs, spins, vanishes on touch. |
| `world/duckling_prop.tscn` | Static yellow sibling, for scale reference. |
| `world/water_volume.gd` | `Area3D` whose origin marks the water surface. Tells the player when it enters or leaves water. |
| `world/cliff_test.tscn` | P4 flight course: a 60 m plateau, a lake to land in, floating ledges to practice landings, pillars to weave through, two thermals, and eight rings. Forces the Fledgling stage on load. |
| `world/cliff_test.gd` | Course script: counts rings, times the run, can reset. |
| `world/thermal.gd` | `Area3D` column that gives a flying player free lift. |
| `world/flight_ring.tscn` | Ring target: `Area3D` plus a torus that turns green when a flying player passes through. |
| `ui/debug_hud.gd` | On-screen state, stage, Heart per region, stamina, quest counters, notice line, interaction prompt, and the dialogue box. Handles the debug keys. Trim before shipping; the dialogue box stays. |
| `tests/smoke_test.tscn` | Headless check that walks the duck into the pond, hops, grows, and reaches the far shore. |
| `tests/flight_smoke_test.tscn` | Headless check that walks off the cliff, glides through ring 1, dives, pulls up, flaps, and dives into the lake. |
| `tests/growth_smoke_test.tscn` | Headless check that bumps the closed reed gate, plays a Growth Spurt, verifies the world shrank to 0.8 and snapped back, then walks through the open gate and eats a bug. |
| `tests/heart_smoke_test.tscn` | Headless check that grows to Duckling, watches the siblings leave and the grass go gray, talks to Nib through four lines, collects eight seeds, and confirms the grass color is restored exactly. |
| `tests/screenshot_tour.tscn`, `tests/flight_screenshot_tour.tscn`, `tests/growth_screenshot_tour.tscn`, `tests/gate_screenshot_tour.tscn`, `tests/heart_screenshot_tour.tscn` | Drive the duck through the pond, the cliff course, a Growth Spurt, both size gates at both sizes, or the whole Heart arc, and save PNGs for sharing progress without a GPU (see below). Use the gate tour to eyeball any new gate's ratios. |

## Smoke test

```
cd game
godot --headless --path . tests/smoke_test.tscn
godot --headless --path . tests/flight_smoke_test.tscn
godot --headless --path . tests/growth_smoke_test.tscn
godot --headless --path . tests/heart_smoke_test.tscn
```

Exit code 0 means every check passed. Run all four after touching the player, water, scale, growth, heart, or flight code.

## Screenshots without a GPU

```
cd game
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
  godot --path . --rendering-driver opengl3 --resolution 1600x900 \
  tests/screenshot_tour.tscn -- --out=/path/to/output
```

## Tuning knobs

All feel values are exported on the `Player` node and the `CameraPivot` node, so they can be tweaked live in the editor while the game runs. Start with `input_smoothing`, `wobble_roll_degrees`, `walk_speed`, and the camera's `base_arm_length`. For flight, the ones that change the feel most are `glide_sink_degrees` (glide ratio), `flap_lift`, `flap_cost`, `air_drag`, and `landing_speed`.

## What the prototypes do not do yet

- No tumble when bumping into things (doc §7.1). The state machine has room for it.
- No run, and no underwater dive. Those are Stage 3 abilities for P3-era work.
- No wind. Thermals exist; regional wind (§7.4) was deferred per the doc's solo-dev plan.
- Only the first Growth Spurt has a trigger (five bugs). Later spurts are story beats that don't exist yet; use G.
- One region only. The doc's per-region coloring is built (each `HeartRegion` tints its own subtree) but the pond is the only region so far.
- No music layers. The doc ties the Heart to instrument count; audio is out of scope until there is audio.
- Water is a flat tinted plane. A noise-driven normal map shader can replace it later without touching gameplay.
