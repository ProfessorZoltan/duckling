extends Node
## The culvert is the one passage the player loses. Run from game/ with:
##   godot --headless --path . tests/culvert_smoke_test.tscn
##
## Checks the whole shape of that beat, not just the gate flag: that First
## Supper genuinely needs the far-side bug, that a Hatchling can walk the pipe,
## and that a Duckling is stopped by it. Reasoning about the clearance is not
## enough — the arch is 0.82 m of collision against a 0.70 m duck, and the
## margin is small enough that only walking it proves anything.

const NEAR_SIDE := Vector3(-12.0, 0.1, 0.0)
## West of the far mouth at x = -19: through the pipe and out the other side.
const THROUGH_X := -19.5

var player: Player
var pond: Node
var gate: SizeGate
var failures: PackedStringArray = PackedStringArray()


func _ready() -> void:
	Globals.start_in_egg = false
	pond = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	player = pond.get_node("Player")
	gate = pond.get_node("World/FarShore/CulvertGate")
	# add_child() already ran the whole subtree's _ready, so awaiting
	# player.ready here would wait for a signal that has been and gone.
	await get_tree().physics_frame

	_check_design()
	await _check_hint()
	await _walk(Globals.Stage.HATCHLING)
	var hatchling_x := player.global_position.x
	_expect(hatchling_x < THROUGH_X,
		"a Hatchling walks through the culvert (reached x=%.1f)" % hatchling_x)

	await _walk(Globals.Stage.DUCKLING)
	var duckling_x := player.global_position.x
	_expect(duckling_x > THROUGH_X,
		"a Duckling is stopped by it (reached x=%.1f)" % duckling_x)

	_finish()


## The far-side bug has to be load-bearing, or the passage is decoration.
func _check_design() -> void:
	var hatchling: float = Globals.STAGE_SCALE[Globals.Stage.HATCHLING]
	var duckling: float = Globals.STAGE_SCALE[Globals.Stage.DUCKLING]
	_expect(gate.is_open(hatchling), "culvert is open to a Hatchling")
	_expect(not gate.is_open(duckling), "culvert is shut to a Duckling")

	var reeds: SizeGate = pond.get_node("World/ReedPocket/ReedGate")
	var beyond := 0
	var reachable := 0
	for bug in get_tree().get_nodes_in_group("pickup_bug"):
		var at := (bug as Node3D).global_position
		if at.x <= pond.CULVERT_FAR_SIDE_X:
			beyond += 1
		elif at.x < reeds.global_position.x:
			# Short of the reed wall, so a Hatchling can swim or walk to it.
			reachable += 1
	_expect(beyond == 1, "exactly one bug sits past the culvert (found %d)" % beyond)
	_expect(reachable < pond.bugs_for_supper,
		"supper cannot be finished without it (%d reachable, needs %d)"
			% [reachable, pond.bugs_for_supper])


## Eating the open pond dry has to produce the nudge toward the pipe. The first
## version of that check counted the Reed Pocket bugs as "still in reach", so it
## could never fire; nothing but asserting on the notice would have caught it.
func _check_hint() -> void:
	Globals.stage = Globals.Stage.HATCHLING
	var notices: PackedStringArray = PackedStringArray()
	Globals.notice.connect(func(text: String) -> void: notices.append(text))
	# Skip ahead to supper, then clear the open pond the way a player would.
	pond._begin_first_supper()
	for bug in get_tree().get_nodes_in_group("pickup_bug"):
		var at := (bug as Node3D).global_position
		if at.x <= pond.CULVERT_FAR_SIDE_X:
			continue
		if at.x > pond.get_node("World/ReedPocket/ReedGate").global_position.x:
			continue
		player.global_position = at
		await get_tree().physics_frame
		await get_tree().physics_frame
	var hinted := false
	for text in notices:
		if text.contains("Through the pipe"):
			hinted = true
	_expect(hinted, "clearing the open pond points the player at the culvert")
	_expect(pond.bugs_collected == pond.bugs_for_supper - 1,
		"and that leaves exactly one bug to get (%d of %d)"
			% [pond.bugs_collected, pond.bugs_for_supper])


## Point the camera west and hold forward: movement is camera-relative, so the
## pivot is what decides which way "forward" is.
func _walk(stage: Globals.Stage) -> void:
	Globals.stage = stage
	await get_tree().physics_frame
	player.global_position = NEAR_SIDE
	player.velocity = Vector3.ZERO
	player.camera_pivot.rotation.y = PI * 0.5
	await get_tree().physics_frame
	Input.action_press("move_forward")
	for _i in 240:
		await get_tree().physics_frame
	Input.action_release("move_forward")
	await get_tree().physics_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		print("  FAIL ", description)
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("culvert: PASS")
		get_tree().quit(0)
	else:
		print("culvert: FAIL (%d)" % failures.size())
		get_tree().quit(1)
