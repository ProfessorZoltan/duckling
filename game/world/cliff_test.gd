extends Node3D
## P4 flight test course. Forces a flying stage, counts rings, times the run.

@export var start_stage: Globals.Stage = Globals.Stage.FLEDGLING

var rings_total: int = 0
var rings_passed: int = 0
var run_time: float = 0.0
var _running: bool = false


func _ready() -> void:
	add_to_group("flight_course")
	Globals.stage = start_stage
	for ring in get_tree().get_nodes_in_group("flight_ring"):
		rings_total += 1
		(ring as FlightRing).passed.connect(_on_ring_passed)


func _process(delta: float) -> void:
	if _running:
		run_time += delta


func _on_ring_passed(_ring: FlightRing) -> void:
	if rings_passed == 0:
		_running = true
		run_time = 0.0
	rings_passed += 1
	if rings_passed >= rings_total:
		_running = false
		print("Course complete in %.1fs" % run_time)


func reset_course() -> void:
	for ring in get_tree().get_nodes_in_group("flight_ring"):
		(ring as FlightRing).reset()
	rings_passed = 0
	run_time = 0.0
	_running = false
