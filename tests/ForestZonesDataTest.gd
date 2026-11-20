# tests/ForestZonesDataTest.gd
extends SceneTree

const EXPECTED_BOUNDS: Dictionary = {
	"forest_zone_1": [0.0, 960.0, 560.0, 480.0],
	"forest_zone_2": [-560.0, 960.0, 560.0, 480.0],
	"forest_zone_3": [0.0, 480.0, 560.0, 480.0],
	"forest_zone_4": [560.0, -480.0, 560.0, 480.0],
	"forest_zone_5": [-560.0, 480.0, 560.0, 480.0],
	"forest_zone_6": [0.0, 0.0, 560.0, 480.0],
}

const EXPECTED_NAMES: Dictionary = {
	"forest_zone_1": "Pintu Rimba",
	"forest_zone_2": "Aliran Sungai Bebatuan",
	"forest_zone_3": "Pos Penebang Kayu",
	"forest_zone_4": "Semak Belukar Lembab",
	"forest_zone_5": "Lembah Akar Purba",
	"forest_zone_6": "Suaka Pohon Raksasa",
}

func _init() -> void:
	var file := FileAccess.open("res://data/world/forest_zones.json", FileAccess.READ)
	assert(file != null, "forest_zones.json must exist")
	var data: Variant = JSON.parse_string(file.get_as_text())
	assert(typeof(data) == TYPE_DICTIONARY, "Data must be a Dictionary")

	var found_baseline_sayur := false

	for i in range(1, 7):
		var zid := "forest_zone_%d" % i
		assert(data.has(zid), "Must contain entry for " + zid)
		var zdata: Dictionary = data[zid]
		assert(zdata.has("name"), zid + " must have name")
		assert(zdata["name"] == EXPECTED_NAMES[zid], "Zone name mismatch for " + zid)

		assert(zdata.has("bounds"), zid + " must have bounds")
		var b = zdata["bounds"]
		assert(typeof(b) == TYPE_ARRAY and b.size() == 4, zid + " bounds must be [x, y, w, h]")
		var exp_b: Array = EXPECTED_BOUNDS[zid]
		assert(is_equal_approx(float(b[0]), float(exp_b[0])) and is_equal_approx(float(b[1]), float(exp_b[1])) and is_equal_approx(float(b[2]), float(exp_b[2])) and is_equal_approx(float(b[3]), float(exp_b[3])), zid + " bounds mismatch")

		var rect := Rect2(float(b[0]), float(b[1]), float(b[2]), float(b[3]))

		assert(zdata.has("landmarks"), zid + " must have landmarks")
		assert(typeof(zdata["landmarks"]) == TYPE_ARRAY and not zdata["landmarks"].is_empty(), zid + " landmarks must not be empty")
		for lm in zdata["landmarks"]:
			assert(lm.has("id") and lm.has("name") and lm.has("type") and lm.has("position") and lm.has("description"), "Landmark missing required keys in " + zid)
			var pos := Vector2(float(lm["position"][0]), float(lm["position"][1]))
			assert(rect.has_point(pos), "Landmark %s position %s must be inside zone rect %s" % [lm["id"], str(pos), str(rect)])

		assert(zdata.has("props"), zid + " must have props")
		assert(typeof(zdata["props"]) == TYPE_ARRAY and not zdata["props"].is_empty(), zid + " props must not be empty")
		for prop in zdata["props"]:
			assert(prop.has("id") and prop.has("type") and prop.has("position"), "Prop missing required keys in " + zid)
			var pos := Vector2(float(prop["position"][0]), float(prop["position"][1]))
			assert(rect.has_point(pos), "Prop %s position %s must be inside zone rect %s" % [prop["id"], str(pos), str(rect)])

		assert(zdata.has("forages"), zid + " must have forages")
		assert(typeof(zdata["forages"]) == TYPE_ARRAY and not zdata["forages"].is_empty(), zid + " forages must not be empty")
		for f in zdata["forages"]:
			assert(f.has("spawn_id") and f.has("id") and f.has("position"), "Forage missing required keys in " + zid)
			var pos := Vector2(float(f["position"][0]), float(f["position"][1]))
			assert(rect.has_point(pos), "Forage %s position %s must be inside zone rect %s" % [f["spawn_id"], str(pos), str(rect)])
			if zid == "forest_zone_1" and f["spawn_id"] == "sayur_liar_1" and f["id"] == "sayur_liar":
				if is_equal_approx(pos.x, 104.0) and is_equal_approx(pos.y, 1178.0):
					found_baseline_sayur = true

	assert(found_baseline_sayur, "Must preserve baseline sayur_liar_1 at Vector2(104.0, 1178.0) in forest_zone_1")

	# Verify items.json contains lumut_sungai
	var ifile := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	assert(ifile != null, "items.json must exist")
	var idata: Variant = JSON.parse_string(ifile.get_as_text())
	var has_moss := false
	for it in idata.get("items", []):
		if it.get("id") == "lumut_sungai":
			assert(it.get("nama") == "Lumut sungai", "lumut_sungai nama mismatch")
			assert(it.get("kategori") == "bahan", "lumut_sungai kategori mismatch")
			assert(it.get("sumber") == "sungai", "lumut_sungai sumber mismatch")
			assert(it.get("warna") == "#5b8a54", "lumut_sungai warna mismatch")
			has_moss = true
			break
	assert(has_moss, "items.json must contain lumut_sungai")

	print("ForestZonesDataTest passed.")
	quit(0)
