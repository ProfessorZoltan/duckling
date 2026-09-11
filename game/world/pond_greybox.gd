extends Node3D
## Home Pond director. Runs the Prologue through Act 3 beats (design doc §2):
##  - Prologue: the egg (EggPrologue).
##  - Act 1 "Keep Up": follow Marra and the siblings round the pond (M2).
##  - Act 1 "First Supper": eat five water bugs (M3).
##  - Act 1 "The Shadow": hide from the hawk three times -> Growth Spurt 1 (M4).
##  - Act 2 "The Far Shore" / "The Culvert": the family leaves; siblings squeeze
##    through the culvert, Marra flies; the pond drains to gray (M5, M6).
##  - Act 3 "A Small Voice": meet Nib in the reeds; Nib's Pantry (M7).

enum Act { EGG, KEEP_UP, FIRST_SUPPER, SHADOW, GROWN, LEAVING, ALONE }

const REGION := "Home Pond"

@export var bugs_for_supper: int = 5
@export var heart_after_culvert: float = 10.0
@export var heart_for_meeting_nib: float = 25.0
@export var seeds_for_pantry: int = 8

@export var flock: FamilyFlock
@export var hawk: HawkShadow
@export var egg: EggPrologue
@export var nib: NPC

var act: Act = Act.EGG
var bugs_total: int = 0
var bugs_collected: int = 0
var seeds_total: int = 0
var seeds_collected: int = 0
var pantry_started: bool = false
var pantry_done: bool = false
var siblings_gone: bool = false

## Marra's loop round the pond. Points below the waterline are swum.
const KEEP_UP_ROUTE: Array[Vector3] = [
	Vector3(0.0, 0.0, 10.4), Vector3(-2.5, -0.62, 7.0), Vector3(-7.0, -0.62, 2.0),
	Vector3(-5.0, -0.62, -5.0), Vector3(3.0, -0.62, -7.0), Vector3(7.0, -0.62, -2.0),
	Vector3(5.0, -0.62, 5.0), Vector3(2.5, 0.0, 10.4), Vector3(3.5, 0.0, 12.0),
]
## From the nest to the culvert. The last point is inside the far shore.
const LEAVE_ROUTE: Array[Vector3] = [
	Vector3(-1.0, 0.0, 11.0), Vector3(-6.5, -0.62, 6.0), Vector3(-10.5, -0.62, 1.0),
	Vector3(-12.3, 0.0, 0.0),
]
const CULVERT_EXIT := Vector3(-21.0, 0.0, 0.5)


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
	if hawk:
		hawk.pass_started.connect(_on_hawk_pass_started)
		hawk.hidden.connect(_on_hidden)
		hawk.caught.connect(_on_caught)
		hawk.all_hidden.connect(_on_all_hidden)
	Globals.stage_changed.connect(_on_stage_changed)
	if egg and is_instance_valid(egg) and Globals.start_in_egg:
		act = Act.EGG
		egg.hatched.connect(_begin_keep_up)
	else:
		_begin_keep_up.call_deferred()


# --- Act 1 --------------------------------------------------------------------

func _begin_keep_up() -> void:
	if act > Act.KEEP_UP:
		return
	act = Act.KEEP_UP
	Globals.notify("Marra: Keep up, little one.")
	Globals.set_objective("Keep up with Marra.")
	if flock:
		flock.route_finished.connect(_begin_first_supper, CONNECT_ONE_SHOT)
		flock.start_route(KEEP_UP_ROUTE)
	else:
		_begin_first_supper()


func _begin_first_supper() -> void:
	act = Act.FIRST_SUPPER
	Globals.notify("Marra: Eat. Bugs, there.")
	Globals.set_objective("First Supper: eat %d water bugs." % bugs_for_supper)
	if bugs_collected >= bugs_for_supper:
		_begin_shadow()


func _on_bug_collected(_bug: Pickup) -> void:
	bugs_collected += 1
	if act == Act.FIRST_SUPPER:
		if bugs_collected >= bugs_for_supper:
			Globals.notify("Full belly.")
			await get_tree().create_timer(1.5).timeout
			if act == Act.FIRST_SUPPER:
				_begin_shadow()
		else:
			Globals.set_objective("First Supper: eat %d water bugs (%d / %d)." % [bugs_for_supper, bugs_collected, bugs_for_supper])
	elif act >= Act.SHADOW:
		Globals.notify("Yum.")


