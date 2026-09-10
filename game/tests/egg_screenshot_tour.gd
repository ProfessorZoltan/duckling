extends Node
## Captures the egg prologue: dark shell, cracks, the pop, and the pull-out.
##   xvfb-run -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 tests/egg_screenshot_tour.tscn -- --out=<dir>

var egg: EggPrologue
var frame: int = 0
var out_dir: String = "user://screenshots"


func _ready() -> void:
	Globals.start_in_egg = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var pond: Node = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	egg = pond.get_node("World/EggPrologue")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _peck() -> void:
	var ev := InputEventAction.new()
	ev.action = "jump"
	ev.pressed = true
	Input.parse_input_event(ev)


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		60:
			_shoot("01_inside_the_egg")
		100, 130, 160, 190:
			_peck()
		230:
			_shoot("02_four_cracks")
		260, 290, 320:
			_peck()
		350:
			_shoot("03_seven_cracks")
		380:
			_peck()
		400:
			_shoot("04_the_pop")
		470:
			_shoot("05_pulling_out")
		600:
			_shoot("06_hatched_beside_siblings")
		640:
			get_tree().quit(0)


func _shoot(name: String) -> void:
	var cracks := egg.cracks if is_instance_valid(egg) else -1
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("shot ", name, " cracks=", cracks)
