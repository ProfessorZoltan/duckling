extends CanvasLayer
## Prototype overlay: player state, stamina, airspeed, Heart, quest counters,
## a notice line, an interaction prompt, and a dialogue box. Hotkeys bump the
## growth stage ([ ]), play a Growth Spurt (G), or switch test scenes (F1 F2).

const SCENES := {
	"debug_scene_pond": "res://world/pond_greybox.tscn",
	"debug_scene_cliff": "res://world/cliff_test.tscn",
}

@export var player: Player

@onready var label: Label = $Label
@onready var notice_label: Label = $Notice
@onready var prompt_label: Label = $Prompt
@onready var dialogue_box: PanelContainer = $Dialogue
@onready var dialogue_speaker: Label = $Dialogue/VBox/Speaker
@onready var dialogue_text: Label = $Dialogue/VBox/Text

var _notice_timer: float = 0.0
var _lines: PackedStringArray = []
var _line_index: int = 0


func _ready() -> void:
	Globals.notice.connect(_on_notice)
	Globals.prompt.connect(_on_prompt)
	Globals.dialogue_requested.connect(_on_dialogue_requested)
	notice_label.text = ""
	prompt_label.text = ""
	dialogue_box.visible = false


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
	var heart_line := "Heart  %d" % int(Globals.heart)
	for region in Globals.region_hearts:
		heart_line += "   %s %d" % [region, int(Globals.region_hearts[region])]
	lines.append(heart_line)
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
		if hunt.pantry_started:
			lines.append("Seeds  %d / %d" % [hunt.seeds_collected, hunt.seeds_for_pantry])

	lines.append("")
	lines.append("Space flap/hop   W pull up   S dive   E talk   G growth spurt   [ ] stage   F1 pond   F2 cliff   Esc mouse")
	label.text = "\n".join(lines)


func _input(event: InputEvent) -> void:
	if dialogue_box.visible and event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()


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


func _on_prompt(text: String) -> void:
	prompt_label.text = text


func _on_dialogue_requested(speaker: String, lines: PackedStringArray) -> void:
	_lines = lines
	_line_index = 0
	dialogue_speaker.text = speaker
	dialogue_box.visible = true
	if player:
		player.frozen = true
	_show_line()


func _show_line() -> void:
	dialogue_text.text = _lines[_line_index] if _line_index < _lines.size() else ""


func _advance_dialogue() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		dialogue_box.visible = false
		if player:
			player.frozen = false
		Globals.end_dialogue()
	else:
		_show_line()
