extends Node
## Captures Act 1 and 2: following the family, the hawk's shadow, hiding in
## the reeds, and the family leaving through the culvert.
##   xvfb-run -s "-screen 0 1600x900x24" godot --path . --rendering-driver opengl3 tests/act1_screenshot_tour.tscn -- --out=<dir>

var player: Player
var pond: Node
var frame: int = 0
var out_dir: String = "user://screenshots"


func _ready() -> void:
	Globals.start_in_egg = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	pond = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	player = pond.get_node("Player")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pond.hawk.warning_seconds = 1.0
	pond.hawk.cross_seconds = 3.0


func _place(pos: Vector3, yaw: float) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.camera_pivot.rotation.y = yaw
	player.body.rotation.y = yaw


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		30:
			_place(Vector3(1.0, 0.1, 13.5), 0.0)
		90:
			_shoot("01_keep_up")
		100:
			player.global_position = pond.flock.mother.global_position + Vector3(1.0, 0.1, 1.5)
		250:
			_shoot("02_following_marra_across_the_pond")
			pond.flock.stop()
			pond.flock.route_finished.emit()
			for bug in get_tree().get_nodes_in_group("pickup_bug"):
				if pond.bugs_collected >= 5:
					break
				player.global_position = (bug as Node3D).global_position + Vector3(0, 0.1, 0)
				await get_tree().physics_frame
				await get_tree().physics_frame
			_place(Vector3(0.0, 0.1, 11.0), 0.0)
		420:
			pond.hawk.active = true
			pond.hawk.start_pass()
		540:
			_shoot("03_the_shadow_comes")
		620:
			var spot: Node3D = get_tree().get_first_node_in_group("hide_spot")
			_place(spot.global_position + Vector3(0, -0.5, 0), 0.0)
		700:
			pond.hawk.start_pass()
		770:
			_shoot("04_hiding_in_the_reeds")
		900:
			pond.hawk.hides = 3
			pond._on_all_hidden()
		1320:
			_place(Vector3(-8.0, 0.1, 3.0), PI / 2)
		1600:
			_shoot("05_the_family_leaves")
		1900:
			_shoot("06_alone")
		1920:
			get_tree().quit(0)


func _shoot(name: String) -> void:
	var act: int = pond.act
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("shot ", name, " act=", act)
