class_name Soundscape
extends Node

var enabled = true
var player: AudioStreamPlayer
var ambience: AudioStreamPlayer
var rainfall: AudioStreamPlayer
var effects: Dictionary = {}

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.max_polyphony = 4
	add_child(player)
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	var wav = load("res://assets/phase2/wind.wav") as AudioStreamWAV
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = 132300
	ambience.stream = wav
	ambience.play()
	rainfall = AudioStreamPlayer.new()
	add_child(rainfall)
	var rain = load("res://assets/phase2/rain-loop.wav") as AudioStreamWAV
	rain.loop_mode = AudioStreamWAV.LOOP_FORWARD
	rain.loop_end = 132300
	rainfall.stream = rain
	for key in ["water", "forest", "mountain", "wildlife", "rain", "bless", "discovery", "button"]:
		effects[key] = load("res://assets/" + key + ".wav")
	for key in ["step","switch","door","trap_warning","trap_active","swing","impact","relic"]:
		effects["sanctuary_"+key]=load("res://assets/adventure/audio/"+key+".wav")

func sanctuary(key: String) -> void:
	if not enabled or not effects.has("sanctuary_"+key):return
	player.stream=effects["sanctuary_"+key];player.play()

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
	player.stream = effects[names[clampi(power, 0, 6)]]
	player.play()

func button_sound() -> void:
	if not enabled: return
	player.stream = effects.button
	player.volume_db = -8
	player.play()
	player.volume_db = 0

func weather(raining: bool) -> void:
	if raining and enabled and not rainfall.playing: rainfall.play()
	if (not raining or not enabled) and rainfall.playing: rainfall.stop()

func set_enabled(value: bool) -> void:
	enabled = value
	ambience.volume_db = 0 if value else -80
	if not value: rainfall.stop()
