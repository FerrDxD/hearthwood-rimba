extends Area2D
class_name HearthwoodInteractiveProp

signal interacted(result: Dictionary)
signal daily_reset
signal player_approached
signal player_departed

@export var prop_id: String = ""
@export var prop_type: String = ""
@export var daily_interacted: bool = false
@export var interaction_prompt: String = "Periksa"
@export var interaction_radius: float = 48.0:
	set(value):
		interaction_radius = value
		_update_collision_shape_radius()

var is_player_nearby: bool = false


func _init() -> void:
	_ensure_collision_shape()


func _ready() -> void:
	_ensure_collision_shape()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _ensure_collision_shape() -> void:
	var existing_col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if existing_col == null:
		existing_col = CollisionShape2D.new()
		existing_col.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = interaction_radius
		existing_col.shape = circle
		add_child(existing_col)
	elif existing_col.shape is CircleShape2D:
		(existing_col.shape as CircleShape2D).radius = interaction_radius


func _update_collision_shape_radius() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = interaction_radius


func can_interact() -> bool:
	return not daily_interacted


func interact(_player: Node2D = null) -> Dictionary:
	if not can_interact():
		var fail_result := {
			"success": false,
			"message": "Objek ini sudah diperiksa hari ini.",
			"data": null
		}
		interacted.emit(fail_result)
		return fail_result

	daily_interacted = true
	var success_result := {
		"success": true,
		"message": "Kamu memeriksa objek lingkungan.",
		"data": null
	}
	interacted.emit(success_result)
	return success_result


func reset_daily() -> void:
	daily_interacted = false
	daily_reset.emit()


func _on_body_entered(body: Node2D) -> void:
	if _is_player_body(body):
		is_player_nearby = true
		player_approached.emit()


func _on_body_exited(body: Node2D) -> void:
	if _is_player_body(body):
		is_player_nearby = false
		player_departed.emit()


func _is_player_body(body: Node2D) -> bool:
	if body == null:
		return false
	return body.name == "Player" or body.is_in_group("player") or body.get("is_player") == true


func _get_game_state() -> Node:
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	if is_inside_tree() and get_tree().root.has_node("GameState"):
		return get_tree().root.get_node("GameState")
	var loop := Engine.get_main_loop()
	if loop is SceneTree and loop.root and loop.root.has_node("GameState"):
		return loop.root.get_node("GameState")
	return null
