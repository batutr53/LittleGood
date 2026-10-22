class_name Soundscape
extends Node

var enabled = true
var player: AudioStreamPlayer
var ambience: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	var wav = make_tone(110, 3.0, 0.025, true)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = 66150
	ambience.stream = wav
	ambience.play()

func make_tone(freq: float, seconds: float, volume: float, wind: bool = false) -> AudioStreamWAV:
	var data = PackedByteArray()
	data.resize(int(seconds * 22050) * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 77
	var smooth = 0.0
	for i in range(data.size() / 2):
		var t = i / 22050.0
		smooth = lerpf(smooth, rng.randf_range(-1, 1), 0.08)
		var sample = (smooth * 0.6 + sin(t * TAU * freq) * 0.1) if wind else (sin(t * TAU * freq) + sin(t * TAU * freq * 1.5) * 0.3) * exp(-t * 7)
		data.encode_s16(i * 2, int(clampf(sample * volume, -1, 1) * 32767))
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.data = data
	return wav

func chime(power: int = 0) -> void:
	if not enabled: return
	var names = ["water", "forest", "mountain", "wildlife", "rain", "bless", "discovery"]
	var path = "res://assets/" + names[clampi(power, 0, 6)] + ".wav"
	player.stream = load(path) if ResourceLoader.exists(path) else make_tone(330 + power * 70, 0.6, 0.15)
	player.play()

func set_enabled(value: bool) -> void:
	enabled = value
	ambience.volume_db = 0 if value else -80
