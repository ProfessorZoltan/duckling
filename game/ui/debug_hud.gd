extends CanvasLayer
## Prototype-only overlay: player state, stamina, airspeed, ring course, and
## hotkeys to bump the growth stage ([ ]) or switch test scenes (F1 F2).

const SCENES := {
	"debug_scene_pond": "res://world/pond_greybox.tscn",
	"debug_scene_cliff": "res://world/cliff_test.tscn",
}

@export var player: Player

@onready var label: Label = $Label
@onready var notice_label: Label = $Notice

var _notice_timer: float = 0.0


func _ready() -> void:
	Globals.notice.connect(_on_notice)
	notice_label.text = ""


func _process(delta: float) -> void:
	_notice_timer = maxf(_notice_timer - delta, 0.0)
	notice_label.modulate.a = clampf(_notice_timer, 0.0, 1.0)
	if player == null:
		label.text = "No player assigned"
		return
	var planar := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var lines: PackedStringArray = []
	lines.append("State  %s" % player.state_name())
	lines.append("Stage  %s  (scale %.2f)" % [Globals.Stage.keys()[Globals.stage], Globals.player_scale])
	lines.append("Heart  %d" % int(Globals.heart))
	lines.append("Stamina  %d / %d" % [int(player.stamina), int(player.max_stamina)])
	if player.state == Player.State.FLY:
		lines.append("Air speed  %.1f m/s   pitch %d°" % [player.air_speed, int(rad_to_deg(player.pitch))])
	else:
		lines.append("Speed  %.2f m/s" % planar.length())

	var course := get_tree().get_first_node_in_group("flight_course")
	if course:
		lines.append("Rings  %d / %d   %.1fs" % [course.rings_passed, course.rings_total, course.run_time])
	var hunt := get_tree().get_first_node_in_group("bug_hunt")
	if hunt:
		lines.append("Bugs  %d / %d" % [hunt.bugs_collected, hunt.bugs_total])

	lines.append("")
	lines.append("Space flap/hop   W pull up   S dive   G growth spurt   [ ] stage   F1 pond   F2 cliff   Esc mouse")
	label.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_growth_spurt"):
		Globals.request_growth_spurt()
	elif event.is_action_pressed("debug_stage_up"):
		Globals.advance_stage()
	elif event.is_action_pressed("debug_stage_down"):
		Globals.regress_stage()
	else:
		for action in SCENES:
			if event.is_action_pressed(action):
				get_tree().change_scene_to_file(SCENES[action])


func _on_notice(text: String) -> void:
	notice_label.text = text
	_notice_timer = 3.5