func _begin_shadow() -> void:
	act = Act.SHADOW
	Globals.notify("Something passes high overhead. The others go quiet.")
	Globals.set_objective("The Shadow: hide under the reeds when it comes (0 / %d)." % (hawk.hides_needed if hawk else 3))
	if hawk:
		hawk.begin()


func _on_hawk_pass_started() -> void:
	Globals.notify("Marra: Hide! Under the reeds!")
	if flock:
		var spots: Array[Vector3] = []
		for spot in get_tree().get_nodes_in_group("hide_spot"):
			spots.append((spot as Node3D).global_position)
		if not spots.is_empty():
			flock.scatter(spots)


func _on_hidden(count: int) -> void:
	Globals.notify("Hidden. It didn't see you.")
	Globals.set_objective("The Shadow: hide under the reeds when it comes (%d / %d)." % [count, hawk.hides_needed])
	_regroup_later()


func _on_caught() -> void:
	Globals.notify("WHUMP. Into the water. Next time, hide.")
	_regroup_later()


func _regroup_later() -> void:
	await get_tree().create_timer(2.5).timeout
	if flock and act == Act.SHADOW:
		flock.regroup(Vector3(1.0, 0.0, 10.8))


func _on_all_hidden() -> void:
	act = Act.GROWN
	Globals.set_objective("")
	Globals.notify("Marra: ...You're bigger. When did you get so big?")
	await get_tree().create_timer(2.0).timeout
	Globals.request_growth_spurt()


# --- Act 2 --------------------------------------------------------------------

func _on_stage_changed(new_stage: Globals.Stage) -> void:
	if new_stage >= Globals.Stage.DUCKLING and not siblings_gone:
		siblings_gone = true
		_family_leaves()


func _family_leaves() -> void:
	act = Act.LEAVING
	await get_tree().create_timer(2.0).timeout
	Globals.notify("The others are moving on.")
	Globals.set_objective("The Far Shore: follow the family.")
	if flock == null:
		_after_culvert()
		return
	flock.route_finished.connect(_at_the_culvert, CONNECT_ONE_SHOT)
	flock.start_route(LEAVE_ROUTE, false)


func _at_the_culvert() -> void:
	# The confrontation. Pip says the meanest line; Marra doesn't intervene.
	Globals.notify("Pip: You're not one of us. Stop following.")
	await get_tree().create_timer(3.0).timeout
	Globals.notify("Quill looks back. Just once.")
	# Siblings squeeze through the culvert one after another.
	var last: Tween
	for i in flock.siblings.size():
		var sibling := flock.siblings[i]
		var tween := create_tween()
		tween.tween_interval(0.6 * i)
		tween.tween_property(sibling, "rotation:y", PI / 2.0, 0.2)
		tween.tween_property(sibling, "global_position", Vector3(-13.6, 0.0, 0.0), 1.0)
		tween.tween_property(sibling, "global_position", CULVERT_EXIT + Vector3(0.0, 0.0, 0.7 * i - 1.0), 3.0)
		last = tween
	# Marra takes off over the bank without a goodbye.
	var lift := create_tween()
	lift.tween_interval(1.5)
	lift.tween_property(flock.mother, "global_position", flock.mother.global_position + Vector3(-6.0, 6.0, 0.0), 2.0) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	lift.tween_property(flock.mother, "global_position", Vector3(-45.0, 16.0, -8.0), 4.0)
	lift.tween_callback(func() -> void: flock.mother.visible = false)
	if last:
		await last.finished
	_after_culvert()


func _after_culvert() -> void:
	act = Act.ALONE
	Globals.notify("They didn't look back.")
	Globals.set_objective("")
	Globals.set_region_heart(REGION, heart_after_culvert)


# --- Act 3 --------------------------------------------------------------------

func _on_met_nib(_npc: NPC) -> void:
	Globals.add_region_heart(REGION, heart_for_meeting_nib)
	pantry_started = true
	Globals.notify("Nib's Pantry: find %d seeds in the reeds." % seeds_for_pantry)
	Globals.set_objective("Nib's Pantry: find seeds (0 / %d)." % seeds_for_pantry)
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
		Globals.set_objective("")
		Globals.add_region_heart(REGION, 100.0)
		if nib:
			nib.lines_override = PackedStringArray(["Squeak! You found them all!", "You can stay in the reeds as long as you want.", "Friends don't have to match."])
	else:
		Globals.set_objective("Nib's Pantry: find seeds (%d / %d)." % [seeds_collected, seeds_for_pantry])
