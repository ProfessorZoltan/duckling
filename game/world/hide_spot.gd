class_name HideSpot
extends Area3D
## Cover from the hawk (design doc §5 Hazards): under the reeds, under a log.
## While the player is inside, it counts as hidden.


func _ready() -> void:
	add_to_group("hide_spot")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(node: Node3D) -> void:
	if node is Player:
		(node as Player).enter_cover()


func _on_body_exited(node: Node3D) -> void:
	if node is Player:
		(node as Player).exit_cover()
