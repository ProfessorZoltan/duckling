class_name WaterBug
extends Area3D
## A snack. Bobs in place; collected when the player touches it.

signal collected(bug: WaterBug)

@export var bob_height: float = 0.05
@export var bob_speed: float = 3.0

var _rest_y: float
var _time: float = randf() * TAU


func _ready() -> void:
	add_to_group("water_bug")
	_rest_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta * bob_speed
	position.y = _rest_y + sin(_time) * bob_height
	rotation.y += delta * 1.5


func _on_body_entered(node: Node3D) -> void:
	if node is Player:
		collected.emit(self)
		queue_free()
