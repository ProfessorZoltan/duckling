extends Node
## Captures the Heart arc in the pond: color, the siblings leaving, gray,
## meeting Nib, and full color after the pantry. Not a test.
##   xvfb-run -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 tests/heart_screenshot_tour.tscn -- --out=<dir>

var player: Player
var pond: Node
var frame: int = 0
var out_dir: String = "user://screenshots"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	pond = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	player = pond.get_node("Player")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Stand on the east shore looking west across the pond at the culvert.
	_place(Vector3(9.0, 0.1, 2.0), PI / 2)


func _place(pos: Vector3, yaw: float) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.camera_pivot.rotation.y = yaw
	player.body.rotation.y = yaw


func _press_action() -> void:
	var ev := InputEventAction.new()
	ev.action = "action"
	ev.pressed = true
	Input.parse_input_event(ev)


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		40:
			_shoot("01_pond_in_color")
		60:
			Globals.stage = Globals.Stage.DUCKLING
		420:
			_shoot("02_siblings_leaving")
		1500:
			_shoot("03_pond_gone_gray")
			_place(Vector3(24.5, 0.1, 1.8), 0.0)
		1560:
			_press_action()
		1600:
			_shoot("04_meeting_nib")
		1640:
			_press_action()
		1680:
			_press_action()
		1720:
			_press_action()
		1760:
			_press_action()
		1800:
			for seed in get_tree().get_nodes_in_group("pickup_seed"):
				player.global_position = (seed as Node3D).global_position + Vector3(0, 0.1, 0)
				await get_tree().physics_frame
				await get_tree().physics_frame
			_place(Vector3(9.0, 0.1, 2.0), PI / 2)
		2100:
			_shoot("05_pond_recolored")
		2130:
			get_tree().quit(0)


func _shoot(name: String) -> void:
	var heart := Globals.heart
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("shot ", name, " heart=", heart)
