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
