extends Node
## Headless smoke test for the egg prologue. Run from the game/ folder with:
##   godot --headless --path . tests/egg_smoke_test.tscn
## Starts in the egg, pecks eight times, and checks the hatch hands control to
## the third-person camera with the player free to move.

var player: Player
var egg: EggPrologue
var frame: int = 0
var failures: PackedStringArray = []
var _cap_start: Vector3


func _ready() -> void:
	Globals.start_in_egg = true
	var pond: Node = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	player = pond.get_node("Player")
	egg = pond.get_node("World/EggPrologue")
	_cap_start = egg.cap.global_position


func _peck() -> void:
	var ev := InputEventAction.new()
	ev.action = "jump"
	ev.pressed = true
	Input.parse_input_event(ev)


func _physics_process(_delta: float) -> void:
	frame += 1
	if frame >= 40 and frame < 40 + 8 * 10 and (frame - 40) % 10 == 0:
		_peck()
	match frame:
		10:
			_expect(egg.active, "prologue active at start")
			_expect(player.frozen, "player frozen inside the egg")
			_expect(not player.body.visible, "player body hidden inside the egg")
			_expect(egg.egg_camera.current, "egg camera is current")
			_expect(egg._overlay.color.a > 0.8, "starts dark (alpha %.2f)" % egg._overlay.color.a)
		75:
			_expect(egg.cracks == 4, "four pecks registered (got %d)" % egg.cracks)
			_expect(egg.crack_root.get_child_count() == 4, "four crack slivers")
			_expect(egg._overlay.color.a < 0.7, "light bleeding in (alpha %.2f)" % egg._overlay.color.a)
		125:
			_expect(egg.cracks == 8, "eight pecks registered (got %d)" % egg.cracks)
			_expect(egg._hatching, "hatch started")
		330:
			print("egg: frame 330 cap=%s frozen=%s" % [egg.cap.global_position, player.frozen])
			_expect(not egg.active, "prologue finished")
			_expect(not player.frozen, "player free after hatching")
			_expect(player.body.visible, "player body visible")
			var cam: Camera3D = player.camera_pivot.get_node("SpringArm3D/Camera3D")
			_expect(cam.current, "third-person camera current")
			_expect(egg.cap.global_position.distance_to(_cap_start) > 0.6, "cap tumbled off the nest")
			_expect(egg.cup.global_position.distance_to(_cap_start) < 0.01, "cup stayed in the nest")
			_expect(not Globals.start_in_egg, "start_in_egg cleared")
			Input.action_press("move_forward")
		420:
			_expect(player.global_position.z < 12.0, "walked out of the shell (z=%.2f)" % player.global_position.z)
			Input.action_release("move_forward")
			_finish()


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		print("  FAIL ", description)
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("egg: PASS")
		get_tree().quit(0)
	else:
		print("egg: FAIL (%d)" % failures.size())
		get_tree().quit(1)
