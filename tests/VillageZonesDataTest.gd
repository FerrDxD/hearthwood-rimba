# tests/VillageZonesDataTest.gd
extends SceneTree


func _init() -> void:
	var file := FileAccess.open("res://data/world/village_zones.json", FileAccess.READ)
	assert(file != null, "village_zones.json must exist")
	var data: Variant = JSON.parse_string(file.get_as_text())
	assert(typeof(data) == TYPE_DICTIONARY, "Data must be a Dictionary")

	# Verify 4 districts
	assert(data.has("districts"), "Must contain districts")
	for d in ["market_district", "civic_district", "tavern_district", "residential_district"]:
		assert(data["districts"].has(d), "Must contain district: " + d)
		var dist_info: Dictionary = data["districts"][d]
		assert(dist_info.has("bounds"), "District %s must have bounds" % d)
		var bounds: Array = dist_info["bounds"]
		assert(bounds.size() == 4, "Bounds must have 4 elements [x, y, w, h]")
		assert(bounds[0] >= 560.0, "District %s bounds.x must be >= 560.0 (village boundary)" % d)

	# Verify building landmarks
	assert(data.has("buildings"), "Must contain buildings")
	assert(data["buildings"].has("town_hall"), "Must contain town_hall")
	assert(data["buildings"].has("giral_store"), "Must contain giral_store")
	assert(data["buildings"].has("talia_store"), "Must contain talia_store")
	assert(data["buildings"].has("player_warung"), "Must contain player_warung")
	assert(data["buildings"].has("village_granary"), "Must contain village_granary")
	assert(data["buildings"].has("residential_cottages"), "Must contain residential_cottages")

	# Verify residential cottages
	var cottages: Array = data["buildings"]["residential_cottages"]
	assert(cottages.size() >= 6, "Must contain at least 6 residential cottages")
	for c in cottages:
		assert(c.has("id"), "Cottage must have id")
		assert(c.has("name"), "Cottage must have name")
		assert(c.has("position"), "Cottage must have position")
		assert(c["position"][0] >= 560.0, "Cottage position.x must be >= 560.0")

	# Verify interactive props
	assert(data.has("props"), "Must contain props")
	assert(data["props"].has("village_well"), "Must contain village_well")
	assert(data["props"].has("notice_board"), "Must contain notice_board")
	assert(data["props"]["village_well"]["position"][0] >= 560.0, "Well must be in village")
	assert(data["props"]["notice_board"]["position"][0] >= 560.0, "Notice board must be in village")

	# Verify social crowd clusters
	assert(data.has("clusters"), "Must contain clusters")
	for c in ["market_cluster", "plaza_cluster", "tavern_cluster", "residential_cluster"]:
		assert(data["clusters"].has(c), "Must contain cluster: " + c)
		var cluster_info: Dictionary = data["clusters"][c]
		assert(cluster_info.has("bounds"), "Cluster %s must have bounds" % c)
		assert(cluster_info["bounds"][0] >= 560.0, "Cluster %s bounds.x must be >= 560.0" % c)

	# Verify items.json contains air_bersih
	var ifile := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	assert(ifile != null, "items.json must exist")
	var idata: Variant = JSON.parse_string(ifile.get_as_text())
	var water_item: Dictionary = {}
	for it in idata.get("items", []):
		if it.get("id") == "air_bersih":
			water_item = it
			break
	assert(not water_item.is_empty(), "items.json must contain air_bersih")
	assert(water_item.get("kategori") == "bahan", "air_bersih kategori must be 'bahan'")
	assert(water_item.get("sumber") == "desa", "air_bersih sumber must be 'desa'")

	print("VillageZonesDataTest passed.")
	quit(0)
