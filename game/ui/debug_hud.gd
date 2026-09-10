extends CanvasLayer
## Prototype-only overlay: shows player state and lets you bump the growth
## stage with [ and ] to check that camera and speed scale nicely (P2 prep).

@export var player: Player

@onready var label: Label = $Label


func _process(_delta: float) -> void:
	if player == null:
		label.text = "No player assigned"
		return
	var planar := Vector3(player.velocity.x, 0.0, player.velocity.z)
	label.text = "State  %s\nStage  %s  (scale %.2f)\nHeart  %d\nSpeed  %.2f m/s\n\n[ / ]  change stage    Esc  release mouse" % [
		player.state_name(),
		Globals.Stage.keys()[Globals.stage],
		Globals.player_scale,
		int(Globals.heart),
		planar.length(),
	]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_stage_up"):
		Globals.advance_stage()
	elif event.is_action_pressed("debug_stage_down"):
		Globals.regress_stage()
