extends "res://scripts/world/InteractiveProp.gd"
class_name HearthwoodFreshSpring

signal spring_used(energy_restored: int)

@export var energy_restore: int = 10


func _init() -> void:
	super._init()
	prop_type = "fresh_spring"
	interaction_prompt = "Basuh Muka"


func can_interact() -> bool:
	return not daily_interacted


func interact(player: Node2D = null) -> Dictionary:
	if daily_interacted:
		var fail_result := {
			"success": false,
			"message": "Kamu sudah membasuh muka hari ini. Airnya terasa sejuk mengalir.",
			"data": null
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

	_play_ripple_effect()
	spring_used.emit(energy_restore)

	var success_result := {
		"success": true,
		"message": "Kamu membasuh muka dengan air mata air pegunungan yang jernih. Energi pulih +%d!" % energy_restore,
		"data": {
			"energy_restored": energy_restore
		}
	}
	interacted.emit(success_result)
	return success_result


func reset_daily() -> void:
	super.reset_daily()


func _play_ripple_effect() -> void:
	if not is_inside_tree():
		return
	var target: Node2D = get_node_or_null("Sprite2D") as Node2D
	if target == null:
		target = self
	var original_scale := target.scale
	var tween := create_tween()
	if tween == null:
		return
	tween.tween_property(target, "scale", original_scale * 1.08, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", original_scale, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
