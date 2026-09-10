extends Node3D
## Home Pond grey-box. Stand-ins for the doc's Act 1–3 beats until real
## quests exist:
##  - M3/M4: eat five water bugs -> Growth Spurt 1.
##  - M6 The Culvert: after the spurt the siblings leave through the culvert
##    and the pond drains to gray (Heart 10).
##  - M7 A Small Voice: meet Nib in the reeds -> first color returns.
##  - Nib's Pantry: bring back eight seeds -> the pond recolors fully.

const REGION := "Home Pond"

## Bugs needed for the first Growth Spurt. The rest are bonus snacks.
@export var bugs_for_spurt: int = 5
@export var heart_after_culvert: float = 10.0
@export var heart_for_meeting_nib: float = 25.0
@export var seeds_for_pantry: int = 8

@export var siblings: Array[Node3D] = []
@export var nib: NPC

var bugs_total: int = 0
var bugs_collected: int = 0
var seeds_total: int = 0
var seeds_collected: int = 0
var pantry_started: bool = false
var pantry_done: bool = false
var siblings_gone: bool = false

var _spurt_fired: bool = false

## Waypoints from the nest to the far side of the culvert.
const LEAVE_PATH: Array[Vector3] = [
	Vector3(-1.0, 0.0, 11.0), Vector3(-6.5, -0.4, 6.0), Vector3(-10.5, -0.35, 1.0),
	Vector3(-12.5, 0.0, 0.0), Vector3(-16.0, 0.0, 0.0), Vector3(-21.0, 0.0, 0.5),
]


func _ready() -> void:
	add_to_group("bug_hunt")
	add_to_group("pantry")
	for bug in get_tree().get_nodes_in_group("pickup_bug"):
		bugs_total += 1
		(bug as Pickup).collected.connect(_on_bug_collected)
	for seed in get_tree().get_nodes_in_group("pickup_seed"):
		seeds_total += 1
		(seed as Pickup).collected.connect(_on_seed_collected)
	if nib:
		nib.first_talk.connect(_on_met_nib)
	Globals.stage_changed.connect(_on_stage_changed)


# --- Act 1: bugs and the first spurt ---------------------------------------

func _on_bug_collected(_bug: Pickup) -> void:
	bugs_collected += 1
	if bugs_collected >= bugs_for_spurt and not _spurt_fired and Globals.stage == Globals.Stage.HATCHLING:
		_spurt_fired = true
		Globals.notify("Full belly. Something is happening...")
		await get_tree().create_timer(1.2).timeout
		Globals.request_growth_spurt()
	elif bugs_collected < bugs_for_spurt:
		Globals.notify("Yum. %d more." % (bugs_for_spurt - bugs_collected))


# --- Act 2: the Culvert -----------------------------------------------------

func _on_stage_changed(new_stage: Globals.Stage) -> void:
	if new_stage >= Globals.Stage.DUCKLING and not siblings_gone:
		siblings_gone = true
		_siblings_leave()


func _siblings_leave() -> void:
	await get_tree().create_timer(2.0).timeout
	Globals.notify("The others are moving on.")
	var last_tween: Tween
	for i in siblings.size():
		var sibling := siblings[i]
		if sibling == null:
			continue
		var tween := create_tween()
		tween.tween_interval(0.5 * i)
		var previous := sibling.global_position
		for point in LEAVE_PATH:
			var target := point + Vector3(0.0, 0.0, 0.6 * i)
			var seconds := maxf(previous.distance_to(target) / 2.2, 0.05)
			tween.tween_callback(_face.bind(sibling, target))
			tween.tween_property(sibling, "global_position", target, seconds)
			previous = target
		last_tween = tween
	if last_tween:
		await last_tween.finished
	Globals.notify("They didn't look back.")
	Globals.set_region_heart(REGION, heart_after_culvert)


func _face(node: Node3D, target: Vector3) -> void:
	var d := target - node.global_position
	d.y = 0.0
	if d.length() > 0.01:
		node.rotation.y = atan2(-d.x, -d.z)


# --- Act 3: Nib -------------------------------------------------------------

func _on_met_nib(_npc: NPC) -> void:
	Globals.add_region_heart(REGION, heart_for_meeting_nib)
	pantry_started = true
	Globals.notify("Nib's Pantry: find %d seeds in the reeds." % seeds_for_pantry)
	if nib:
		nib.lines_repeat = PackedStringArray(["Squeak. Seeds are scattered everywhere.", "The storm did it. I'm too small to carry them."])


func _on_seed_collected(_seed: Pickup) -> void:
	seeds_collected += 1
	if not pantry_started:
		Globals.notify("A seed. Someone might want these.")
		return
	if seeds_collected >= seeds_for_pantry and not pantry_done:
		pantry_done = true
		Globals.notify("Nib's pantry is full.")
		Globals.add_region_heart(REGION, 100.0)
		if nib:
			nib.lines_override = PackedStringArray(["Squeak! You found them all!", "You can stay in the reeds as long as you want.", "Friends don't have to match."])
	else:
		Globals.notify("Seed %d / %d" % [seeds_collected, seeds_for_pantry])
