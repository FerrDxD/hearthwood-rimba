extends Node
class_name HearthwoodSaveSystem


func write_save(path: String, data: Dictionary) -> Dictionary:
	if path.is_empty():
		return {"valid": false, "pesan": "Lokasi save tidak valid."}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {
			"valid": false,
			"pesan": "File save tidak dapat dibuka (kode %d)." % FileAccess.get_open_error(),
		}
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	if write_error != OK:
		return {
			"valid": false,
			"pesan": "File save gagal ditulis (kode %d)." % write_error,
		}
	return {"valid": true, "pesan": "Game berhasil disimpan."}


func read_save(path: String) -> Dictionary:
	if path.is_empty():
		return {"valid": false, "exists": false, "pesan": "Lokasi save tidak valid."}
	if not FileAccess.file_exists(path):
		return {"valid": false, "exists": false, "pesan": "Save tidak ditemukan."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"valid": false,
			"exists": true,
			"pesan": "File save tidak dapat dibaca (kode %d)." % FileAccess.get_open_error(),
		}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {
			"valid": false,
			"exists": true,
			"pesan": "Format file save tidak valid: %s" % parser.get_error_message(),
		}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"valid": false, "exists": true, "pesan": "Format file save harus berupa object."}
	return {"valid": true, "exists": true, "data": parsed, "pesan": "Save berhasil dibaca."}


## Serializes game state and writes save file.
func save_game(
	game_state: Node,
	path: String = "user://savegame.json",
	player_position: Vector2 = Vector2.ZERO,
	scene_path: String = ""
) -> Dictionary:
	if game_state == null:
		return {"valid": false, "pesan": "GameState tidak valid."}
	var save_data: Dictionary
	if game_state.has_method("_create_save_data"):
		save_data = game_state._create_save_data(player_position, scene_path)
	else:
		save_data = {
			"interacted_props_today": serialize_interacted_props(game_state)
		}
	return write_save(path, save_data)


## Reads save file and restores game state with backward compatibility.
func load_game(game_state: Node, path: String = "user://savegame.json") -> Dictionary:
	var read_result := read_save(path)
	if not bool(read_result.get("valid", false)):
		return read_result
	var data: Dictionary = read_result.get("data", {})
	if game_state != null:
		if game_state.has_method("_load_save_data"):
			game_state._load_save_data(data)
		else:
			restore_interacted_props(game_state, data)
	return read_result


## Helper to serialize interacted_props_today from game_state.
func serialize_interacted_props(game_state: Node) -> Array[String]:
	if game_state != null and "interacted_props_today" in game_state:
		return (game_state.interacted_props_today as Array[String]).duplicate()
	return []


## Helper to restore interacted_props_today into game_state with backward compatibility.
func restore_interacted_props(game_state: Node, data: Dictionary) -> void:
	if game_state == null or not ("interacted_props_today" in game_state):
		return
	var raw_props: Variant = data.get(
		"interacted_props_today",
		data.get("objek_interaktif_hari_ini", [])
	)
	game_state.interacted_props_today.clear()
	if typeof(raw_props) == TYPE_ARRAY:
		for item in raw_props:
			var id_str := str(item).strip_edges()
			if not id_str.is_empty() and not game_state.interacted_props_today.has(id_str):
				game_state.interacted_props_today.append(id_str)
