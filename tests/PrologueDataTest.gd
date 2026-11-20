# tests/PrologueDataTest.gd
extends SceneTree

func _init() -> void:
	var file := FileAccess.open("res://data/quests/opening_prologue.json", FileAccess.READ)
	if file == null:
		push_error("opening_prologue.json must exist")
		quit(1)
		return
		
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Data must be a Dictionary")
		quit(1)
		return
	
	if not data.has("monologues") or typeof(data["monologues"]) != TYPE_ARRAY:
		push_error("Must contain monologues array")
		quit(1)
		return
		
	if data["monologues"].size() < 5:
		push_error("Must contain at least 5 monologue steps")
		quit(1)
		return
	
	for entry in data["monologues"]:
		if typeof(entry) != TYPE_DICTIONARY:
			push_error("Monologue entry must be a Dictionary")
			quit(1)
			return
		if not entry.has("id") or str(entry["id"]).is_empty():
			push_error("Monologue must have an id")
			quit(1)
			return
		if not entry.has("text") or str(entry["text"]).is_empty():
			push_error("Monologue must have text")
			quit(1)
			return
		if not entry.has("audio_hint"):
			push_error("Monologue must have audio_hint")
			quit(1)
			return
	
	if not data.has("awakening") or typeof(data["awakening"]) != TYPE_DICTIONARY:
		push_error("Must contain awakening object")
		quit(1)
		return
		
	if not data["awakening"].has("text") or str(data["awakening"]["text"]).is_empty():
		push_error("Awakening must have text")
		quit(1)
		return
		
	if not data["awakening"].has("question") or str(data["awakening"]["question"]).is_empty():
		push_error("Awakening must have question")
		quit(1)
		return
	
	print("PrologueDataTest passed.")
	quit(0)
