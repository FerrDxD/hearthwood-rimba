extends Area2D
class_name ZoneGate2D

signal gate_triggered(target_zone_id: String, target_spawn_pos: Vector2)
signal blocked_attempted(gate: ZoneGate2D, dialog_key: String)

@export var target_zone_id: String = ""
@export var target_spawn_position: Vector2 = Vector2.ZERO
@export var is_blocked: bool = false
@export var blocked_dialog_key: String = ""
@export var source_zone_id: String = ""


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func trigger_transition() -> bool:
	if is_blocked:
		blocked_attempted.emit(self, blocked_dialog_key)
		return false
	gate_triggered.emit(target_zone_id, target_spawn_position)
	return true


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and (body.name == "Player" or body.is_in_group("player") or body.get("is_player") == true):
		trigger_transition()
