class_name NPC
extends Area3D
## A talkable animal. Shows a prompt when the player is close; the Action key
## opens a short dialogue (design doc §7.5: animal sounds with brief subtitles,
## lines under 12 words). Emits [signal first_talk] once, for quest hooks.

signal first_talk(npc: NPC)
signal talked(npc: NPC)

@export var npc_name: String = "Nib"
@export var lines_first: PackedStringArray = ["Squeak?", "Oh. You're big. That's fine."]
@export var lines_repeat: PackedStringArray = ["Squeak."]
## Set by the scene when a quest for this NPC is complete.
var lines_override: PackedStringArray = []

var has_talked: bool = false
var _player_near: bool = false


func _ready() -> void:
	add_to_group("npc")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(node: Node3D) -> void:
	if node is Player:
		_player_near = true
		Globals.show_prompt("E   Talk to %s" % npc_name)


func _on_body_exited(node: Node3D) -> void:
	if node is Player:
		_player_near = false
		Globals.show_prompt("")


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or Globals.dialogue_active:
		return
	if event.is_action_pressed("action"):
		get_viewport().set_input_as_handled()
		talk()


func talk() -> void:
	var lines: PackedStringArray
	if not lines_override.is_empty():
		lines = lines_override
	elif not has_talked:
		lines = lines_first
	else:
		lines = lines_repeat
	Globals.show_prompt("")
	Globals.request_dialogue(npc_name, lines)
	var was_first := not has_talked
	has_talked = true
	await Globals.dialogue_finished
	if was_first:
		first_talk.emit(self)
	talked.emit(self)
	if _player_near:
		Globals.show_prompt("E   Talk to %s" % npc_name)
