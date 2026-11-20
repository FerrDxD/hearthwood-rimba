extends "res://scripts/world/InteractiveProp.gd"
class_name HearthwoodFruitTree

signal fruit_harvested(item_id: String, count: int)

const ITEM_PICKUP_SCENE_PATH: String = "res://scenes/ItemPickup.tscn"

@export var fruit_item_id: String = "buah_liar"
@export var min_drop: int = 1
@export var max_drop: int = 3
@export var has_fruit: bool = true


func _init() -> void:
	super._init()
	prop_type = "fruit_tree"
	interaction_prompt = "Petik Buah"


func can_interact() -> bool:
	return has_fruit and not daily_interacted


func interact(player: Node2D = null) -> Dictionary:
	if daily_interacted or not has_fruit:
		var fail_result := {
			"success": false,
			"message": "Pohon ini sudah dipetik hari ini. Tunggu esok hari.",
			"data": 0
		}
		interacted.emit(fail_result)
		return fail_result

	daily_interacted = true
	has_fruit = false

	var drop_count := randi_range(min_drop, max_drop)
	_play_shake_animation()
	var spawned_pickups := _spawn_pickups(drop_count)
	fruit_harvested.emit(fruit_item_id, drop_count)

	var success_result := {
		"success": true,
		"message": "Kamu memetik %d %s dari pohon." % [drop_count, fruit_item_id],
		"data": {
			"item_id": fruit_item_id,
			"count": drop_count,
			"pickups": spawned_pickups
		}
	}
	interacted.emit(success_result)
	return success_result


func reset_daily() -> void:
	super.reset_daily()
	has_fruit = true


func _play_shake_animation() -> void:
	if not is_inside_tree():
		return
	var target: Node2D = get_node_or_null("Sprite2D") as Node2D
	if target == null:
		target = self
	var original_rot := target.rotation
	var tween := create_tween()
	if tween == null:
		return
	tween.tween_property(target, "rotation", original_rot + 0.08, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "rotation", original_rot - 0.08, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "rotation", original_rot + 0.04, 0.04).set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "rotation", original_rot, 0.04).set_trans(Tween.TRANS_SINE)


func _spawn_pickups(count: int) -> Array[Node2D]:
	var spawned: Array[Node2D] = []
	var parent_node := get_parent()
	if parent_node == null:
		return spawned
	if not ResourceLoader.exists(ITEM_PICKUP_SCENE_PATH):
		return spawned
	var pickup_scene := load(ITEM_PICKUP_SCENE_PATH) as PackedScene
	if pickup_scene == null:
		return spawned

	for i in range(count):
		var pickup := pickup_scene.instantiate() as Node2D
		var offset := Vector2(randf_range(-24.0, 24.0), randf_range(8.0, 28.0))
		var spawn_pos := global_position + offset
		var drop_id := "%s_harvest_%d_%d" % [prop_id, Time.get_ticks_msec(), i]
		if pickup.has_method("configure"):
			pickup.configure(fruit_item_id, spawn_pos, drop_id)
		parent_node.add_child(pickup)
		if "_item_pickups" in parent_node and parent_node.get("_item_pickups") is Array:
			parent_node._item_pickups.append(pickup)
		spawned.append(pickup)
	return spawned
