extends Node
## Captures the Growth Spurt sequence in the pond. Not a test.
##   xvfb-run -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 tests/growth_screenshot_tour.tscn -- --out=<dir>

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


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		10:
			Input.action_press("move_forward")
		70:
			Input.action_release("move_forward")
			# Look back at the nest and siblings so the shrink has references.
			player.camera_pivot.rotation.y = PI
		110:
			_shoot("01_hatchling_by_the_nest")
			Globals.request_growth_spurt()
		150:
			_shoot("02_spurt_begins")
			Input.action_press("move_forward")
		205:
			_shoot("03_world_shrinking")
		280:
			_shoot("04_duckling_after_spurt")
		420:
			_shoot("05_duckling_walking")
			Input.action_release("move_forward")
			get_tree().quit(0)


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [out_dir, name]
	img.save_png(path)
	print("shot ", ProjectSettings.globalize_path(path), " stage=", Globals.stage_name())
