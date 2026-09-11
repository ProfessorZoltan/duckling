extends Node
## Headless smoke test for P1. Run from the game/ folder with:
##   godot --headless --path . tests/smoke_test.tscn
## Instantiates the pond, walks the duck into the water, hops, grows a stage,
## and paddles to the far shore. Exits 0 on success, 1 on failure.

var player: Player
var frame: int = 0
var failures: PackedStringArray = []
var _seen_air_after_hop := false
var _heard: Dictionary = {}


func _ready() -> void:
	Globals.start_in_egg = false
	var pond: Node = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	player = pond.get_node("Player")
	Audio.played.connect(func(name: String) -> void: _heard[name] = true)
	print("smoke: pond loaded, player at ", player.global_position)


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		20:
			_expect(player.state == Player.State.WALK, "starts in WALK, got %s" % player.state_name())
			Input.action_press("move_forward")
		300:
			_expect(_heard.has("splash"), "a splash played when the duck entered the water")
			print("smoke: frame 300 state=%s pos=%s" % [player.state_name(), player.global_position])
			_expect(player.state == Player.State.SWIM, "in SWIM after walking into pond, got %s" % player.state_name())
			_expect(player.global_position.y < -0.5, "floating below water surface, y=%.2f" % player.global_position.y)
			Input.action_press("jump")
		302:
			Input.action_release("jump")
		420:
			_expect(_seen_air_after_hop, "hop from water entered AIR")
			_expect(player.state == Player.State.SWIM, "back in SWIM after hop, got %s" % player.state_name())
			_expect(_heard.has("splash"), "landing back in the water splashed again")
			Globals.advance_stage()
		422:
			_expect(is_equal_approx(Globals.player_scale, 1.25), "scale 1.25 after stage bump, got %.2f" % Globals.player_scale)
			_expect(is_equal_approx(player.body.scale.x, 1.25), "body scaled, got %.2f" % player.body.scale.x)
			var arm: SpringArm3D = player.camera_pivot.get_node("SpringArm3D")
			_expect(is_equal_approx(arm.spring_length, 3.75), "camera arm scaled, got %.2f" % arm.spring_length)
			var capsule := player.collision_shape.shape as CapsuleShape3D
			_expect(is_equal_approx(capsule.radius, 0.22 * 1.25), "capsule scaled, got %.3f" % capsule.radius)
		1300:
			print("smoke: frame 1300 state=%s pos=%s" % [player.state_name(), player.global_position])
			_expect(player.state == Player.State.WALK, "back in WALK on far shore, got %s" % player.state_name())
			_expect(player.global_position.z < -10.0, "crossed the pond, z=%.2f" % player.global_position.z)
			_expect(player.global_position.y > -0.2, "standing on ground, y=%.2f" % player.global_position.y)
			Input.action_release("move_forward")
			_finish()

	if frame > 302 and frame < 420 and player.state == Player.State.AIR:
		_seen_air_after_hop = true


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		print("  FAIL ", description)
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("smoke: PASS")
		get_tree().quit(0)
	else:
		print("smoke: FAIL (%d)" % failures.size())
		get_tree().quit(1)
