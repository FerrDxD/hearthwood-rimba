extends CharacterBody2D

const CHARACTER_VISUAL_SCRIPT: Script = preload("res://scripts/characters/CharacterVisual.gd")

@export var walk_speed: float = 140.0
@export var world_bounds: Rect2 = Rect2(16.0, 16.0, 1568.0, 848.0)
@export var forest_end_x: float = 560.0

var _game_state: Node


func _ready() -> void:
	_game_state = get_node("/root/GameState")
	get_node("/root/TimeSystem").minute_changed.connect(_on_minute_changed)
	var character_visual = CHARACTER_VISUAL_SCRIPT.new()
	character_visual.name = "characterVisual"
	add_child(character_visual)
	character_visual.configure(
		Color("#8b4513"),
		Color("#556b2f"),
		Color("#654321")
	)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * walk_speed
	move_and_slide()
	global_position.x = clampf(global_position.x, world_bounds.position.x, world_bounds.end.x)
	global_position.y = clampf(global_position.y, world_bounds.position.y, world_bounds.end.y)


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	if global_position.x < forest_end_x and velocity.length_squared() > 1.0:
		_game_state.change_energy(-2)
