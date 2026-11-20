# tests/RustlingBushTest.gd
extends SceneTree

const HearthwoodInteractiveProp = preload("res://scripts/world/InteractiveProp.gd")
const HearthwoodFruitTree = preload("res://scripts/world/FruitTree.gd")
const HearthwoodFreshSpring = preload("res://scripts/world/FreshSpring.gd")
const HearthwoodInspectableHollow = preload("res://scripts/world/InspectableHollow.gd")
const HearthwoodRustlingBush = preload("res://scripts/world/RustlingBush.gd")

const EXPECTED_PROPS_BY_ZONE: Dictionary = {
	"forest_zone_1": ["fruit_tree_apel_hutan_z1"],
	"forest_zone_2": ["fresh_spring_sungai_z2"],
	"forest_zone_3": ["inspectable_stump_z3"],
	"forest_zone_4": ["fruit_tree_beri_z4"],
	"forest_zone_5": ["inspectable_root_cleft_z5"],
}


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- Running RustlingBushTest ---")
	test_rustling_bush_properties_and_trigger()
	test_world_spawns_interactive_props()
	test_world_spawns_rustling_bushes()
	test_world_query_apis()
	test_atmospheric_effects()
	test_world_daily_reset()
	print("RustlingBushTest passed.")
	quit(0)


func test_rustling_bush_properties_and_trigger() -> void:
	print("Testing HearthwoodRustlingBush class and interaction...")
	var bush = HearthwoodRustlingBush.new()
	assert(bush is Area2D, "RustlingBush must extend Area2D")
	assert("bush_id" in bush, "RustlingBush must have bush_id property")
	assert("sway_intensity" in bush, "RustlingBush must have sway_intensity property")
	assert(bush.has_signal("bush_rustled"), "RustlingBush must have bush_rustled signal")

	bush.bush_id = "test_bush_01"
	bush.sway_intensity = 0.15

	root.add_child(bush)

	var col = bush.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert(col != null, "RustlingBush must have CollisionShape2D")
	assert(col.shape != null, "CollisionShape2D shape must not be null")

	var rustled_event: Array[String] = []
	bush.bush_rustled.connect(func(id: String): rustled_event.append(id))

	var player = CharacterBody2D.new()
	player.name = "Player"
	root.add_child(player)

	# Simulate body entered
	if bush.has_method("_on_body_entered"):
		bush._on_body_entered(player)
	elif bush.has_method("trigger_rustle"):
		bush.trigger_rustle()

	assert(rustled_event.size() >= 1, "bush_rustled must be emitted on player contact")
	assert(rustled_event[0] == "test_bush_01", "bush_rustled payload must match bush_id")

	root.remove_child(player)
	player.free()
	root.remove_child(bush)
	bush.free()
	print("HearthwoodRustlingBush passed.")


func test_world_spawns_interactive_props() -> void:
	print("Testing World interactive props instantiation...")
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	assert(world_scene != null, "MainTileset.tscn must exist")
	var world = world_scene.instantiate()
	root.add_child(world)

	assert(world.has_method("get_interactive_props"), "World must implement get_interactive_props()")
	var props = world.get_interactive_props()
	assert(not props.is_empty(), "World must spawn interactive props")

	# Check zone 1 fruit tree
	var apple_tree = world.get_interactive_prop("fruit_tree_apel_hutan_z1")
	assert(apple_tree != null, "World must have fruit_tree_apel_hutan_z1")
	assert(apple_tree is HearthwoodFruitTree, "fruit_tree_apel_hutan_z1 must be HearthwoodFruitTree")
	assert(apple_tree.fruit_item_id == "buah_liar", "Apple tree item must be buah_liar")

	# Check zone 2 fresh spring
	var spring = world.get_interactive_prop("fresh_spring_sungai_z2")
	assert(spring != null, "World must have fresh_spring_sungai_z2")
	assert(spring is HearthwoodFreshSpring, "fresh_spring_sungai_z2 must be HearthwoodFreshSpring")
	assert(spring.energy_restore == 10, "Fresh spring energy restore must be 10")

	# Check zone 3 hollow stump
	var stump = world.get_interactive_prop("inspectable_stump_z3")
	assert(stump != null, "World must have inspectable_stump_z3")
	assert(stump is HearthwoodInspectableHollow, "inspectable_stump_z3 must be HearthwoodInspectableHollow")

	# Check zone 4 berry tree
	var berry_tree = world.get_interactive_prop("fruit_tree_beri_z4")
	assert(berry_tree != null, "World must have fruit_tree_beri_z4")
	assert(berry_tree is HearthwoodFruitTree, "fruit_tree_beri_z4 must be HearthwoodFruitTree")

	# Check zone 5 root cleft
	var root_cleft = world.get_interactive_prop("inspectable_root_cleft_z5")
	assert(root_cleft != null, "World must have inspectable_root_cleft_z5")
	assert(root_cleft is HearthwoodInspectableHollow, "inspectable_root_cleft_z5 must be HearthwoodInspectableHollow")

	root.remove_child(world)
	world.free()
	print("World interactive props instantiation passed.")


