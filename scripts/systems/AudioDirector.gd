extends Node
class_name HearthwoodAudioDirector

const MUSIC_PATHS: Dictionary = {
	"forest": "res://assets/audio/music/forest.wav",
	"village": "res://assets/audio/music/village.wav",
	"night": "res://assets/audio/music/night.wav",
}
const SFX_PATHS: Dictionary = {
	"cook": "res://assets/audio/sfx/cook.wav",
	"interact": "res://assets/audio/sfx/interact.wav",
	"sleep": "res://assets/audio/sfx/sleep.wav",
	"heart_up": "res://assets/audio/sfx/heart_up.wav",
}

var _music_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}
var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _current_music: String = ""


func _ready() -> void:
	_music_streams = _load_audio_streams(MUSIC_PATHS, "music")
	_sfx_streams = _load_audio_streams(SFX_PATHS, "sound effect")
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SfxPlayer"
	add_child(_sfx_player)


func _exit_tree() -> void:
	if is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null
	if is_instance_valid(_sfx_player):
		_sfx_player.stop()
		_sfx_player.stream = null


func play_music(track_name: String) -> void:
	if not _music_streams.has(track_name):
		push_error("Unknown music track: %s" % track_name)
		return
	if _current_music == track_name and _music_player.playing:
		return
	var stream := _music_streams[track_name] as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	_music_player.stream = stream
	_music_player.play()
	_current_music = track_name


func play_sfx(effect_name: String) -> void:
	if not _sfx_streams.has(effect_name):
		push_error("Unknown sound effect: %s" % effect_name)
		return
	_sfx_player.stream = _sfx_streams[effect_name]
	_sfx_player.play()


func _load_audio_streams(paths: Dictionary, category: String) -> Dictionary:
	var streams: Dictionary = {}
	for audio_name in paths:
		var path := str(paths[audio_name])
		var loaded: Resource = load(path)
		if not loaded is AudioStreamWAV:
			push_error("Could not load %s asset: %s" % [category, path])
			continue
		streams[str(audio_name)] = loaded
	return streams
