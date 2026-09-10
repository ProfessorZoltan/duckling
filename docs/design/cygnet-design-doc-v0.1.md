# Working Title: *Cygnet* — Design Document v0.1

Alternate titles to consider: *Odd Duck*, *The Wrong Duckling*, *Downy*, *Still Water*.

---

## 1. Core Concept

A cozy 3D exploration game where you raise a "duckling" from egg to adulthood. The secret twist: you were a swan all along. The world literally shrinks as you grow, and it loses and regains its color as you lose and rebuild your sense of belonging.

**Design pillars**
1. **Growing up feels physical.** Every growth stage changes what you can reach, how fast you move, and how big the world feels.
2. **Belonging is earned, not given.** Family rejects you; friends you *find* restore you. Color is the meter.
3. **Flight is the reward.** Everything before flight is preparation; flight recontextualizes the whole map.
4. **No fail states, low stress.** Hazards push you back, never kill you.

**Comparable games:** A Short Hike (flight, tone), Untitled Goose Game (bird control feel), Journey (wordless emotional arc), Lil Gator Game (cozy 3D exploration).

---

## 2. Narrative Outline

### Prologue — The Egg (5 min)
- First-person, inside the egg. Muffled sounds: mother's voice, siblings' peeping, rain on the nest.
- Player taps/pecks at the shell (mash a button or click cracks). Light bleeds in with each crack.
- Shell breaks → camera pulls out to third person. You are noticeably larger and greyer than your siblings, but nobody comments yet.

### Act 1 — The Nest (30–45 min)
- Learn wobble-walk, paddle-swim, peep/call.
- Follow Mother and four siblings around Home Pond. They are always just slightly too fast (tension without punishment).
- Siblings' dialogue is dismissive; Mother is distracted, not cruel.
- Small tasks: find food, hide from the hawk shadow, get back to the nest by dusk.
- Ends with the first **Growth Spurt** (world shrinks ~20%).

### Act 2 — Left Behind (20–30 min)
- Family moves to the far side of the pond. You struggle to keep up; reeds and logs that were walls are now passable, but they're still faster.
- Confrontation: siblings tell you plainly you don't belong. Mother doesn't intervene.
- Scripted moment: they swim through a culvert you can't fit in. They're gone.
- **World desaturates** to near-grayscale. Music drops to a single instrument.

### Act 3 — The Wide Water (2–3 hrs, the bulk of the game)
- Open exploration. Every new friend and completed quest restores color to their region.
- Mentors teach abilities: diving, hopping, gliding.
- The player is the "ugly" gawky juvenile through this act — NPCs comment on it kindly, or don't care.
- Two more Growth Spurts open the Creek and the Forest.
- Climax: the Crow (or Geese) get you to a high cliff and dare you to jump. First flight.

### Act 4 — Sky (1–2 hrs)
- Flight unlocks the full map. Rivers you paddled are now shortcuts you cross in seconds.
- Flight-based quests: help the geese, race the kingfisher, carry things.
- Rumor of "the big white birds on the Great Lake."

### Act 5 — The Great Lake (30–45 min)
- Arrive at the Great Lake. See your reflection for the first time in still water: **white plumage**. The reveal.
- Meet the swan flock; nobody is surprised — they knew what you were.
- Choose a mate through a courtship "dance" minigame (mirrored movement, like the real swan neck-heart pose).
- **Optional epilogue:** fly back over Home Pond. The ducks are tiny now. You can call to them or fly past. Either choice is valid.
- Full color, full orchestra. Credits.

---

## 3. Growth Stages & World Scale

The world "shrinks" is the fantasy; mechanically it's easier to **scale the player, camera distance, and speed** while leaving the world fixed. Physics, navmeshes, and water planes stay stable, and the visual effect is identical. Reserve a real world-root scale tween for the Growth Spurt cutscenes so the player *sees* the world shrink for 2–3 seconds.

