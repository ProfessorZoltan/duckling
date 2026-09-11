extends Node
## Autoload "Audio": music that follows the Heart, and one-shot sound effects.
##
## Two piano layers play at once and crossfade on [member Globals.heart]
## (design doc §10: one instrument at Heart 10, the full ensemble at 100; the
## v1 cut asks for a simple gray / recovering / full switch, which this is, as
## a continuous blend). The blend uses the same slow-out, quick-in timing as
## the colour, so the music drains with the world.
##
## Effects are pooled: [method play] for flat sounds, [method play_at] for a
## point in the world. Each name maps to a set of variants; one is chosen at
## random and pitched slightly, so repeats never sound identical.

## Emitted whenever a sound is triggered. Tests and debug overlays listen;
## nothing in the game needs it.
signal played(name: String)

const MUSIC := {
	"gray": "res://assets/audio/music/piano_gray.ogg",
	"warm": "res://assets/audio/music/piano_warm.ogg",
}

## name -> [files, base volume dB, pitch spread]
const SFX := {
	"peck": [["peck_1", "peck_2", "peck_3"], -4.0, 0.14],
	"shell_break": [["shell_break"], 0.0, 0.04],
	"splash": [["splash_1", "splash_2", "splash_3", "splash_4"], -5.0, 0.12],
	"quack": [["quack_1", "quack_2", "quack_3", "quack_4", "quack_5", "quack_6"], -7.0, 0.07],
	"squeak": [["squeak_1", "squeak_2", "squeak_3", "squeak_4", "squeak_5"], -8.0, 0.10],
	"pickup": [["pickup"], -9.0, 0.06],
	"flap": [["flap_1", "flap_2", "flap_3"], -8.0, 0.12],
	"hawk": [["hawk_pass"], -6.0, 0.05],
	"growth": [["growth_swell"], -3.0, 0.03],
	"muffled_call": [["muffled_call"], -3.0, 0.03],
}

const SFX_DIR := "res://assets/audio/sfx/"
const OPEN_HZ := 20500.0
const MUFFLED_HZ := 430.0
const POOL_SIZE := 12
const SILENT_DB := -60.0

## Seconds for the music to fall away, and to come back. Matched to HeartRegion.
@export var drain_time: float = 15.0
@export var recover_time: float = 3.0

var music_enabled: bool = true
## The most recent sound name, for debugging.
var last_played: String = ""
## 0 = fully gray, 1 = fully warm.
var blend: float = 1.0

var _players: Dictionary = {}
var _sfx: Array[AudioStreamPlayer] = []
var _sfx3d: Array[AudioStreamPlayer3D] = []
var _streams: Dictionary = {}
var _next: int = 0
var _next3d: int = 0
var _muffle: AudioEffectLowPassFilter
var _muffle_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in MUSIC:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = SILENT_DB
		var stream: AudioStream = load(MUSIC[key])
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		player.stream = stream
		add_child(player)
		_players[key] = player
	for i in POOL_SIZE:
		var flat := AudioStreamPlayer.new()
		flat.bus = "SFX"
		add_child(flat)
		_sfx.append(flat)
		var spatial := AudioStreamPlayer3D.new()
		spatial.bus = "SFX"
		spatial.unit_size = 6.0
		spatial.max_distance = 45.0
		add_child(spatial)
		_sfx3d.append(spatial)
	_install_muffle()
	blend = clampf(Globals.heart / 100.0, 0.0, 1.0)
	start_music()


## A low-pass across the music, for hearing the world through an eggshell.
## 0 is open, 1 is fully muffled.
func set_muffle(amount: float) -> void:
	if _muffle:
		_muffle.cutoff_hz = lerpf(OPEN_HZ, MUFFLED_HZ, clampf(amount, 0.0, 1.0))


func muffle_to(amount: float, seconds: float) -> void:
	if _muffle == null:
		return
	if _muffle_tween and _muffle_tween.is_valid():
		_muffle_tween.kill()
	_muffle_tween = create_tween()
	_muffle_tween.tween_property(_muffle, "cutoff_hz",
			lerpf(OPEN_HZ, MUFFLED_HZ, clampf(amount, 0.0, 1.0)), seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _install_muffle() -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus < 0:
		return
	_muffle = AudioEffectLowPassFilter.new()
	_muffle.cutoff_hz = OPEN_HZ
	AudioServer.add_bus_effect(bus, _muffle)


func start_music() -> void:
	if not music_enabled:
		return
	for key in _players:
		var player: AudioStreamPlayer = _players[key]
		if not player.playing:
			player.play()
	_apply_blend()


func stop_music() -> void:
	for key in _players:
		(_players[key] as AudioStreamPlayer).stop()


func _process(delta: float) -> void:
	var target := clampf(Globals.heart / 100.0, 0.0, 1.0)
	if not is_equal_approx(blend, target):
		var seconds := drain_time if target < blend else recover_time
		blend = move_toward(blend, target, delta / maxf(seconds, 0.01))
		_apply_blend()


func _apply_blend() -> void:
	# Equal-power, so the pair never dips in the middle of the crossfade.
	var warm := sin(blend * PI * 0.5)
	var gray := cos(blend * PI * 0.5)
	_set_volume("warm", warm)
	_set_volume("gray", gray)


func _set_volume(key: String, amount: float) -> void:
	var player: AudioStreamPlayer = _players.get(key)
	if player:
		player.volume_db = SILENT_DB if amount <= 0.001 else linear_to_db(amount)


## Play [param name] flat (no position). [param pitch] multiplies the variant's
## own random pitch, so a duckling can be the same quack an octave up.
func play(name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream := _pick(name)
	if stream == null:
		return
	var entry: Array = SFX[name]
	last_played = name
	played.emit(name)
	var player := _sfx[_next]
	_next = (_next + 1) % _sfx.size()
	player.stream = stream
	player.pitch_scale = maxf(0.05, pitch * randf_range(1.0 - entry[2], 1.0 + entry[2]))
	player.volume_db = entry[1] + volume_db
	player.play()


## Play [param name] at a point in the world.
func play_at(name: String, position: Vector3, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream := _pick(name)
	if stream == null:
		return
	var entry: Array = SFX[name]
	last_played = name
	played.emit(name)
	var player := _sfx3d[_next3d]
	_next3d = (_next3d + 1) % _sfx3d.size()
	player.stream = stream
	player.global_position = position
	player.pitch_scale = maxf(0.05, pitch * randf_range(1.0 - entry[2], 1.0 + entry[2]))
	player.volume_db = entry[1] + volume_db
	player.play()


func _pick(name: String) -> AudioStream:
	if not SFX.has(name):
		push_warning("Audio: no sound named '%s'" % name)
		return null
	var files: Array = SFX[name][0]
	var file: String = files[randi() % files.size()]
	if not _streams.has(file):
		var path := SFX_DIR + file + ".wav"
		_streams[file] = load(path) if ResourceLoader.exists(path) else null
	return _streams[file]
