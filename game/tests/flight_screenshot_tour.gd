extends Node
## Captures screenshots of the cliff flight course. Not a test.
##   xvfb-run -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 tests/flight_screenshot_tour.tscn -- --out=<dir>

var player: Player
var frame: int = 0
var out_dir: String = "user://screenshots"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var scene: Node = load("res://world/cliff_test.tscn").instantiate()
	add_child(scene)
	player = scene.get_node("Player")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		30:
			_shoot("01_cliff_top")
			Input.action_press("move_forward")
		150:
			Input.action_release("move_forward")
			Input.action_press("jump")
		152:
			Input.action_release("jump")
		230:
			_shoot("02_gliding_off_the_ledge")
		260:
			Input.action_press("move_back")
		330:
			_shoot("03_dive")
			Input.action_release("move_back")
			Input.action_press("move_forward")
		400:
			_shoot("04_pull_up")
			Input.action_release("move_forward")
			Input.action_press("move_left")
		520:
			_shoot("05_banking_turn")
			Input.action_release("move_left")
		540:
			get_tree().quit(0)


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [out_dir, name]
	img.save_png(path)
	print("shot ", ProjectSettings.globalize_path(path), " state=", player.state_name())
