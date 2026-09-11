extends Node
## Headless smoke test for P3 Heart. Run from the game/ folder with:
##   godot --headless --path . tests/heart_smoke_test.tscn
## Grows to Duckling, watches the siblings leave and the pond drain to gray,
## meets Nib (dialogue), collects eight seeds, and checks the pond recolors.

var player: Player
var pond: Node
var region: HeartRegion
var env: WorldEnvironment
var grass: StandardMaterial3D
var grass_original: Color
var frame: int = 0
var failures: PackedStringArray = []


func _ready() -> void:
	Globals.start_in_egg = false
	pond = load("res://world/pond_greybox.tscn").instantiate()
	add_child(pond)
	player = pond.get_node("Player")
	region = pond.get_node("HeartRegion")
	env = pond.get_node("WorldEnvironment")
	grass = pond.get_node("World/Terrain/Ground").material
	grass_original = region.original_albedo(grass)


func _saturation(c: Color) -> float:
	return c.s


## Input.action_press only sets polling state; dialogue listens for events.
func _press_action() -> void:
	var ev := InputEventAction.new()
	ev.action = "action"
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = "action"
	up.pressed = false
	Input.parse_input_event(up)


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		10:
			_expect(is_equal_approx(Globals.heart, 70.0), "starts at Heart 70 (got %.0f)" % Globals.heart)
			_expect(Globals.region_hearts.has("Home Pond"), "Home Pond region registered")
			_expect(_saturation(grass.albedo_color) > 0.1, "grass has color at Heart 70")
			Globals.stage = Globals.Stage.DUCKLING
		30:
			_expect(pond.siblings_gone, "siblings start leaving after the spurt")
		2600:
			print("heart: frame 2600 heart=%.0f displayed=%.0f grass=%s" % [Globals.heart, region.displayed_heart, grass.albedo_color])
			_expect(is_equal_approx(Globals.heart, 10.0), "pond dropped to Heart 10 after the culvert (got %.0f)" % Globals.heart)
			_expect(is_equal_approx(region.displayed_heart, 10.0), "region blend finished (displayed %.0f)" % region.displayed_heart)
			_expect(_saturation(grass.albedo_color) < 0.08, "grass is nearly gray (sat %.2f)" % _saturation(grass.albedo_color))
			_expect(env.environment.adjustment_saturation < 0.7, "post-process desaturated (%.2f)" % env.environment.adjustment_saturation)
			var sib: Node3D = pond.flock.siblings[0]
			_expect(sib.global_position.x < -19.0, "sibling reached the far side (x=%.1f)" % sib.global_position.x)
			_expect(not pond.flock.mother.visible, "Marra flew off")
			# Step up to Nib (talk radius 1.6 m).
			player.global_position = Vector3(24.5, 0.1, 1.8)
		2660:
			_press_action()
		2662:
			_expect(Globals.dialogue_active, "E near Nib opens dialogue")
			_expect(player.frozen, "player frozen during dialogue")
		2680:
			_press_action()
		2700:
			_press_action()
		2720:
			_press_action()
		2740:
			_press_action()
		2760:
			_expect(not Globals.dialogue_active, "dialogue closed after four lines")
			_expect(not player.frozen, "player unfrozen after dialogue")
			_expect(is_equal_approx(Globals.heart, 35.0), "meeting Nib gave +25 Heart (got %.0f)" % Globals.heart)
			_expect(pond.pantry_started, "Nib's Pantry started")
		2800:
			# Vacuum up the seeds by teleporting onto each one.
			for seed in get_tree().get_nodes_in_group("pickup_seed"):
				player.global_position = (seed as Node3D).global_position + Vector3(0, 0.1, 0)
				await get_tree().physics_frame
				await get_tree().physics_frame
		2860:
			print("heart: frame 2860 seeds=%d heart=%.0f" % [pond.seeds_collected, Globals.heart])
			_expect(pond.seeds_collected == 8, "collected all eight seeds (got %d)" % pond.seeds_collected)
			_expect(pond.pantry_done, "pantry complete")
			_expect(is_equal_approx(Globals.heart, 100.0), "pantry restored Heart to 100 (got %.0f)" % Globals.heart)
		3200:
			print("heart: frame 3200 displayed=%.0f grass=%s original=%s" % [region.displayed_heart, grass.albedo_color, grass_original])
			_expect(grass.albedo_color.is_equal_approx(grass_original), "grass color fully restored")
			_expect(env.environment.adjustment_saturation > 1.0, "post-process back to warm (%.2f)" % env.environment.adjustment_saturation)
			_finish()


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		print("  FAIL ", description)
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("heart: PASS")
		get_tree().quit(0)
	else:
		print("heart: FAIL (%d)" % failures.size())
		get_tree().quit(1)
