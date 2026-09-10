class_name SizeGate
extends StaticBody3D
## A gap that only some sizes fit through (design doc §7.2): a simple scale
## check, not a physical fit. Its collision shapes block the player while the
## player is outside [min_scale, max_scale], and vanish once they fit.
##
## A reed wall uses [member min_scale] (too small to push through). The culvert
## the siblings escape through uses [member max_scale] (too big to follow).

## Player must be at least this big. 0 means no minimum.
@export var min_scale: float = 0.0
## Player must be at most this big. Leave huge for no maximum.
@export var max_scale: float = 1000.0
## Shown when the player bumps the closed gate.
@export var closed_hint: String = "Too small to push through."
## Optional visual (reeds, brush) to wobble on a bump.
@export var wobble_target: Node3D
@export var wobble_degrees: float = 12.0

var _hint_cooldown: float = 0.0
var _wobbling: bool = false


func _ready() -> void:
	Globals.player_scale_changed.connect(_refresh)
	_refresh(Globals.player_scale)


func _process(delta: float) -> void:
	_hint_cooldown = maxf(_hint_cooldown - delta, 0.0)


func is_open(scale_value: float = Globals.player_scale) -> bool:
	return scale_value >= min_scale and scale_value <= max_scale


func _refresh(scale_value: float) -> void:
	var open := is_open(scale_value)
	for child in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = open


## Called by the player when it walks into the closed gate.
func bump() -> void:
	if _hint_cooldown <= 0.0:
		_hint_cooldown = 2.5
		Globals.notify(closed_hint)
	if wobble_target and not _wobbling:
		_wobbling = true
		var rest := wobble_target.rotation
		var tween := create_tween()
		tween.tween_property(wobble_target, "rotation:z", rest.z + deg_to_rad(wobble_degrees), 0.12)
		tween.tween_property(wobble_target, "rotation:z", rest.z - deg_to_rad(wobble_degrees * 0.5), 0.18)
		tween.tween_property(wobble_target, "rotation:z", rest.z, 0.25)
		tween.tween_callback(func() -> void: _wobbling = false)
