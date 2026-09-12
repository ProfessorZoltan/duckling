extends Node
## Guards the patterns that behave differently in an exported build than they do
## in the editor, and so slip past every other test here. Run from game/ with:
##   godot --headless --path . tests/export_safety_test.tscn
##
## The one that bit us: `@export var x: PackedStringArray = ["a", "b"]`. A bare
## Array-literal default makes an exported build discard whatever the scene set
## and fall back to the script's default. Text scenes take a more forgiving load
## path, so the editor and every headless test look correct while the shipped
## build quietly loses the data — the whole family read Nib's placeholder lines
## in the first .exe. Writing `PackedStringArray([...])` keeps the scene value.

const PACKED_TYPES := [
	"PackedStringArray", "PackedInt32Array", "PackedInt64Array",
	"PackedFloat32Array", "PackedFloat64Array", "PackedByteArray",
	"PackedVector2Array", "PackedVector3Array", "PackedColorArray",
]

var failures: PackedStringArray = PackedStringArray()


func _ready() -> void:
	var scripts := _all_scripts("res://")
	print("export safety: scanning %d scripts" % scripts.size())
	for path in scripts:
		_check_script(path)
	_check_family_dialogue()
	_finish()


func _all_scripts(root: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return found
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var path := root.path_join(name)
		if dir.current_is_dir():
			found.append_array(_all_scripts(path))
		elif name.ends_with(".gd"):
			found.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	return found


func _check_script(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var line_number := 0
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		line_number += 1
		if not line.begins_with("@export"):
			continue
		for type in PACKED_TYPES:
			# `: PackedStringArray = [` — a literal default, which an exported
			# build will prefer over the value the scene stored.
			var marker := ": %s = [" % type
			if line.contains(marker):
				failures.append("%s:%d  %s default is an Array literal; write %s([...])"
					% [path, line_number, type, type])


## The bug this file exists for, checked from the other end: the family must
## still be five different voices, not five copies of one placeholder.
func _check_family_dialogue() -> void:
	var scene: PackedScene = load("res://world/pond_greybox.tscn")
	var state := scene.get_state()
	var seen: Dictionary = {}
	for i in state.get_node_count():
		var node_name := String(state.get_node_name(i))
		if not node_name in ["Marra", "Pip", "Dab", "Quill", "Sedge"]:
			continue
		for p in state.get_node_property_count(i):
			if String(state.get_node_property_name(i, p)) != "lines_first":
				continue
			var lines: PackedStringArray = state.get_node_property_value(i, p)
			if lines.is_empty():
				failures.append("%s has no lines_first in the scene" % node_name)
			elif seen.has(lines[0]):
				failures.append("%s opens with the same line as %s" % [node_name, seen[lines[0]]])
			else:
				seen[lines[0]] = node_name
	if seen.size() != 5:
		failures.append("expected 5 family members with lines, found %d" % seen.size())


func _finish() -> void:
	if failures.is_empty():
		print("export safety: PASS")
		get_tree().quit(0)
	else:
		for f in failures:
			print("  FAIL ", f)
		print("export safety: FAIL (%d)" % failures.size())
		get_tree().quit(1)