| Stage | Rough age | Player scale | Effective world feel | Abilities gained |
|---|---|---|---|---|
| 0. Egg | — | — | — | Crack shell (1st person) |
| 1. Hatchling | Days 1–7 | 1.0× | Huge; reeds are forests | Wobble walk, paddle, peep |
| 2. Duckling | Weeks 2–5 | 1.25× | Still big; can cross shallow logs | Steady walk, dabble (head underwater), hop |
| 3. Gawky Juvenile | Weeks 6–12 | 1.7× | Medium; culverts and gaps open | Run, dive, flap-hop (short glide from height) |
| 4. Fledgling | Months 4–6 | 2.3× | Small; most water is crossable | Flight (limited stamina) |
| 5. Young Swan | Months 7–12 | 3.0× | Small; map is contiguous | Full flight, thermals, carry items |
| 6. Adult Swan | Year 2 | 3.5× | Tiny | Courtship dance, white plumage (visual only) |

Growth Spurts are triggered by story beats, not timers, so the player never feels rushed.

---

## 4. World Map (Regions)

Roughly a single large valley, ~1.5 km across at full scale. Regions unlock by growth stage, not by gates.

| Region | Unlocks at | Mood/Color | Key features |
|---|---|---|---|
| Home Pond | Stage 1 | Warm greens/golds → gray after Act 2 | Nest, reeds, lily pads, culvert |
| Reed Marsh | Stage 2 | Muted blue-green | Maze of reeds, frog chorus, Heron's shallows |
| The Creek | Stage 3 | Cool blues | Fast current (swim-against challenge), beaver dam, Otter's slide |
| Old Forest | Stage 3 | Deep green, dappled | Fox hazard, Owl's hollow, mushrooms, a fallen tree that's a bridge |
| Farm Meadow | Stage 3 | Yellow/tan | Barn, hay bales, Bo the dog, Cat hazard, human ambient (never seen up close) |
| Stony Cliffs | Stage 3 (reachable), 4 (usable) | Gray/violet | Crow's roost, first-flight ledge, thermals |
| Upper Sky | Stage 4 | Bright blue | Thermals, geese flight paths, cloud islands (cosmetic) |
| The Great Lake | Stage 4/5 | Silver, then full color | Swan flock, still-water reflection, finale |

---

## 5. NPC List

Every named NPC has a **home region**, a **role**, and a **Heart value** (how much color they restore when their arc completes).

### Family (Act 1–2)
| Name | Species | Role | Notes |
|---|---|---|---|
| Marra | Mallard hen | Mother | Distracted, never cruel. Leaves without a goodbye. |
| Pip | Duckling | Sibling, ringleader | Says the meanest line. |
| Dab | Duckling | Sibling | Follows Pip. |
| Quill | Duckling | Sibling | Quietly uncomfortable; the one who almost looks back. |
| Sedge | Duckling | Sibling, youngest | Mimics the others. |

### Mentors (teach abilities)
| Name | Species | Region | Teaches | Personality |
|---|---|---|---|---|
| Old Stillwater | Great blue heron | Reed Marsh | Patience; dabble/dive | Speaks slowly, in long pauses. First adult who says "you're not a duck" without saying what you are. |
| Mossback | Snapping turtle (retired from snapping) | Reed Marsh | Diving, holding breath | Grumpy, warm underneath. |
| Rill | River otter | The Creek | Fast swimming, current riding | Hyperactive, treats you like a little sibling — the good kind. |
| Ash | Crow | Stony Cliffs | Flap-hop, then first flight | Trickster, dares you into things, secretly protective. |
| Hollis | Barn owl | Old Forest | Night navigation, listening | Only awake at night. Cryptic. |
| The V | Canada geese (flock, leader "Sergeant Honk") | Upper Sky | Formation flight, long-distance stamina | Loud, blunt, fair. |

