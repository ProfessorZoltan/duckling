extends Node
## Captures a few screenshots of the pond for sharing. Not a test.
##   xvfb-run -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 tests/screenshot_tour.tscn
## Writes PNGs to user://screenshots/ (override with --out=<dir> after "--").

var player: Player
var frame: int = 0
var out_dir: String = "user://screenshots"


func _ready() -> void:
	Globals.start_in_egg = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var pond: Node = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	player = pond.get_node("Player")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		30:
			_shoot("01_spawn_at_nest")
			Input.action_press("move_forward")
		130:
			_shoot("02_wobble_walk_to_shore")
		330:
			_shoot("03_paddling")
		340:
			Globals.stage = Globals.Stage.JUVENILE
		420:
			_shoot("04_juvenile_scale")
			Input.action_release("move_forward")
			Input.action_press("move_right")
		600:
			_shoot("05_lily_pads")
			Input.action_release("move_right")
		620:
			get_tree().quit(0)


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [out_dir, name]
	img.save_png(path)
	print("shot ", ProjectSettings.globalize_path(path), " state=", player.state_name())