func test_world_spawns_rustling_bushes() -> void:
	print("Testing World rustling bushes instantiation...")
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	root.add_child(world)

	assert(world.has_method("get_rustling_bushes"), "World must implement get_rustling_bushes()")
	var bushes = world.get_rustling_bushes()
	assert(bushes.size() >= 6, "World must instantiate at least 6 rustling bushes across zones")

	var bush_ids: Array[String] = []
	for b in bushes:
		assert(b is HearthwoodRustlingBush, "Each bush must be HearthwoodRustlingBush")
		bush_ids.append(b.bush_id)

	assert(bush_ids.has("rustling_bush_z1_a"), "Zone 1 bush A must exist")
	assert(bush_ids.has("rustling_bush_z3_a"), "Zone 3 bush A must exist")
	assert(bush_ids.has("rustling_bush_z4_a"), "Zone 4 bush A must exist")

	root.remove_child(world)
	world.free()
	print("World rustling bushes instantiation passed.")


func test_world_query_apis() -> void:
	print("Testing World query APIs for interactive props...")
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	root.add_child(world)

	# Query by ID
	var found_prop = world.get_interactive_prop("fruit_tree_apel_hutan_z1")
	assert(found_prop != null, "Query by valid ID should succeed")
	var missing_prop = world.get_interactive_prop("non_existent_prop_id")
	assert(missing_prop == null, "Query by invalid ID should return null")

	# Query closest prop
	var tree_pos = found_prop.global_position
	var closest = world.get_closest_interactive_prop(tree_pos + Vector2(10.0, 5.0), 48.0)
	assert(closest == found_prop, "get_closest_interactive_prop should locate nearby prop")

	var far_away = world.get_closest_interactive_prop(Vector2(9999.0, 9999.0), 48.0)
	assert(far_away == null, "get_closest_interactive_prop should return null when none in range")

	root.remove_child(world)
	world.free()
	print("World query APIs passed.")


func test_atmospheric_effects() -> void:
	print("Testing World atmospheric ambient particles...")
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	root.add_child(world)

	assert(world.has_method("get_ambient_particles"), "World must implement get_ambient_particles()")
	var particles: Dictionary = world.get_ambient_particles()

	assert(particles.has("mist"), "Must have mist particles for Zone 4")
	assert(particles.has("spores"), "Must have spores particles for Zone 5")
	assert(particles.has("fireflies"), "Must have fireflies particles for Zone 6")

	var mist_particle = particles["mist"] as CPUParticles2D
	assert(mist_particle != null, "Mist particle must be CPUParticles2D")
	assert(is_equal_approx(mist_particle.color.r, 0.85) and is_equal_approx(mist_particle.color.g, 0.90) and is_equal_approx(mist_particle.color.a, 0.18), "Mist color must match brief")

	var spore_particle = particles["spores"] as CPUParticles2D
	assert(spore_particle != null, "Spore particle must be CPUParticles2D")
	assert(is_equal_approx(spore_particle.color.r, 0.70) and is_equal_approx(spore_particle.color.g, 0.85) and is_equal_approx(spore_particle.color.a, 0.40), "Spore color must match brief")

	var firefly_particle = particles["fireflies"] as CPUParticles2D
	assert(firefly_particle != null, "Firefly particle must be CPUParticles2D")
	assert(is_equal_approx(firefly_particle.color.r, 0.96) and is_equal_approx(firefly_particle.color.g, 0.77) and is_equal_approx(firefly_particle.color.a, 0.65), "Firefly color must match brief")

	root.remove_child(world)
	world.free()
	print("World atmospheric ambient particles passed.")


func test_world_daily_reset() -> void:
	print("Testing World daily reset on interactive props...")
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	root.add_child(world)

	var apple_tree: HearthwoodFruitTree = world.get_interactive_prop("fruit_tree_apel_hutan_z1") as HearthwoodFruitTree
	var spring: HearthwoodFreshSpring = world.get_interactive_prop("fresh_spring_sungai_z2") as HearthwoodFreshSpring
	var hollow: HearthwoodInspectableHollow = world.get_interactive_prop("inspectable_stump_z3") as HearthwoodInspectableHollow

	assert(apple_tree != null and spring != null and hollow != null, "Props must be found")

	var res_tree = apple_tree.interact()
	assert(res_tree["success"] == true, "Apple tree interaction should succeed")
	assert(apple_tree.daily_interacted == true, "Apple tree should be daily_interacted")
	assert(apple_tree.has_fruit == false, "Apple tree should not have fruit")

	var res_spring = spring.interact()
	assert(res_spring["success"] == true, "Spring interaction should succeed")
	assert(spring.daily_interacted == true, "Spring should be daily_interacted")

	var res_hollow = hollow.interact()
	assert(res_hollow["success"] == true, "Hollow interaction should succeed")
	assert(hollow.daily_interacted == true, "Hollow should be daily_interacted")

	# Trigger day change on world
	world._on_day_changed(2)

	assert(apple_tree.daily_interacted == false, "Apple tree must reset daily_interacted")
	assert(apple_tree.has_fruit == true, "Apple tree must regrow fruit")
	assert(apple_tree.can_interact() == true, "Apple tree must be interactable again")

	assert(spring.daily_interacted == false, "Spring must reset daily_interacted")
	assert(spring.can_interact() == true, "Spring must be interactable again")

	assert(hollow.daily_interacted == false, "Hollow must reset daily_interacted")
	assert(hollow.can_interact() == true, "Hollow must be interactable again")

	root.remove_child(world)
	world.free()
	print("World daily reset passed.")
