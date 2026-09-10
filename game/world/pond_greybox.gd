extends Node3D
## Home Pond grey-box. Counts water bugs; a full belly triggers Growth Spurt 1
## (stand-in for the doc's M3/M4 beats until real quests exist).

## Bugs needed for the first Growth Spurt. The rest are bonus snacks.
@export var bugs_for_spurt: int = 5

var bugs_total: int = 0
var bugs_collected: int = 0
var _spurt_fired: bool = false


func _ready() -> void:
	add_to_group("bug_hunt")
	for bug in get_tree().get_nodes_in_group("water_bug"):
		bugs_total += 1
		(bug as WaterBug).collected.connect(_on_bug_collected)


func _on_bug_collected(_bug: WaterBug) -> void:
	bugs_collected += 1
	if bugs_collected >= bugs_for_spurt and not _spurt_fired and Globals.stage == Globals.Stage.HATCHLING:
		_spurt_fired = true
		Globals.notify("Full belly. Something is happening...")
		await get_tree().create_timer(1.2).timeout
		Globals.request_growth_spurt()
	elif bugs_collected < bugs_for_spurt:
		Globals.notify("Yum. %d more." % (bugs_for_spurt - bugs_collected))
