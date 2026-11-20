extends "res://scripts/world/InteractiveProp.gd"
class_name HearthwoodInspectableHollow

signal loot_found(item_id: String)

@export var possible_loot: Array[String] = ["jamur_hutan", "akar_rempah", "kayu"]
@export var hollow_name: String = "Tunggul Berongga"


func _init() -> void:
	super._init()
	prop_type = "inspectable_hollow"
	interaction_prompt = "Periksa Ceruk"


func can_interact() -> bool:
	return not daily_interacted


func interact(player: Node2D = null) -> Dictionary:
	if daily_interacted:
		var fail_result := {
			"success": false,
			"message": "Ceruk ini sudah kosong untuk hari ini.",
			"data": null
		}
		interacted.emit(fail_result)
		return fail_result

	daily_interacted = true
	var chosen_item := ""
	if not possible_loot.is_empty():
		chosen_item = possible_loot[randi() % possible_loot.size()]

	var game_state := _get_game_state()
	if game_state != null and not chosen_item.is_empty() and game_state.has_method("add_item"):
		game_state.add_item(chosen_item, 1)

	_play_inspect_feedback()
	loot_found.emit(chosen_item)

	var success_result := {
		"success": true,
		"message": "Memeriksa %s dan menemukan %s!" % [hollow_name, chosen_item],
		"data": {
			"item_id": chosen_item,
			"hollow_name": hollow_name
		}
	}
	interacted.emit(success_result)
	return success_result


func reset_daily() -> void:
	super.reset_daily()


func _play_inspect_feedback() -> void:
	if not is_inside_tree():
		return
	var target: Node2D = get_node_or_null("Sprite2D") as Node2D
	if target == null:
		target = self
	var original_pos := target.position
	var tween := create_tween()
	if tween == null:
		return
	tween.tween_property(target, "position", original_pos + Vector2(0.0, -4.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", original_pos, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
