class_name FlightRing
extends Area3D
## A ring to fly through. Emits [signal passed] once, the first time a flying
## player crosses it, and tints itself so the course reads at a glance.

signal passed(ring: FlightRing)

@export var todo_color: Color = Color(0.95, 0.75, 0.25)
@export var done_color: Color = Color(0.35, 0.85, 0.45)

var is_passed: bool = false

@onready var torus: CSGTorus3D = $Torus


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_tint(todo_color)


func _on_body_entered(node: Node3D) -> void:
	if is_passed or not (node is Player):
		return
	if (node as Player).state != Player.State.FLY:
		return
	is_passed = true
	_tint(done_color)
	passed.emit(self)


func reset() -> void:
	is_passed = false
	_tint(todo_color)


func _tint(color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	torus.material = mat
