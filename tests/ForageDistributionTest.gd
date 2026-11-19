# tests/ForageDistributionTest.gd
extends SceneTree

func _init() -> void:
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	
	# Verify that each of the 6 forest zones contains forage spawn points according to spec
	var zones_with_forage = {}
	for spawn in world.FORAGE_SPAWN_POINTS:
		var pos: Vector2 = spawn["position"]
		var found_zone = ""
		for zid in ["forest_zone_1", "forest_zone_2", "forest_zone_3", "forest_zone_4", "forest_zone_5", "forest_zone_6"]:
			if world.get_zone_rect(zid).has_point(pos):
				found_zone = zid
				break
		assert(found_zone != "", "Forage point " + spawn["spawn_id"] + " must belong to a defined forest zone: " + str(pos))
		zones_with_forage[found_zone] = true
	
	# All 6 forest zones must have forage spawns
	for zid in ["forest_zone_1", "forest_zone_2", "forest_zone_3", "forest_zone_4", "forest_zone_5", "forest_zone_6"]:
		assert(zones_with_forage.has(zid), "Zone " + zid + " must contain at least one forage spawn point")
	
	# Verify specific thematic placements:
	# Zone 1 (Pintu Rimba): sayur_liar, daun_hutan
	var z1_rect = world.get_zone_rect("forest_zone_1")
	var z1_items = []
	for spawn in world.FORAGE_SPAWN_POINTS:
		if z1_rect.has_point(spawn["position"]):
			z1_items.append(spawn["id"])
	assert("sayur_liar" in z1_items or "daun_hutan" in z1_items, "Zone 1 must contain sayur_liar or daun_hutan")
	
	# Zone 2 (Aliran Sungai): ikan_sungai, batu
	var z2_rect = world.get_zone_rect("forest_zone_2")
	var z2_items = []
	for spawn in world.FORAGE_SPAWN_POINTS:
		if z2_rect.has_point(spawn["position"]):
			z2_items.append(spawn["id"])
	assert("ikan_sungai" in z2_items or "batu" in z2_items, "Zone 2 must contain ikan_sungai or batu")
	
	# Zone 3 (Pos Penebang): kayu
	var z3_rect = world.get_zone_rect("forest_zone_3")
	var z3_items = []
	for spawn in world.FORAGE_SPAWN_POINTS:
		if z3_rect.has_point(spawn["position"]):
			z3_items.append(spawn["id"])
	assert("kayu" in z3_items, "Zone 3 must contain kayu")
	
	# Zone 4 (Semak Belukar Lembab): jamur_hutan, buah_liar
	var z4_rect = world.get_zone_rect("forest_zone_4")
	var z4_items = []
	for spawn in world.FORAGE_SPAWN_POINTS:
		if z4_rect.has_point(spawn["position"]):
			z4_items.append(spawn["id"])
	assert("jamur_hutan" in z4_items or "buah_liar" in z4_items, "Zone 4 must contain jamur_hutan or buah_liar")
	
	# Zone 5 (Lembah Akar Purba): akar_rempah
	var z5_rect = world.get_zone_rect("forest_zone_5")
	var z5_items = []
	for spawn in world.FORAGE_SPAWN_POINTS:
		if z5_rect.has_point(spawn["position"]):
			z5_items.append(spawn["id"])
	assert("akar_rempah" in z5_items, "Zone 5 must contain akar_rempah")
	
	# Rain bonus spawn in zone 4
	assert(z4_rect.has_point(world.RAIN_FORAGE_SPAWN["position"]), "RAIN_FORAGE_SPAWN must be located in forest_zone_4")
	
	world.free()
	print("ForageDistributionTest passed.")
	quit(0)
