extends Area2D
class_name HearthwoodRustlingBush

signal bush_rustled(bush_id: String)

@export var bush_id: String = ""
@export var sway_intensity: float = 0.15
@export var bush_radius: float = 14.0

var is_swaying: bool = false


func _init() -> void:
	_ensure_collision_shape()


func _ready() -> void:
	_ensure_collision_shape()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	queue_redraw()


func _ensure_collision_shape() -> void:
	var existing_col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if existing_col == null:
		existing_col = CollisionShape2D.new()
		existing_col.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = bush_radius
		existing_col.shape = circle
		add_child(existing_col)
	elif existing_col.shape is CircleShape2D:
		(existing_col.shape as CircleShape2D).radius = bush_radius


func trigger_rustle() -> void:
	bush_rustled.emit(bush_id)
	_play_sway_animation()


func _on_body_entered(body: Node2D) -> void:
	if _is_player_body(body):
		trigger_rustle()


func _is_player_body(body: Node2D) -> bool:
	if body == null:
		return false
	return (
		body.name == "Player"
		or body.is_in_group("player")
		or body.get("is_player") == true
		or body is CharacterBody2D
	)


func _play_sway_animation() -> void:
	if not is_inside_tree():
		return
	if is_swaying:
		return
	var tween := create_tween()
	if tween == null:
		return

	is_swaying = true
	var original_rot := rotation
	tween.tween_property(self, "rotation", original_rot + sway_intensity, 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation", original_rot - sway_intensity * 0.8, 0.07).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation", original_rot + sway_intensity * 0.4, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation", original_rot, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): is_swaying = false)


func _draw() -> void:
	# Subtle ground contact shadow
	draw_circle(Vector2(0.0, 4.0), 13.0, Color(0.08, 0.12, 0.08, 0.28))

	# Deep foliage base / silhouette (#1E3A1A)
	draw_circle(Vector2(-7.0, 2.0), 8.5, Color("#1e3a1a"))
	draw_circle(Vector2(7.0, 2.0), 8.5, Color("#1e3a1a"))
	draw_circle(Vector2(0.0, -3.0), 10.5, Color("#1e3a1a"))
	draw_circle(Vector2(-4.0, -5.0), 8.0, Color("#1e3a1a"))
	draw_circle(Vector2(4.0, -5.0), 8.0, Color("#1e3a1a"))

	# Mid-tone leafy clusters (#294D35)
	draw_circle(Vector2(-6.0, 1.0), 7.0, Color("#294d35"))
	draw_circle(Vector2(6.0, 1.0), 7.0, Color("#294d35"))
	draw_circle(Vector2(0.0, -3.0), 8.5, Color("#294d35"))
	draw_circle(Vector2(-3.0, -6.0), 6.5, Color("#294d35"))
	draw_circle(Vector2(3.0, -6.0), 6.5, Color("#294d35"))

	# Highlight leaf tips & vibrant crown clusters (#4A6B3A)
	draw_circle(Vector2(-4.0, -4.0), 4.5, Color("#4a6b3a"))
	draw_circle(Vector2(4.0, -4.0), 4.0, Color("#4a6b3a"))
	draw_circle(Vector2(0.0, -7.0), 4.5, Color("#4a6b3a"))
	draw_circle(Vector2(-6.0, -1.0), 3.0, Color("#4a6b3a"))
	draw_circle(Vector2(6.0, -1.0), 3.0, Color("#4a6b3a"))
	draw_circle(Vector2(0.0, 0.0), 3.5, Color("#4a6b3a"))
