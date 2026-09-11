class_name NPC
extends Area3D
## A talkable animal. Registers with the player while in range; the player
## picks the nearest NPC, shows the prompt, and calls [method talk] on E
## (design doc §7.5: animal sounds with brief subtitles, lines under 12 words).
## Emits [signal first_talk] once, for quest hooks.

signal first_talk(npc: NPC)
signal talked(npc: NPC)

@export var npc_name: String = "Nib"
@export var lines_first: PackedStringArray = ["Squeak?", "Oh. You're big. That's fine."]
@export var lines_repeat: PackedStringArray = ["Squeak."]
## Set by the scene when a quest for this NPC is complete.
var lines_override: PackedStringArray = []

var has_talked: bool = false
var talking: bool = false


func _ready() -> void:
	add_to_group("npc")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(node: Node3D) -> void:
	if node is Player:
		(node as Player).enter_talk_range(self)


func _on_body_exited(node: Node3D) -> void:
	if node is Player:
		(node as Player).exit_talk_range(self)


func talk(player: Player = null) -> void:
	if talking or Globals.dialogue_active:
		return
	talking = true
	var lines: PackedStringArray
	if not lines_override.is_empty():
		lines = lines_override
	elif not has_talked:
		lines = lines_first
	else:
		lines = lines_repeat
	if player:
		_face(player.global_position)
	Globals.request_dialogue(npc_name, lines)
	var was_first := not has_talked
	has_talked = true
	await Globals.dialogue_finished
	talking = false
	if was_first:
		first_talk.emit(self)
	talked.emit(self)


func _face(target: Vector3) -> void:
	var d := target - global_position
	d.y = 0.0
	if d.length() > 0.05:
		var tween := create_tween()
		tween.tween_property(self, "rotation:y", lerp_angle(rotation.y, atan2(-d.x, -d.z), 1.0), 0.25)
