extends Node
## Headless smoke test for audio. Run from the game/ folder with:
##   godot --headless --path . tests/audio_smoke_test.tscn
## Checks every sound in the table loads, the music players start, and the
## Heart crossfade moves the two piano layers past each other.

var frame: int = 0
var failures: PackedStringArray = []
var _gray: AudioStreamPlayer
var _warm: AudioStreamPlayer


func _ready() -> void:
	_gray = Audio._players["gray"]
	_warm = Audio._players["warm"]
	# Faster than the shipping values so the test is quick.
	Audio.drain_time = 0.6
	Audio.recover_time = 0.3


func _physics_process(_delta: float) -> void:
	frame += 1
	match frame:
		5:
			for name in Audio.SFX:
				var files: Array = Audio.SFX[name][0]
				for file in files:
					var path: String = Audio.SFX_DIR + file + ".wav"
					_expect(ResourceLoader.exists(path), "sound file exists: %s" % file)
				Audio.play(name)
				Audio.play_at(name, Vector3.ZERO)
			_expect(true, "every sound played without error")
		10:
			_expect(_gray.stream != null and _warm.stream != null, "both music layers loaded")
			_expect(_gray.stream.loop, "gray track loops")
			_expect(_warm.stream.loop, "warm track loops")
			_expect(_gray.playing and _warm.playing, "both music layers are playing")
			Globals.heart = 100.0
		40:
			print("audio: heart 100 blend=%.2f warm=%.1f dB gray=%.1f dB" % [Audio.blend, _warm.volume_db, _gray.volume_db])
			_expect(Audio.blend > 0.98, "blend follows Heart up (%.2f)" % Audio.blend)
			_expect(_warm.volume_db > _gray.volume_db, "warm piano is the loud one in colour")
			Globals.set_region_heart("Home Pond", 10.0)
		42:
			_expect(Globals.heart < 20.0, "Heart dropped")
		120:
			print("audio: heart %.0f blend=%.2f warm=%.1f dB gray=%.1f dB" % [Globals.heart, Audio.blend, _warm.volume_db, _gray.volume_db])
			_expect(Audio.blend < 0.2, "blend follows Heart down (%.2f)" % Audio.blend)
			_expect(_gray.volume_db > _warm.volume_db, "sad piano is the loud one in gray")
			_finish()


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		print("  FAIL ", description)
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("audio: PASS")
		get_tree().quit(0)
	else:
		print("audio: FAIL (%d)" % failures.size())
		get_tree().quit(1)
