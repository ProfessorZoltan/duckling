extends Node
## Screenshot tour of the culvert beat: the pipe from the pond side as a
## Hatchling, the bug waiting on the west bank, and the same mouth once the
## player is a Duckling and it is closed to them.

const SHOTS := [
	{"name": "01_pipe_from_the_pond", "stage": Globals.Stage.HATCHLING,
		"at": Vector3(-11.0, 0.1, 0.0), "eye": Vector3(-8.0, 1.6, 0.0)},
	{"name": "02_bug_on_the_west_bank", "stage": Globals.Stage.HATCHLING,
		"at": Vector3(-20.5, 0.1, 1.0), "eye": Vector3(-17.6, 1.5, 2.6)},
	{"name": "03_shut_to_a_duckling", "stage": Globals.Stage.DUCKLING,
		"at": Vector3(-12.2, 0.1, 0.0), "eye": Vector3(-9.4, 1.7, 1.4)},
]

var out_dir: String = "/tmp/culvert"


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out_dir = argument.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out_dir)
	Globals.start_in_egg = false
	var pond: Node = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	var player: Player = pond.get_node("Player")
	await get_tree().physics_frame

	var camera := Camera3D.new()
	add_child(camera)
	camera.fov = 62.0

	for shot in SHOTS:
		Globals.stage = shot["stage"]
		player.global_position = shot["at"]
		player.velocity = Vector3.ZERO
		await get_tree().physics_frame
		camera.global_position = shot["eye"]
		camera.look_at(shot["at"] + Vector3(0.0, 0.25, 0.0))
		camera.make_current()
		for _i in 12:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("%s/%s.png" % [out_dir, shot["name"]])
		print("shot ", shot["name"])
	get_tree().quit(0)
