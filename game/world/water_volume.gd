class_name WaterVolume
extends Area3D
## Marks a body of water. Put this node's origin at the water surface and give
## it a collision shape that extends below (and a little above) the surface.
## Entering it flips the [Player] into its swim state.


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(node: Node3D) -> void:
	if node is Player:
		(node as Player).enter_water(global_position.y)


func _on_body_exited(node: Node3D) -> void:
	if node is Player:
		(node as Player).exit_water()
