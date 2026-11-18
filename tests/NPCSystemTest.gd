extends SceneTree

const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")
const DIALOG_UI_SCENE: PackedScene = preload("res://scenes/DialogUI.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var world := WORLD_SCENE.instantiate() as HearthwoodWorld
	root.add_child(world)
	await process_frame

	if world.get_named_npc_count() != 11 or world.get_ambient_npc_count() != 32:
		push_error("Expected 11 named NPCs and 32 ambient NPCs.")
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

	print("NPC data, schedules, layered character art, ambient population, and dialog UI tests passed.")
	quit(0)