### Friends (Heart restorers)
| Name | Species | Region | Arc summary |
|---|---|---|---|
| Nib | Field mouse | Home Pond edge | Your first friend after abandonment. Tiny, doesn't care what you look like. Lives in the reeds you used to be afraid of. |
| The Chorus | Frogs (5) | Reed Marsh | Rhythm minigame; they need a bass voice. Your honk is it. |
| Tamsin | Beaver | The Creek | Building a dam; you fetch sticks she can't reach. |
| Zip | Dragonfly | Reed Marsh / Creek | Races. Impossible until you can fly; then rematch. |
| Bo | Farm dog | Farm Meadow | Big, gentle, lonely. Fetch quests. Warns you about the cat. |
| Flick | Kingfisher | The Creek | Dive competitions; later, aerial dive races. |
| Wren | Wren | Old Forest | Lost her nest's location after a storm; you help find it from above. |
| The Elder | Old mute swan | Great Lake | Explains, gently, what you are. |
| Lumen | Young swan | Great Lake | Mate candidate. (Consider 2–3 candidates with different personalities.) |

### Hazards (non-lethal)
| Name | Species | Region | Behavior |
|---|---|---|---|
| The Shadow | Hawk (never fully seen until Act 4) | Everywhere early | Shadow passes overhead; hide under cover or get knocked into water. |
| Vesper | Fox | Old Forest | Patrols; if caught, you're carried back to the forest edge. |
| Marmalade | Barn cat | Farm Meadow | Stalks; same knockback behavior. Later, when you're huge, she's afraid of *you*. |
| Current | (environmental) | The Creek | Pushes you downstream until you learn current riding. |

---

## 6. Quest List

### Main Quests
| # | Act | Quest | Goal | Reward |
|---|---|---|---|---|
| M1 | 0 | Crack the Shell | Break out of the egg | Third-person view |
| M2 | 1 | Keep Up | Follow the family around Home Pond | Walk/swim tutorial |
| M3 | 1 | First Supper | Find 5 water bugs before dusk | Dabble |
| M4 | 1 | The Shadow | Hide from the hawk 3 times | Growth Spurt 1 |
| M5 | 2 | The Far Shore | Follow the family across the pond | — |
| M6 | 2 | The Culvert | Scripted: family leaves | World desaturates |
| M7 | 3 | A Small Voice | Meet Nib in the reeds | First color returns |
| M8 | 3 | Stillwater's Lesson | Complete the Heron's patience trial | Dive |
| M9 | 3 | Against the Current | Reach the top of the Creek with Rill | Current riding, Growth Spurt 2 |
| M10 | 3 | The Fallen Tree | Cross into Old Forest; survive Vesper | Run |
| M11 | 3 | Ash's Dare | Flap-hop from progressively higher rocks | Flap-hop, Growth Spurt 3 |
| M12 | 3→4 | The Ledge | First flight from Stony Cliffs | Flight |
| M13 | 4 | Fly With Us | Join the geese formation for one migration leg | Stamina upgrade, Great Lake revealed |
| M14 | 5 | Still Water | See your reflection at the Great Lake | Plumage reveal |
| M15 | 5 | The Dance | Courtship minigame | Ending |
| M16 | 5 (opt.) | Home Pond, From Above | Fly back over the start | Alternate credits |

