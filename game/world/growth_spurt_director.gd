class_name GrowthSpurtDirector
extends Node
## Plays the Growth Spurt cutscene (design doc §7.2).
##
## The fantasy is "the world shrinks". Mechanically the player grows, but for
## 2.5 seconds we let the player see it: freeze input, tween [member world]
## down around the player's feet, then snap the world back to 1.0 and bump the
## stage in the same frame. Because the camera boom and player scale both key
## off PlayerScale, the swap is seamless: what you see the moment before and
## after is identical, and only the numbers changed underneath.
##
## Everything that should shrink (terrain, water, props, NPCs) must live under
## [member world]. The player, lights and sky must not.

@export var world: Node3D
@export var player: Player
@export var duration: float = 2.5
@export var flash_color: Color = Color(1.0, 0.98, 0.9, 0.55)

var playing: bool = false

var _flash: ColorRect


func _ready() -> void:
	Globals.growth_spurt_requested.connect(play)
	_build_flash()


func play() -> void:
	if playing or world == null or player == null:
		return
	if Globals.stage >= Globals.Stage.ADULT_SWAN:
		return
	playing = true

	var from_stage := Globals.stage
	var to_stage := Globals.next_stage()
	var shrink: float = Globals.STAGE_SCALE[from_stage] / Globals.STAGE_SCALE[to_stage]
	var pivot := player.global_position
	var body_rest := player.body.scale

	player.frozen = true
	Audio.play("growth")

	var tween := create_tween().set_parallel(true)
	# The world shrinks around the duck's feet.
	tween.tween_method(
		func(t: float) -> void: _set_world_scale(pivot, lerpf(1.0, shrink, t)),
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	# A soft flash at the start.
	_flash.color = flash_color
	tween.tween_property(_flash, "color:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# The duck puffs up and settles, so the growth reads on the body too.
	var puff := create_tween()
	puff.tween_property(player.body, "scale", body_rest * 1.18, duration * 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	puff.tween_property(player.body, "scale", body_rest, duration * 0.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	# Swap: world back to 1.0, player to the new stage, all in one frame.
	_set_world_scale(pivot, 1.0)
	Globals.stage = to_stage
	player.frozen = false
	playing = false
	Globals.notify("Growth spurt! You are a %s now." % Globals.stage_name())


func _set_world_scale(pivot: Vector3, k: float) -> void:
	world.scale = Vector3.ONE * k
	world.position = pivot * (1.0 - k)


func _build_flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	_flash = ColorRect.new()
	_flash.color = Color(flash_color, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_flash)
	add_child(layer)
