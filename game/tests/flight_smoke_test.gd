extends Node
## Headless smoke test for P4 flight. Run from the game/ folder with:
##   godot --headless --path . tests/flight_smoke_test.tscn
## Walks off the cliff, glides, dives, pulls up, flaps, then dives into the
## lake. Exits 0 on success, 1 on failure.

var player: Player
var frame: int = 0
var failures: PackedStringArray = []
var _y_at_glide_start: float = 0.0
var _speed_before_dive: float = 0.0
var _stamina_before_flap: float = 0.0
var _y_before_flap: float = 0.0
var _peak_vy_after_flap: float = -INF
var _flew: bool = false


func _ready() -> void:
	var scene: Node = load("res://world/cliff_test.tscn").instantiate()
	add_child(scene)
	player = scene.get_node("Player")
	print("flight: scene loaded, stage=%s scale=%.2f" % [Globals.Stage.keys()[Globals.stage], Globals.player_scale])


func _physics_process(_delta: float) -> void:
	frame += 1
	if player.state == Player.State.FLY:
		_flew = true
	match frame:
		20:
			_expect(player.state == Player.State.WALK, "starts in WALK on the plateau, got %s" % player.state_name())
			_expect(Globals.stage == Globals.Stage.FLEDGLING, "course forces FLEDGLING stage")
			Input.action_press("move_forward")
		140:
			print("flight: frame 140 state=%s pos=%s" % [player.state_name(), player.global_position])
			_expect(player.state == Player.State.AIR, "walked off the edge into AIR, got %s" % player.state_name())
			Input.action_release("move_forward")
			Input.action_press("jump")
		142:
			Input.action_release("jump")
			_expect(player.state == Player.State.FLY, "jump press in AIR starts FLY, got %s" % player.state_name())
			_expect(player.stamina < player.max_stamina, "first flap spent stamina (%.0f)" % player.stamina)
			_y_at_glide_start = player.global_position.y
		240:
			var vy := player.velocity.y
			print("flight: frame 240 state=%s speed=%.1f pitch=%d vy=%.2f" % [player.state_name(), player.air_speed, int(rad_to_deg(player.pitch)), vy])
			_expect(player.state == Player.State.FLY, "still gliding, got %s" % player.state_name())
			_expect(vy < 0.0 and vy > -6.0, "hands-off glide sinks gently (vy=%.2f)" % vy)
		340:
			# Past ring 1 now. Dive.
			_speed_before_dive = player.air_speed
			Input.action_press("move_back")
		430:
			print("flight: frame 430 speed=%.1f pitch=%d" % [player.air_speed, int(rad_to_deg(player.pitch))])
			_expect(player.air_speed > _speed_before_dive + 3.0, "dive gained speed (%.1f -> %.1f)" % [_speed_before_dive, player.air_speed])
			_expect(player.pitch < deg_to_rad(-40.0), "dive pitched nose down (%d°)" % int(rad_to_deg(player.pitch)))
			Input.action_release("move_back")
			Input.action_press("move_forward")
		520:
			print("flight: frame 520 speed=%.1f pitch=%d vy=%.2f" % [player.air_speed, int(rad_to_deg(player.pitch)), player.velocity.y])
			_expect(player.pitch > 0.0, "pull-up pitched nose up (%d°)" % int(rad_to_deg(player.pitch)))
			_expect(player.air_speed < _speed_before_dive + 3.0, "pull-up bled speed back (%.1f)" % player.air_speed)
			Input.action_release("move_forward")
			_stamina_before_flap = player.stamina
			_y_before_flap = player.global_position.y
			Input.action_press("jump")
		522:
			Input.action_release("jump")
			_expect(player.stamina < _stamina_before_flap, "flap spent stamina")
		570:
			_expect(_peak_vy_after_flap > 0.0, "flap produced upward velocity (peak vy=%.2f)" % _peak_vy_after_flap)
		620:
			# Over the lake now: dive in. Water must be a safe landing at any speed.
			Input.action_press("move_back")
		1000:
			print("flight: frame 1000 state=%s pos=%s" % [player.state_name(), player.global_position])
			Input.action_release("move_back")
			_expect(_flew, "flew at some point")
			_expect(player.state == Player.State.SWIM, "dived into the lake and is swimming (state %s)" % player.state_name())
			var course := get_tree().get_first_node_in_group("flight_course")
			print("flight: rings passed %d / %d" % [course.rings_passed, course.rings_total])
			_expect(course.rings_passed >= 1, "the first ring sits on the walk-off glide line")
			_finish()

	if frame > 522 and frame <= 570:
		_peak_vy_after_flap = maxf(_peak_vy_after_flap, player.velocity.y)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		print("  FAIL ", description)
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("flight: PASS")
		get_tree().quit(0)
	else:
		print("flight: FAIL (%d)" % failures.size())
		get_tree().quit(1)
