extends Node
## Captures the size gates at Hatchling and Duckling size, to check that what
## fits visually matches what the gate allows. Not a test.
##   xvfb-run -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 tests/gate_screenshot_tour.tscn -- --out=<dir>

var player: Player
var frame: int = 0
var out_dir: String = "user://screenshots"


func _ready() -> void:
	Globals.start_in_egg = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var scene: Node = load("res://world/pond_greybox.tscn").instantiate()
	add_child(scene)
	player = scene.get_node("Player")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_place(Vector3(-12.2, 0.1, 0.0), PI / 2)


func _place(pos: Vector3, yaw: float) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.camera_pivot.rotation.y = yaw
	player.body.rotation.y = yaw


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		40:
			_shoot("01_culvert_hatchling")
		70:
			Globals.stage = Globals.Stage.DUCKLING
		110:
			_shoot("02_culvert_duckling")
		140:
			Globals.stage = Globals.Stage.HATCHLING
			_place(Vector3(14.6, 0.1, 0.0), -PI / 2)
		180:
			_shoot("03_reeds_hatchling")
		210:
			Globals.stage = Globals.Stage.DUCKLING
		280:
			_shoot("04_reeds_duckling_open")
		310:
			get_tree().quit(0)


func _shoot(name: String) -> void:
	var stage := Globals.stage_name()
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("shot ", name, " stage=", stage)
