extends Node
## Headless smoke test for Act 1. Run from the game/ folder with:
##   godot --headless --path . tests/act1_smoke_test.tscn
## Marra leads and waits for you, five bugs end First Supper, the hawk knocks
## you into the water in the open and counts a hide under the reeds, and three
## hides trigger Growth Spurt 1 and the family leaving.

var player: Player
var pond: Node
var flock: FamilyFlock
var hawk: HawkShadow
var frame: int = 0
var failures: PackedStringArray = []
var _mother_start: Vector3
var _mother_at_wait: Vector3
var _y_before_knock: float
var _caught: int = 0
var _worst_sink: float = 0.0


func _ready() -> void:
	Globals.start_in_egg = false
	pond = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	player = pond.get_node("Player")
	flock = pond.flock
	hawk = pond.hawk
	# Shorter beats so the test stays quick; gameplay values are the exports.
	hawk.warning_seconds = 0.5
	hawk.cross_seconds = 2.0
	hawk.seconds_between_passes = 1.0
	flock.max_wait = 30.0
	hawk.caught.connect(func() -> void: _caught += 1)
	_mother_start = flock.mother.global_position


func _press_action() -> void:
	var ev := InputEventAction.new()
	ev.action = "action"
	ev.pressed = true
	Input.parse_input_event(ev)


func _end_dialogue_quickly() -> void:
	for i in 4:
		_press_action()
		await get_tree().process_frame


func _ground_y(x: float, z: float) -> float:
	var inner := 400.0 - (x * x + z * z)
	if inner <= 0.0:
		return 0.0
	return minf(17.0 - sqrt(inner), 0.0)


