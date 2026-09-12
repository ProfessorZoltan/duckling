extends Node3D
## Home Pond director. Runs the Prologue through Act 3 beats (design doc §2):
##  - Prologue: the egg (EggPrologue).
##  - Act 1 "Keep Up": follow Marra and the siblings round the pond (M2).
##  - Act 1 "Hello": say hello to everyone once the loop is over, so the
##    siblings' lines land after they've watched you struggle to keep up.
##  - Act 1 "First Supper": eat five water bugs (M3).
##  - Act 1 "The Shadow": hide from the hawk three times -> Growth Spurt 1 (M4).
##  - Act 2 "The Far Shore" / "The Culvert": the family leaves; siblings squeeze
##    through the culvert, Marra flies; the pond drains to gray (M5, M6).
##  - Act 3 "A Small Voice": meet Nib in the reeds; Nib's Pantry (M7).

enum Act { EGG, KEEP_UP, HELLO, FIRST_SUPPER, SHADOW, GROWN, LEAVING, ALONE }

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
var greeted: int = 0
var family_size: int = 0
var bugs_total: int = 0
var bugs_collected: int = 0
var seeds_total: int = 0
var seeds_collected: int = 0
var pantry_started: bool = false
var pantry_done: bool = false
var siblings_gone: bool = false
var culvert_hinted: bool = false

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
## Anything west of the culvert's far mouth is through the pipe.
const CULVERT_FAR_SIDE_X := -18.7


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
	if flock:
		var members: Array[Node3D] = [flock.mother]
		members.append_array(flock.siblings)
		for member in members:
			if member is NPC:
				family_size += 1
				(member as NPC).first_talk.connect(_on_greeted)
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
		flock.route_finished.connect(_begin_hello, CONNECT_ONE_SHOT)
		flock.start_route(KEEP_UP_ROUTE)
	else:
		_begin_hello()


func _begin_hello() -> void:
	if act > Act.HELLO:
		return
	act = Act.HELLO
	# Greetings during the loop already counted; only ask for the ones left.
	if family_size == 0 or greeted >= family_size:
		_begin_first_supper()
		return
	Globals.notify("Marra: Rest a moment. Say hello to the others.")
	Globals.set_objective("Say hello to your family (%d / %d)." % [greeted, family_size])


func _on_greeted(_npc: NPC) -> void:
	greeted += 1
	if act != Act.HELLO:
		return
	if greeted >= family_size:
		Globals.set_objective("")
		await get_tree().create_timer(1.0).timeout
		_begin_first_supper()
	else:
		Globals.set_objective("Say hello to your family (%d / %d)." % [greeted, family_size])


func _begin_first_supper() -> void:
	act = Act.FIRST_SUPPER
	Globals.notify("Marra: Eat. Bugs, there.")
	Globals.set_objective("First Supper: eat %d water bugs." % bugs_for_supper)
	if bugs_collected >= bugs_for_supper:
		_begin_shadow()


func _on_bug_collected(bug: Pickup) -> void:
	bugs_collected += 1
	if act == Act.FIRST_SUPPER:
		if bugs_collected >= bugs_for_supper:
			Globals.notify("Full belly.")
			await get_tree().create_timer(1.5).timeout
			if act == Act.FIRST_SUPPER:
				_begin_shadow()
		else:
			Globals.set_objective("First Supper: eat %d water bugs (%d / %d)." % [bugs_for_supper, bugs_collected, bugs_for_supper])
			_hint_past_the_culvert(bug)
	elif act >= Act.SHADOW:
		Globals.notify("Yum.")


## Supper's last bug sits through the culvert, and a player who has eaten the
## open pond dry has no reason to think there is anywhere else to look. Say so
## the moment nothing is left in reach — and say that they still fit, so the day
## the pipe closes on them is a loss and not a puzzle.
##
## "In reach" is the open pond only. The bugs in the Reed Pocket sit behind a
## gate that wants scale 1.2, so a Hatchling at supper can never reach them;
## count those as remaining and this hint never fires at all.
##
## [param eaten] is the pickup that triggered this. It is still in the group and
## still valid — queue_free() has not run yet — so it has to be skipped by hand
## or the last bug in the pond counts itself as still there and nothing is said.
func _hint_past_the_culvert(eaten: Pickup) -> void:
	if culvert_hinted:
		return
	var reed_wall_x := INF
	var reeds := get_node_or_null("World/ReedPocket/ReedGate") as SizeGate
	if reeds and not reeds.is_open():
		reed_wall_x = reeds.global_position.x
	var in_reach := 0
	var beyond := 0
	for bug in get_tree().get_nodes_in_group("pickup_bug"):
		var node := bug as Node3D
		if node == eaten or not is_instance_valid(node):
			continue
		var x := node.global_position.x
		if x <= CULVERT_FAR_SIDE_X:
			beyond += 1
		elif x < reed_wall_x:
			in_reach += 1
	if beyond == 0 or in_reach > 0:
		return
	culvert_hinted = true
	Globals.notify("Marra: One more. Through the pipe. You still fit.")


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
	if nib:
		nib.lines_repeat = PackedStringArray(["Squeak. Seeds are scattered everywhere.", "The storm did it. I'm too small to carry them."])
	if seeds_collected > 0:
		Globals.notify("Nib's Pantry: you already have %d of %d seeds." % [mini(seeds_collected, seeds_for_pantry), seeds_for_pantry])
	else:
		Globals.notify("Nib's Pantry: find %d seeds in the reeds." % seeds_for_pantry)
	# Seeds found before meeting her still count, so a full pouch finishes now.
	_refresh_pantry()


func _on_seed_collected(_seed: Pickup) -> void:
	seeds_collected += 1
	if not pantry_started:
		Globals.notify("A seed. Someone might want these.")
		return
	_refresh_pantry()


func _refresh_pantry() -> void:
	if pantry_done or not pantry_started:
		return
	if seeds_collected >= seeds_for_pantry:
		pantry_done = true
		Globals.notify("Nib's pantry is full.")
		Globals.set_objective("")
		Globals.add_region_heart(REGION, 100.0)
		if nib:
			nib.lines_override = PackedStringArray(["Squeak! You found them all!", "You can stay in the reeds as long as you want.", "Friends don't have to match."])
	else:
		Globals.set_objective("Nib's Pantry: find seeds (%d / %d)." % [seeds_collected, seeds_for_pantry])