### Side Quests (by region)
| Region | Quest | Giver | Summary | Reward |
|---|---|---|---|---|
| Home Pond | Nib's Pantry | Nib | Collect 8 seeds scattered in reeds | Heart +, seed cosmetic |
| Reed Marsh | Bass Note | The Chorus | Rhythm game, 3 songs | Heart +, "Song" collectible |
| Reed Marsh | Mossback's Nap | Mossback | Find him a sunnier log (push/nudge puzzle) | Breath upgrade |
| Reed Marsh | Zip's Race (I) | Zip | Race on water — designed to be lost | Sets up rematch |
| The Creek | Stick by Stick | Tamsin | Fetch 6 sticks from increasingly hard spots | Heart +, dam becomes a shortcut |
| The Creek | Otter Slide | Rill | Time trial down the mud slide | Speed upgrade |
| The Creek | Flick's Plunge (I) | Flick | Dive for 5 minnows in 30s | Dive upgrade |
| Old Forest | Owl Hours | Hollis | Three night-time navigation tasks by sound | Night vision (subtle) |
| Old Forest | Mushroom Ring | (found) | Find 12 glowing mushrooms | Cosmetic feather color |
| Farm Meadow | Bo's Ball | Bo | Fetch his ball from the cat's territory | Heart +, Bo escorts you past Marmalade |
| Farm Meadow | Bread Day | (ambient) | Humans throw bread; compete with ducks for it | Nostalgic callback to family |
| Stony Cliffs | Ash's Shinies | Ash | Collect 10 shiny objects (bottle caps, foil) | Heart +, Ash teaches a flight trick |
| Upper Sky | Zip's Race (II) | Zip | Aerial rematch | Heart +, closes Zip's arc |
| Upper Sky | Flick's Plunge (II) | Flick | Dive from altitude into the Creek | Dive-bomb ability |
| Upper Sky | Wren's Nest | Wren | Find her nest from above using landmarks | Heart + |
| Upper Sky | Thermal Hunt | The V | Find and ride 5 thermals | Stamina upgrade |
| Great Lake | Feather Count | The Elder | Return 6 lost feathers to the flock | Unlocks epilogue |

### Collectibles
- **Songs** (8): short melodies learned from animals; each adds a layer to the world music.
- **Feathers**: cosmetic plumage tints, most visible only after the white reveal.
- **Memories**: 10 spots that trigger a short memory of the family — the game's way of letting the player process the abandonment.

---

## 7. Core Mechanics

### 7.1 Movement (ground / water)
- **Wobble walk (Stage 1–2):** input is intentionally laggy with a slight procedural sway. Bump into things and you tumble (harmless, cute).
- **Run (Stage 3+):** hold sprint; stamina shared with flight later.
- **Swim:** auto-transitions when entering water. Slower than walking early, faster later.
- **Dabble / Dive:** hold Action while swimming to tip forward (dabble); press again to fully submerge. Breath meter.
- **Hop / Flap-hop:** jump; from Stage 3, holding jump at the apex gives a short glide.
- **Current riding:** tilt into the current to surf; fight it and you lose speed.

### 7.2 World Scale / Growth
- `PlayerScale` global drives: model scale, camera boom distance, move speed, jump height, collision capsule.
- Growth Spurt cutscene: freeze input, tween world-root scale down ~0.8 over 2.5s while camera pulls back, then swap to fixed values. Optional: siblings/NPCs visibly shrink relative to you.
- Doorways/gaps use simple size checks (`if PlayerScale >= threshold`) rather than physical fit, to avoid physics jank.

### 7.3 Mood / Color System
- `Heart` value 0–100. Starts ~70, drops to ~10 after the Culvert, recovers via quests and friendships.
- Drives a **post-process blend**: saturation, a warm↔cold color-grading LUT, sky color, ambient light temperature, and music layer count.
- Regional override: each region has its own Heart sub-value, so finishing the Creek colors the Creek first. Global average sets the sky.
- Never *reduce* color after Act 2 — recovery is monotonic. No punishment mechanics.

### 7.4 Flight (A Short Hike model, extended)
- **Flap:** press to gain height, costs stamina.
- **Glide:** release to glide; free. Glide ratio improves with stage.
- **Dive:** tilt down to trade height for speed; pull up to convert speed back to height (energy conservation feel).
- **Thermals:** visible shimmer columns; circle inside them to gain height for free.
- **Wind:** regional wind direction shown with particles; headwinds drain, tailwinds push.
- **Landing:** water is always safe. Branches/ledges require slowing below a threshold or you bounce off.
- **Stamina:** upgrades from geese quests and Growth Spurts. At Stage 5 it's generous enough to cross the whole map.
- **Camera:** free-look on right stick with soft auto-follow behind the player; pull back further as speed increases.