func _physics_process(_delta: float) -> void:
	frame += 1
	if pond.act == pond.Act.LEAVING and flock.mother.visible:
		var m := flock.mother.global_position
		var expected := maxf(_ground_y(m.x, m.z), flock.WATER_Y)
		_worst_sink = maxf(_worst_sink, expected - m.y)
	match frame:
		5:
			_expect(pond.act == pond.Act.HELLO, "Act 1 begins with Hello (act %d)" % pond.act)
			_expect(not flock.moving, "Marra waits until everyone has been greeted")
			# Stand among the siblings: several talk circles overlap.
			player.global_position = Vector3(1.5, 0.1, 12.6)
		20:
			_expect(player.nearest_npc != null, "an NPC is in range")
			var d_best := player.nearest_npc.global_position.distance_to(player.global_position)
			for npc in get_tree().get_nodes_in_group("npc"):
				if (npc as Node3D).global_position.distance_to(player.global_position) < d_best - 0.01:
					_expect(false, "nearest NPC chosen (%s is closer than %s)" % [npc.npc_name, player.nearest_npc.npc_name])
			_press_action()
		22:
			_expect(Globals.dialogue_active, "E opens dialogue with the nearest duck")
			_end_dialogue_quickly()
		40:
			_expect(pond.greeted == 1, "one greeting counted (got %d)" % pond.greeted)
			# Greet the rest directly; the mechanic is the same.
			for npc in get_tree().get_nodes_in_group("npc"):
				if npc.get_parent() == flock and not npc.has_talked:
					npc.has_talked = true
					npc.first_talk.emit(npc)
		130:
			_expect(pond.act == pond.Act.KEEP_UP, "Keep Up begins once all five are greeted (act %d)" % pond.act)
			_expect(flock.moving, "flock is moving")
			# Stay put on the far side so she has to wait.
			player.global_position = Vector3(6.0, 0.1, 12.5)
		330:
			var wp: Vector3 = pond.KEEP_UP_ROUTE[1]
			print("act1: frame 330 marra=%s waiting=%.1f" % [flock.mother.global_position, flock._waiting])
			_expect(flock.mother.global_position.distance_to(wp) < 0.8, "Marra reached the second waypoint")
			_expect(flock._waiting >= 0.0, "Marra waits there for the straggler")
			_expect(flock.siblings[0].global_position.distance_to(flock.mother.global_position) < 4.0, "siblings hold near Marra")
			# Catch up.
			player.global_position = flock.mother.global_position + Vector3(1.5, 0.1, 1.0)
		390:
			var wp: Vector3 = pond.KEEP_UP_ROUTE[1]
			print("act1: frame 390 marra=%s waiting=%.1f" % [flock.mother.global_position, flock._waiting])
			_expect(flock._waiting < 0.0 and flock.mother.global_position.distance_to(wp) > 0.8, "Marra moves on once you're close")
			_expect(flock.mother.global_position.y < -0.3, "Marra is swimming toward the next waypoint")
		430:
			# Skip the rest of the loop: finish the route.
			flock.stop()
			flock.route_finished.emit()
		450:
			_expect(pond.act == pond.Act.FIRST_SUPPER, "First Supper begins after the route (act %d)" % pond.act)
			for bug in get_tree().get_nodes_in_group("pickup_bug"):
				if pond.bugs_collected >= 5:
					break
				player.global_position = (bug as Node3D).global_position + Vector3(0, 0.1, 0)
				await get_tree().physics_frame
				await get_tree().physics_frame
			player.global_position = Vector3(0.0, 0.1, 12.0)
		560:
			_expect(pond.bugs_collected >= 5, "ate five bugs (%d)" % pond.bugs_collected)
			_expect(pond.act == pond.Act.SHADOW, "The Shadow begins after supper (act %d)" % pond.act)
			_expect(hawk.active, "hawk active")
			# Stand in the open on the shore and wait for the first pass.
			player.global_position = Vector3(0.0, 0.1, 12.0)
			_y_before_knock = player.global_position.y
		900:
			print("act1: frame 900 passes=%d hides=%d caught=%d state=%s pos=%s" % [hawk.passes, hawk.hides, _caught, player.state_name(), player.global_position])
			_expect(hawk.passes >= 1, "a hawk pass happened")
			_expect(_caught >= 1, "caught in the open and knocked (%d)" % _caught)
			_expect(hawk.hides == 0, "no hide credited in the open (hides=%d)" % hawk.hides)
			_expect(player.global_position.distance_to(Vector3(0.0, 0.1, 12.0)) > 1.0, "knocked away from where you stood")
		1400:
			# Now hide under the reeds for the next pass.
			var spot: Node3D = get_tree().get_first_node_in_group("hide_spot")
			player.global_position = spot.global_position + Vector3(0, -0.5, 0)
		2400:
			print("act1: frame 2400 hides=%d passes=%d in_cover=%d act=%d" % [hawk.hides, hawk.passes, player.in_cover, pond.act])
			_expect(player.in_cover > 0, "player is in cover")
			_expect(hawk.hides >= 1, "hidden pass credited (hides=%d)" % hawk.hides)
		3600:
			print("act1: frame 3600 hides=%d act=%d stage=%s" % [hawk.hides, pond.act, Globals.stage_name()])
			_expect(hawk.hides >= 3, "three hides (%d)" % hawk.hides)
			_expect(Globals.stage == Globals.Stage.DUCKLING, "Growth Spurt 1 after three hides (stage %s)" % Globals.stage_name())
			_expect(pond.act >= pond.Act.LEAVING, "family is leaving (act %d)" % pond.act)
		5400:
			print("act1: frame 5400 act=%d heart=%.0f sib=%s" % [pond.act, Globals.heart, flock.siblings[0].global_position])
			_expect(pond.act == pond.Act.ALONE, "alone after the culvert (act %d)" % pond.act)
			_expect(_worst_sink < 0.08, "Marra never sank into the bank on the way (worst %.2f m)" % _worst_sink)
			_expect(flock.siblings[0].global_position.x < -19.0, "siblings went through the culvert")
			_expect(not flock.mother.visible, "Marra flew away")
			_expect(is_equal_approx(Globals.heart, 10.0), "Heart dropped to 10 (got %.0f)" % Globals.heart)
			_finish()


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		print("  FAIL ", description)
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("act1: PASS")
		get_tree().quit(0)
	else:
		print("act1: FAIL (%d)" % failures.size())
		get_tree().quit(1)
