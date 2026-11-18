extends SceneTree

const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")
const DIALOG_UI_SCENE: PackedScene = preload("res://scenes/DialogUI.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const COOKING_SYSTEM_SCENE: PackedScene = preload("res://scenes/CookingSystem.tscn")
const AFFECTION_SYSTEM_SCENE: PackedScene = preload("res://scenes/AffectionSystem.tscn")
const EXPANSION_NPCS: Array[String] = ["arin", "budi", "siti", "pak_udin"]


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var world := WORLD_SCENE.instantiate() as HearthwoodWorld
	root.add_child(world)
	await process_frame

	if world.get_named_npc_count() != 15 or world.get_ambient_npc_count() != 32:
		push_error("Expected 15 named NPCs and 32 ambient NPCs.")
		quit(1)
		return
	var ground := world.get_node_or_null("ground") as TileMapLayer
	var tile_source: TileSetAtlasSource
	if ground != null and ground.tile_set != null:
		tile_source = ground.tile_set.get_source(0) as TileSetAtlasSource
	if (
		tile_source == null
		or tile_source.texture == null
		or tile_source.texture.get_size() != Vector2(80.0, 16.0)
	):
		push_error("The medieval world tiles should load from the 16-pixel atlas asset.")
		quit(1)
		return

	var rast := world.get_closest_named_npc(Vector2(210.0, 432.0), 300.0)
	if rast == null or rast.get_display_name() != "Rast":
		push_error("Rast should be available near the forest spawn.")
		quit(1)
		return

	var first_dialogue := rast.get_dialogue()
	rast.mark_met()
	var second_dialogue := rast.get_dialogue()
	if first_dialogue.is_empty() or second_dialogue.is_empty() or first_dialogue == second_dialogue:
		push_error("NPC first and progressed dialogues should both load from data.")
		quit(1)
		return
	var rast_visual := rast.get_node_or_null("characterVisual")
	if (
		rast_visual == null
		or rast_visual.get_child_count() != 6
		or rast_visual.get_node_or_null("hair") == null
		or rast_visual.get_node_or_null("shirt") == null
	):
		push_error("Named NPCs should use reusable layered pixel character art.")
		quit(1)
		return

	var player := PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame
	var player_visual: Node = player.get_node_or_null("characterVisual")
	if player_visual == null or player_visual.get_child_count() != 6:
		push_error("The player should use the layered pixel character art.")
		quit(1)
		return

	# Expansion NPCs load data, follow their schedules, and react to food.
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")
	for npc_id in EXPANSION_NPCS:
		var expansion_npc := _find_npc(world, npc_id)
		if (
			expansion_npc == null
			or expansion_npc.get_display_name().is_empty()
			or expansion_npc.get_role().is_empty()
			or expansion_npc.get_dialogue().is_empty()
		):
			push_error("Expansion NPC should load name, role, and dialogue from JSON: %s" % npc_id)
			quit(1)
			return

	game_state.current_hour = 7
	time_system.sync_from_game_state()
	await process_frame
	if (
		not _find_npc(world, "arin").can_interact()
		or _find_npc(world, "siti").can_interact()
		or _find_npc(world, "budi").can_interact()
		or _find_npc(world, "pak_udin").can_interact()
	):
		push_error("Arin should be the only expansion NPC available at 07:00.")
		quit(1)
		return
	game_state.current_hour = 9
	time_system.sync_from_game_state()
	await process_frame
	if (
		_find_npc(world, "arin").can_interact()
		or not _find_npc(world, "siti").can_interact()
		or not _find_npc(world, "budi").can_interact()
	):
		push_error("Siti and Budi should be available at 09:00 while Arin is gone.")
		quit(1)
		return
	game_state.current_hour = 16
	time_system.sync_from_game_state()
	await process_frame
	if not _find_npc(world, "pak_udin").can_interact():
		push_error("Pak Udin should be available in the afternoon.")
		quit(1)
		return

	var cooking_system := COOKING_SYSTEM_SCENE.instantiate() as HearthwoodCookingSystem
	root.add_child(cooking_system)
	var affection_system := AFFECTION_SYSTEM_SCENE.instantiate() as HearthwoodAffectionSystem
	affection_system.set_cooking_system(cooking_system)
	root.add_child(affection_system)
	await process_frame
	if (
		affection_system.preview_food_reaction("arin", "bubur_hangat_hutan") != "suka"
		or affection_system.preview_food_reaction("siti", "ikan_bakar_rempah") != "suka"
		or affection_system.preview_food_reaction("siti", "sambal_tumisan_pedas") != "tidak_suka"
		or affection_system.preview_food_reaction("pak_udin", "bubur_hangat_hutan") != "tidak_suka"
		or affection_system.preview_food_reaction("budi", "kue_manis_liar") != "suka"
	):
		push_error("Expansion NPC food preferences should drive their affection reactions.")
		quit(1)
		return

	var dialog_ui := DIALOG_UI_SCENE.instantiate() as HearthwoodDialogUI
	root.add_child(dialog_ui)
	dialog_ui.open_dialog(rast.get_display_name(), rast.get_role(), first_dialogue)
	if not dialog_ui.is_open():
		push_error("Dialog UI did not open.")
		quit(1)
		return
	dialog_ui.close_dialog()
	if dialog_ui.is_open():
		push_error("Dialog UI did not close.")
		quit(1)
		return

	print("NPC data, schedules, layered character art, ambient population, expansion NPCs, and dialog UI tests passed.")
	quit(0)


func _find_npc(world: HearthwoodWorld, npc_id: String) -> HearthwoodNPC:
	for child in world.get_children():
		if child is HearthwoodNPC and child.npc_id == npc_id:
			return child as HearthwoodNPC
	return null
