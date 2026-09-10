extends Node
## Headless smoke test for P2 growth. Run from the game/ folder with:
##   godot --headless --path . tests/growth_smoke_test.tscn
## Bumps the closed reed gate, plays a Growth Spurt, checks the world shrank
## and snapped back, then walks through the now-open gate and eats a bug.

var player: Player
var world: Node3D
var director: GrowthSpurtDirector
var reed_gate: SizeGate
var culvert_gate: SizeGate
var pond: Node
var frame: int = 0
var failures: PackedStringArray = []
var _pos_before_spurt: Vector3
var _min_world_scale: float = 1.0


func _ready() -> void:
	pond = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	player = pond.get_node("Player")
	world = pond.get_node("World")
	director = pond.get_node("GrowthSpurtDirector")
	reed_gate = pond.get_node("World/ReedPocket/ReedGate")
	culvert_gate = pond.get_node("World/FarShore/CulvertGate")
	# Start by the west bank, off the culvert line (camera yaw 0, so A walks -X).
	player.global_position = Vector3(-11.5, 0.1, 5.0)


func _physics_process(_delta: float) -> void:
	frame += 1
	if director.playing:
		_min_world_scale = minf(_min_world_scale, world.scale.x)
	match frame:
		20:
			_expect(Globals.stage == Globals.Stage.HATCHLING, "starts as a Hatchling")
			_expect(not reed_gate.is_open(), "reed gate closed for a hatchling")
			_expect(culvert_gate.is_open(), "culvert open for a hatchling")
			_expect(pond.bugs_total == 7, "seven bugs in the pond, got %d" % pond.bugs_total)
			Input.action_press("move_left")
		150:
			print("growth: frame 150 x=%.2f (bank face is x=-13)" % player.global_position.x)
			_expect(player.global_position.x > -13.3, "bank blocks the hatchling away from the pipe (x=%.2f)" % player.global_position.x)
			Input.action_release("move_left")
			player.global_position = Vector3(-11.5, 0.1, 0.0)
		160:
			Input.action_press("move_left")
		460:
			print("growth: frame 460 x=%.2f (far side is x<-19)" % player.global_position.x)
			_expect(player.global_position.x < -19.5, "hatchling walked through the culvert (x=%.2f)" % player.global_position.x)
			Input.action_release("move_left")
			player.global_position = Vector3(12.0, 0.1, 1.5)
		480:
			Input.action_press("move_right")
		700:
			print("growth: frame 700 x=%.2f" % player.global_position.x)
			_expect(player.global_position.x < 16.0, "reed gate stops the hatchling (x=%.2f)" % player.global_position.x)
			_expect(player.global_position.x > 14.5, "walked up to the gate (x=%.2f)" % player.global_position.x)
			Input.action_release("move_right")
		720:
			_pos_before_spurt = player.global_position
			Globals.request_growth_spurt()
		722:
			_expect(director.playing, "director is playing the spurt")
			_expect(player.frozen, "player frozen during the spurt")
		800:
			print("growth: mid-spurt world scale=%.3f world pos=%s" % [world.scale.x, world.position])
			_expect(world.scale.x < 0.95 and world.scale.x > 0.8, "world is shrinking mid-spurt (%.3f)" % world.scale.x)
			_expect(player.global_position.distance_to(_pos_before_spurt) < 0.01, "player held still during the spurt")
			_expect(is_equal_approx(Globals.player_scale, 1.0), "player scale unchanged until the swap")
		900:
			print("growth: after spurt stage=%s world scale=%.3f min=%.3f" % [Globals.stage_name(), world.scale.x, _min_world_scale])
			_expect(not director.playing, "spurt finished")
			_expect(Globals.stage == Globals.Stage.DUCKLING, "now a Duckling")
			_expect(is_equal_approx(world.scale.x, 1.0) and world.position.is_zero_approx(), "world snapped back to scale 1 at origin")
			_expect(is_equal_approx(_min_world_scale, 0.8), "world bottomed out at 0.8 (got %.3f)" % _min_world_scale)
			_expect(is_equal_approx(Globals.player_scale, 1.25), "player scale 1.25")
			_expect(not player.frozen, "player unfrozen")
			_expect(reed_gate.is_open(), "reed gate open for a duckling")
			_expect(not culvert_gate.is_open(), "culvert closed for a duckling")
			Input.action_press("move_right")
		1180:
			print("growth: frame 1180 x=%.2f bugs=%d" % [player.global_position.x, pond.bugs_collected])
			_expect(player.global_position.x > 17.0, "walked through the open reed gate (x=%.2f)" % player.global_position.x)
			_expect(pond.bugs_collected >= 1, "ate the bug behind the reeds")
			Input.action_release("move_right")
			_finish()


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		print("  FAIL ", description)
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("growth: PASS")
		get_tree().quit(0)
	else:
		print("growth: FAIL (%d)" % failures.size())
		get_tree().quit(1)