### 7.5 Dialogue
- Short, wordless-adjacent: animal sounds with brief subtitle text. Keep lines under 12 words.
- No dialogue trees needed; a few yes/no choices (call to the ducks or fly past).

---

## 8. Controls

Context-sensitive **Action** button handles peep/call, dabble, talk, pick up.

| Action | Keyboard / Mouse | Gamepad |
|---|---|---|
| Move | WASD | Left stick |
| Camera | Mouse | Right stick |
| Jump / Flap | Space | A / Cross |
| Action (call, dabble, talk, grab) | E or Left click | X / Square |
| Run / Dive (in water) | Shift | B / Circle |
| Glide | Hold Space (airborne) | Hold A |
| Dive (flight) | S / push mouse down | Left stick down |
| Look at self / photo mode | R | Y / Triangle |
| Map (Stage 4+) | M | Back / Select |
| Pause | Esc | Start |

**Feel targets**
- Egg cracking: mash any button; each press plays a crack sound with light haptics.
- Wobble walk: 0.15s input smoothing plus a 2–3° procedural body roll.
- Flight: 200ms from flap press to lift so it never feels laggy; glide should feel like *floating*, not falling.

---

## 9. Engine Recommendation

**Recommendation: Godot 4.x**, unless you already know C# and Unity well.

Rationale: this is a stylized low-poly 3D game, exactly the tier Godot handles comfortably. It's free with no revenue share, has a Python-like scripting language that's fast to learn, and its 3D side has improved substantially through the 4.x series. Unity's advantages (asset store depth, console export, high-fidelity rendering) matter less for a cozy indie title, and its licensing is the one thing you'd have to keep an eye on.

| Factor | Godot 4.x | Unity | Source |
|---|---|---|---|
| Cost | Free, MIT license, no royalties or seat fees | Free under $200K/yr revenue; Pro ~$2,300/yr per seat above that | godotlearning.com; ziva.sh |
| 3D capability | Viable for most indie 3D; Vulkan renderer, Jolt physics added in 4.6 | Stronger for realistic lighting, large terrain, and console targets | ziva.sh; dev.to |
| Learning curve | GDScript is lighter than C#; C# also supported | More tutorials overall, larger asset ecosystem | dev.to; itch.io |
| Console export | Third-party support only | Official | oceanviewgames.co.uk |
| Adoption trend | Roughly doubled Steam releases year over year; ~40% of GMTK jam entries | Still dominant in commercial studios | ziva.sh |

**Also consider:** Unity if you want to lean on Asset Store water/foliage/character-controller packages to skip building systems. Unreal is overkill for this scope.

**Godot-specific building blocks**
- `CharacterBody3D` for the duckling; write a state machine (Walk / Swim / Dive / Hop / Glide / Fly).
- `WorldEnvironment` + a custom shader or `ColorCorrection` LUT for the Heart system.
- Terrain: Terrain3D addon; water: a simple plane shader with a `noise`-driven normal map is enough for the style.
- Dialogue: Dialogic addon or a hand-rolled JSON system (lines are short enough to hand-roll).
- Save system: a single JSON with `stage`, `heart`, region sub-hearts, quest flags, collectibles.

---

## 10. Art & Audio Direction

- **Art:** low-poly, soft shading, no hard outlines. Everything slightly rounded. The duckling is grey-brown and lanky; siblings are compact and yellow. Color grading does the emotional heavy lifting, so keep base textures simple.
- **Audio:** layered adaptive score; one instrument at Heart 10, full ensemble at 100. Each Song collectible adds a real layer. Animal voices are pitched instrument phrases, not recorded speech.

---

## 11. Prototype Milestones

