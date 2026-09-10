# Duckling (codename)

Working title: **Cygnet**. A cozy 3D exploration game about raising a "duckling" from egg to adulthood, in which the world shrinks as you grow and regains its color as you find where you belong.

## Status

Pre-production. Engine decided: Godot 4.7.2 with GDScript. Solo developer, PC only (Steam / itch.io). Target length 2–3 hours.

## Documents

| Document | Purpose |
|---|---|
| [docs/design/cygnet-design-doc-v0.1.md](docs/design/cygnet-design-doc-v0.1.md) | Full design vision plus the v1 scope plan, prototype milestones, and 10-week learning path |

## Layout

- `docs/design/` — design documents, versioned by filename.
- `game/` — the Godot 4 project. See [game/README.md](game/README.md) for controls, layout, and the smoke tests.
- `game/assets/nature_kit/` — Stylized Nature MegaKit (standard, free version) by Quaternius, CC0. Trees, grass, rocks, flowers, pebbles.

## Screenshots (Home Pond with the Stylized Nature MegaKit, software-rendered)

| Spawn at the nest | Paddling as a hatchling | Same pond at juvenile scale |
|---|---|---|
| ![](docs/screenshots/p1_spawn_at_nest.png) | ![](docs/screenshots/p1_paddling.png) | ![](docs/screenshots/p1_juvenile_scale.png) |

## Screenshots (P5 vertical slice: the egg prologue)

| Inside the egg, seven pecks in | The pop | Hatched beside the siblings |
|---|---|---|
| ![](docs/screenshots/p5_inside_the_egg.png) | ![](docs/screenshots/p5_the_pop.png) | ![](docs/screenshots/p5_hatched.png) |

## Screenshots (P2 growth spurt)

| Hatchling by the nest | World shrinking mid-spurt | Duckling afterward |
|---|---|---|
| ![](docs/screenshots/p2_hatchling_by_the_nest.png) | ![](docs/screenshots/p2_world_shrinking.png) | ![](docs/screenshots/p2_duckling_after_spurt.png) |

## Screenshots (P3 heart)

| Heart 70 at the start | Heart 10 after the culvert | Meeting Nib | Heart 100 after Nib's Pantry |
|---|---|---|---|
| ![](docs/screenshots/p3_pond_heart_70.png) | ![](docs/screenshots/p3_pond_gone_gray.png) | ![](docs/screenshots/p3_meeting_nib.png) | ![](docs/screenshots/p3_pond_recolored.png) |

## Screenshots (P4 flight course)

| Gliding off the ledge | Dive | Pull-up |
|---|---|---|
| ![](docs/screenshots/p4_glide_off_the_ledge.png) | ![](docs/screenshots/p4_dive.png) | ![](docs/screenshots/p4_pull_up.png) |

## Progress

| Milestone | Status |
|---|---|
| P1 — Duckling (grey-box pond, walk / swim / hop, camera) | Skeleton in place; needs hands-on feel tuning |
| P2 — Growth | Growth Spurt cutscene (world shrinks around you), reed wall you grow into, culvert you grow out of, bug collection triggers spurt 1 |
| P3 — Heart | Region sub-hearts drive material saturation; global Heart drives sky, sun, post-process. Siblings leave through the culvert (Heart 10), meeting Nib and Nib's Pantry restore it to 100 |
| P4 — Flight | Cliff test course in place: flap, glide, dive, pull-up, thermals, ring course, water and ledge landings. Needs hands-on feel tuning |
| P5 — Vertical slice | Egg prologue done (first person, peck to crack, pull-out reveal). Act 1 family, hawk shadow, and playtest to come |
