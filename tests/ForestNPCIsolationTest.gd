# tests/ForestNPCIsolationTest.gd
extends SceneTree

func _init() -> void:
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	
	# Verify no ambient NPC is spawned in forest coordinates (all must be in village x >= 560.0)
	assert(world._ambient_npcs.size() > 0, "Ambient NPCs must be spawned")
	for npc in world._ambient_npcs:
		assert(npc.global_position.x >= 560.0, "Ambient NPC must only spawn in village: " + str(npc.global_position))
		var zone_id = world.get_zone_for_position(npc.global_position)
		assert(zone_id == "village", "Ambient NPC zone must be village, got: " + zone_id)
	
	# Verify Rast is placed in forest_zone_3 at 06:00
	var time_system = load("res://scripts/systems/TimeSystem.gd").new()
	time_system.set("current_hour", 6)
	var rast_npc = world.get_named_npc("rast")
	assert(rast_npc != null, "Rast NPC must exist")
	var f3_rect = world.get_zone_rect("forest_zone_3")
	assert(f3_rect.has_point(rast_npc.global_position), "Rast must be located in forest_zone_3 during work hours (06:00-16:00), got: " + str(rast_npc.global_position))
	
	world.free()
	time_system.free()
	print("ForestNPCIsolationTest passed.")
	quit(0)