| Milestone | Scope | Done when |
|---|---|---|
| P1 — Duckling | Grey-box pond, walk/swim/hop, camera | It's fun to just waddle around for 5 minutes |
| P2 — Growth | PlayerScale system, one Growth Spurt cutscene, size-gated gap | The shrink moment gives a visible "oh" |
| P3 — Heart | Post-process blend, one region with sub-heart, one friend quest | Finishing the quest visibly recolors the area |
| P4 — Flight | Flap/glide/dive/thermal on a cliff test map | You can lose 10 minutes just flying |
| P5 — Vertical slice | Prologue → Act 2 → first friend (Nib), with real art in Home Pond | Playtesters feel the abandonment and the first color returning |

Build P4 early, even before P3. If flight isn't fun, the whole back half of the game fails.

---

## 12. Decisions (Sept 2026)

- **Team:** solo, limited coding background.
- **Platform:** PC only (Steam / itch.io).
- **Engine:** Godot 4.x with GDScript. Decided.
- **Length target:** 2–3 hours. Cut, don't add.

## 13. Solo-Dev Scope Plan

The doc above is the *full* vision. Build this smaller version first; it's a complete game on its own.

### What to cut from v1
| Cut | Why | Bring back if… |
|---|---|---|
| Farm Meadow region (Bo, Marmalade, Bread Day) | Fourth biome; humans and a dog are extra rigs and animations | v1 ships and you want a content update |
| Old Forest night mechanics (Hollis, Owl Hours) | Day/night cycle is a whole system | Same |
| Multiple mate candidates | One is enough for the emotional beat | Never, probably |
| Songs collectible with adaptive music layers | Adaptive audio is fiddly; use a simple 3-state music switch (gray / recovering / full) | You get an audio collaborator |
| Zip and Flick "II" rematches, Thermal Hunt | Flight side content can be one quest, not four | Flight prototype turns out to be very fun |
| Memories collectible | Nice but optional | Late polish |

### v1 content
- **Regions:** Home Pond, Reed Marsh, The Creek, Stony Cliffs, Great Lake. (Forest becomes a small scenic strip between Creek and Cliffs.)
- **NPCs:** Marra + 4 siblings, Nib, Old Stillwater, Rill, Tamsin, Ash, The V (as a single scripted flight), The Elder, Lumen. Twelve characters, of which five are one duckling model recolored.
- **Main quests:** M1–M15 as written. **Side quests:** Nib's Pantry, Bass Note (simplified to a call-and-response, no rhythm engine), Stick by Stick, Otter Slide, Ash's Shinies.

### Ordered learning path (first ~10 weeks)
1. **Weeks 1–2:** Godot's official "Your first 3D game" tutorial, then Brackeys' Godot 4 beginner series. Don't touch your game yet.
2. **Weeks 3–4:** P1 — a `CharacterBody3D` duck on a grey-box pond. Walk, swim (an `Area3D` water volume toggles swim state), hop, third-person camera. Use a capsule for the duck; no art.
3. **Weeks 5–6:** P4 — flight prototype on a separate test scene. Flap/glide/dive only. Skip thermals and wind for now.
4. **Week 7:** P2 — `PlayerScale` global and one growth tween. Confirm camera and speed scale nicely.
5. **Week 8:** P3 — `WorldEnvironment` saturation lerp driven by a `Heart` variable. One region, one variable.
6. **Weeks 9–10:** Egg prologue (first-person camera, click-to-crack) and the Culvert scripted sequence. If these two moments land with a friend playing, keep going.

### Assets without an artist
- Kenney.nl (CC0 low-poly nature packs) for trees, rocks, reeds.
- Quaternius (CC0 animated low-poly animals) — has ducks, birds, and a fox.
- Model the duckling yourself in Blender only after the prototypes work; a primitive-shape duck is fine for months.
- Audio: freesound.org (CC0 filters), and a single royalty-free piano track for the gray section.

### Rules for staying finished
- No new systems after week 10. Everything after that is content and polish.
- If a feature needs a tutorial you can't find, cut it.
- Playtest every two weeks with one person who hasn't seen it.
