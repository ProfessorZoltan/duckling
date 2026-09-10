extends Node
## Autoload "Globals": the two numbers the whole game hangs off.
##
## - [member player_scale] drives model scale, camera boom, speeds, and the
##   collision capsule (design doc §7.2). The world stays fixed; the player grows.
## - [member heart] is the belonging / color meter (design doc §7.3). Nothing
##   reads it yet; P3 wires it to the WorldEnvironment.

signal stage_changed(new_stage: Stage)
signal player_scale_changed(new_scale: float)
signal heart_changed(new_heart: float)
## Something asked for a Growth Spurt. A GrowthSpurtDirector in the scene plays
## the cutscene; if none is listening, the stage advances instantly.
signal growth_spurt_requested
## Short on-screen message for the HUD (gate hints, stage announcements).
signal notice(text: String)

enum Stage { EGG, HATCHLING, DUCKLING, JUVENILE, FLEDGLING, YOUNG_SWAN, ADULT_SWAN }

## Player scale per growth stage (design doc §3).
const STAGE_SCALE: Dictionary = {
	Stage.EGG: 1.0,
	Stage.HATCHLING: 1.0,
	Stage.DUCKLING: 1.25,
	Stage.JUVENILE: 1.7,
	Stage.FLEDGLING: 2.3,
	Stage.YOUNG_SWAN: 3.0,
	Stage.ADULT_SWAN: 3.5,
}

var stage: Stage = Stage.HATCHLING:
	set(value):
		if value == stage:
			return
		stage = value
		player_scale = STAGE_SCALE[stage]
		stage_changed.emit(stage)

var player_scale: float = 1.0:
	set(value):
		if is_equal_approx(value, player_scale):
			return
		player_scale = value
		player_scale_changed.emit(player_scale)

## 0–100. Starts around 70, drops to ~10 after the Culvert, recovers monotonically.
var heart: float = 70.0:
	set(value):
		value = clampf(value, 0.0, 100.0)
		if is_equal_approx(value, heart):
			return
		heart = value
		heart_changed.emit(heart)

## Per-region Heart sub-values, keyed by region name. Global [member heart]
## will become the average of these once regions exist.
var region_hearts: Dictionary = {}


func advance_stage() -> void:
	if stage < Stage.ADULT_SWAN:
		stage = (stage + 1) as Stage


func regress_stage() -> void:
	if stage > Stage.HATCHLING:
		stage = (stage - 1) as Stage


func next_stage() -> Stage:
	return mini(stage + 1, Stage.ADULT_SWAN) as Stage


func stage_name(which: Stage = stage) -> String:
	return Stage.keys()[which].capitalize().replace("_", " ")


## Ask for a Growth Spurt (design doc §7.2). Story beats call this, never timers.
func request_growth_spurt() -> void:
	if stage >= Stage.ADULT_SWAN:
		return
	if growth_spurt_requested.get_connections().is_empty():
		advance_stage()
		notify("Growth spurt! You are a %s now." % stage_name())
	else:
		growth_spurt_requested.emit()


func notify(text: String) -> void:
	notice.emit(text)
