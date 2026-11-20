extends "res://scripts/world/InteractiveProp.gd"
class_name HearthwoodVillageWell

signal well_drawn(energy_restored: int, item_id: String)

@export var energy_restore: int = 5
@export var water_item_id: String = "air_bersih"

var is_drawing_water: bool = false


func _init() -> void:
	super._init()
	prop_id = "village_well"
	prop_type = "village_well"
	interaction_prompt = "Timba Air"
	interaction_radius = 48.0


func _ready() -> void:
	super._ready()
	queue_redraw()


func can_interact() -> bool:
	return not daily_interacted


func interact(player: Node2D = null) -> Dictionary:
	if daily_interacted:
		var fail_result := {
			"success": false,
			"message": "Air sumur masih tenang beriak di kedalaman. Kamu sudah mengambil air untuk hari ini.",
			"data": {}
		}
		interacted.emit(fail_result)
		return fail_result

	daily_interacted = true
	var game_state := _get_game_state()
	if game_state != null:
		if game_state.has_method("change_energy"):
			game_state.change_energy(energy_restore)
		elif "energy" in game_state:
			game_state.energy = mini(100, int(game_state.energy) + energy_restore)

		if game_state.has_method("add_item"):
			game_state.add_item(water_item_id, 1)

	_play_draw_animation()
	well_drawn.emit(energy_restore, water_item_id)

	var success_result := {
		"success": true,
		"message": "Kamu menimba seember air bersih yang segar dan membasuh wajahmu. Energi bertambah +5!",
		"data": {
			"energy_restored": energy_restore,
			"item_awarded": water_item_id
		}
	}
	interacted.emit(success_result)
	return success_result


func reset_daily() -> void:
	super.reset_daily()
	daily_interacted = false


func _play_draw_animation() -> void:
	if not is_inside_tree() or is_drawing_water:
		return
	var target: Node2D = get_node_or_null("Sprite2D") as Node2D
	if target == null:
		target = self
	var original_pos := target.position
	var tween := create_tween()
	if tween == null:
		return

	is_drawing_water = true
	# Tactile hoisting motion: slight pull upwards, slight bounce, return to rest
	tween.tween_property(target, "position", original_pos + Vector2(0.0, -3.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", original_pos + Vector2(0.0, 1.5), 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", original_pos, 0.10).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): is_drawing_water = false)


func _draw() -> void:
	# Subtle contact ground shadow
	draw_circle(Vector2(0.0, 10.0), 19.0, Color(0.10, 0.12, 0.10, 0.28))

	# Cobblestone apron / well base foundation
	draw_circle(Vector2(0.0, 4.0), 18.0, Color("#525955"))
	draw_circle(Vector2(0.0, 2.0), 16.0, Color("#6B736E"))

	# Mortar detailing / ring stone facets
	var stone_angles := [0.0, 1.05, 2.09, 3.14, 4.19, 5.24]
	for rad in stone_angles:
		var edge_pt := Vector2(cos(rad), sin(rad) * 0.7) * 16.0
		var inner_pt := Vector2(cos(rad), sin(rad) * 0.7) * 11.0
		draw_line(edge_pt + Vector2(0.0, 2.0), inner_pt + Vector2(0.0, 2.0), Color("#4F5652"), 1.2)
		draw_circle(edge_pt + Vector2(0.0, 2.0), 1.2, Color("#8A938E"))

	# Dark interior opening
	draw_circle(Vector2(0.0, 1.0), 11.0, Color("#1E2B27"))

	# Deep subterranean water reflection
	draw_circle(Vector2(0.0, 2.0), 8.0, Color("#2F5157"))
	draw_arc(Vector2(-1.0, 2.0), 5.0, -1.0, 1.2, 12, Color("#55878F"), 1.2)

	# Left wooden support post (#76513A)
	draw_rect(Rect2(-14.0, -24.0, 4.0, 26.0), Color("#76513A"))
	draw_line(Vector2(-13.0, -24.0), Vector2(-13.0, 2.0), Color("#946C51"), 1.0)
	draw_rect(Rect2(-15.0, 0.0, 6.0, 4.0), Color("#4F5652")) # Stone footer clamp

	# Right wooden support post (#76513A)
	draw_rect(Rect2(10.0, -24.0, 4.0, 26.0), Color("#76513A"))
	draw_line(Vector2(11.0, -24.0), Vector2(11.0, 2.0), Color("#946C51"), 1.0)
	draw_rect(Rect2(9.0, 0.0, 6.0, 4.0), Color("#4F5652")) # Stone footer clamp

	# Wooden crossbeam axle
	draw_rect(Rect2(-14.0, -20.0, 28.0, 4.0), Color("#5C3A1E"))
	draw_line(Vector2(-14.0, -20.0), Vector2(14.0, -20.0), Color("#76513A"), 1.0)

	# Pulley wheel and rope
	draw_circle(Vector2(0.0, -18.0), 3.0, Color("#3A2312"))
	draw_circle(Vector2(0.0, -18.0), 1.0, Color("#8A938E"))
	draw_line(Vector2(0.0, -17.0), Vector2(0.0, -6.0), Color("#D4B98B"), 1.5)

	# Suspended wooden bucket
	draw_rect(Rect2(-4.0, -6.0, 8.0, 7.0), Color("#8A5229"))
	draw_line(Vector2(-4.0, -6.0), Vector2(4.0, -6.0), Color("#3E2614"), 1.2)
	draw_line(Vector2(-4.0, -3.0), Vector2(4.0, -3.0), Color("#4A4A4A"), 1.0) # Iron hoop
	draw_rect(Rect2(-3.0, -6.0, 6.0, 2.0), Color("#588B9C")) # Water sheen inside bucket

	# Gabled wooden roof (#5C3A1E)
	var roof_shadow: PackedVector2Array = [
		Vector2(-19.0, -22.0),
		Vector2(0.0, -34.0),
		Vector2(19.0, -22.0)
	]
	draw_colored_polygon(roof_shadow, Color("#422813"))

	var roof_slats: PackedVector2Array = [
		Vector2(-20.0, -21.0),
		Vector2(0.0, -35.0),
		Vector2(20.0, -21.0)
	]
	draw_colored_polygon(roof_slats, Color("#5C3A1E"))

	# Shingle texture lines and ridge highlights
	draw_line(Vector2(-20.0, -21.0), Vector2(0.0, -35.0), Color("#8F654A"), 2.0)
	draw_line(Vector2(0.0, -35.0), Vector2(20.0, -21.0), Color("#3E2614"), 2.0)
	draw_line(Vector2(-10.0, -28.0), Vector2(-4.0, -28.0), Color("#76513A"), 1.2)
	draw_line(Vector2(4.0, -28.0), Vector2(10.0, -28.0), Color("#4A2E17"), 1.2)
