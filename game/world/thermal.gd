class_name Thermal
extends Area3D
## A rising column of air. A flying [Player] inside it gains [member lift]
## metres per second of free height. Ground states ignore it.

@export var lift: float = 5.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(node: Node3D) -> void:
	if node is Player:
		(node as Player).enter_thermal(lift)


func _on_body_exited(node: Node3D) -> void:
	if node is Player:
		(node as Player).exit_thermal(lift)
