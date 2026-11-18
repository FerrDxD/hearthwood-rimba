extends SceneTree

const AUDIO_DIRECTOR_SCRIPT: Script = preload("res://scripts/systems/AudioDirector.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var audio_director = AUDIO_DIRECTOR_SCRIPT.new()
	root.add_child(audio_director)
	await process_frame

	for track_name in ["forest", "village", "night"]:
		audio_director.play_music(track_name)
		var music_player := audio_director.get_node("MusicPlayer") as AudioStreamPlayer
		if not music_player.playing or music_player.stream == null:
			push_error("Music track did not start: %s" % track_name)
			quit(1)
			return
		var stream := music_player.stream as AudioStreamWAV
		if stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			push_error("Music track should loop: %s" % track_name)
			quit(1)
			return

	for effect_name in ["cook", "interact", "sleep", "heart_up"]:
		audio_director.play_sfx(effect_name)
		var sfx_player := audio_director.get_node("SfxPlayer") as AudioStreamPlayer
		if not sfx_player.playing or sfx_player.stream == null:
			push_error("Sound effect did not start: %s" % effect_name)
			quit(1)
			return

	var music_player := audio_director.get_node("MusicPlayer") as AudioStreamPlayer
	var sfx_player := audio_director.get_node("SfxPlayer") as AudioStreamPlayer
	music_player.stop()
	sfx_player.stop()
	music_player.stream = null
	sfx_player.stream = null
	audio_director.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	print("Forest, village, night, and gameplay audio assets loaded and played.")
	quit(0)
