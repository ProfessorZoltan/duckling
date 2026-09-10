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
- `game/` — the Godot 4 project. See [game/README.md](game/README.md) for controls, layout, and the smoke test.

## Screenshots (P1 grey-box, software-rendered)

| Spawn at the nest | Paddling as a hatchling | Same pond at juvenile scale |
|---|---|---|
| ![](docs/screenshots/p1_spawn_at_nest.png) | ![](docs/screenshots/p1_paddling.png) | ![](docs/screenshots/p1_juvenile_scale.png) |

## Screenshots (P2 growth spurt)

| Hatchling by the nest | World shrinking mid-spurt | Duckling afterward |
|---|---|---|
| ![](docs/screenshots/p2_hatchling_by_the_nest.png) | ![](docs/screenshots/p2_world_shrinking.png) | ![](docs/screenshots/p2_duckling_after_spurt.png) |

## Screenshots (P4 flight course)

| Gliding off the ledge | Dive | Pull-up |
|---|---|---|
| ![](docs/screenshots/p4_glide_off_the_ledge.png) | ![](docs/screenshots/p4_dive.png) | ![](docs/screenshots/p4_pull_up.png) |

## Progress

| Milestone | Status |
|---|---|
| P1 — Duckling (grey-box pond, walk / swim / hop, camera) | Skeleton in place; needs hands-on feel tuning |
| P2 — Growth | Growth Spurt cutscene (world shrinks around you), reed wall you grow into, culvert you grow out of, bug collection triggers spurt 1 |
| P3 — Heart | `Heart` value exists; not wired to visuals |
| P4 — Flight | Cliff test course in place: flap, glide, dive, pull-up, thermals, ring course, water and ledge landings. Needs hands-on feel tuning |
| P5 — Vertical slice | Not started |
