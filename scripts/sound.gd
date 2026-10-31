extends Node

var enabled := true
var voices: Array[AudioStreamPlayer] = []
var sounds := {}
var music: AudioStreamPlayer

func _ready() -> void:
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -16
		add_child(voice)
		voices.append(voice)
	sounds["jump"] = tone([523.25, 659.25], 0.15)
	sounds["double"] = tone([783.99, 1046.5], 0.2)
	sounds["land"] = tone([329.63, 392.0], 0.12)
	sounds["spring"] = tone([392.0, 523.25, 783.99], 0.32)
	sounds["checkpoint"] = tone([523.25, 659.25, 783.99, 1046.5], 0.65)
	sounds["fall"] = tone([392.0, 293.66, 261.63], 0.4)
	sounds["win"] = tone([523.25, 659.25, 783.99, 1046.5, 1318.5], 1.2)
	music = AudioStreamPlayer.new()
	music.stream = load("res://assets/roomtone.wav")
	music.volume_db = -25
	add_child(music)
	music.play()

func tone(notes: Array, duration: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples := int(duration * stream.mix_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / stream.mix_rate
		var index := mini(int(t / duration * notes.size()), notes.size() - 1)
		var local := fmod(t, duration / notes.size())
		var envelope := minf(local * 100.0, 1.0) * exp(-local * 12) * minf((duration - t) * 30, 1)
		var value := (sin(TAU * notes[index] * t) * 0.8 + sin(TAU * notes[index] * 2 * t) * 0.12) * envelope
		data.encode_s16(i * 2, int(value * 14500))
	stream.data = data
	return stream

func play_sound(id: String) -> void:
	if not enabled:
		return
	for voice in voices:
		if not voice.playing:
			voice.stream = sounds[id]
			voice.play()
			break

func set_enabled(value: bool) -> void:
	enabled = value
	music.stream_paused = not enabled
	if not enabled:
		for voice in voices:
			voice.stop()
