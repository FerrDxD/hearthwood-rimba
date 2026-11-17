extends Node2D

const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const PLAYER_START: Vector2 = Vector2(210.0, 432.0)

var _world: HearthwoodWorld
var _player: CharacterBody2D
var _clock_label: Label
var _energy_label: Label
var _energy_bar: ProgressBar
var _hint_label: Label


func _ready() -> void:
	_world = WORLD_SCENE.instantiate()
	add_child(_world)

	_player = PLAYER_SCENE.instantiate()
	_player.position = PLAYER_START
	add_child(_player)

	var camera: Camera2D = _player.get_node("camera2d")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1600
	camera.limit_bottom = 880

	_create_hud()
	_connect_signals()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		_interact()


func _process(_delta: float) -> void:
	if _world.is_near_bed(_player.global_position):
		_hint_label.text = "Tempat istirahat  |  E untuk tidur dan berganti hari"
	else:
		_hint_label.text = "WASD / panah untuk bergerak  |  E untuk berinteraksi"


func _connect_signals() -> void:
	var game_state = get_node("/root/GameState")
	var time_system = get_node("/root/TimeSystem")
	game_state.energy_changed.connect(_update_energy)
	time_system.hour_changed.connect(_update_hud)
	time_system.day_changed.connect(_update_hud)
	time_system.minute_changed.connect(_on_minute_changed)


func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var interface := Control.new()
	interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(interface)

	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(16.0, 16.0)
	interface.add_child(status_panel)
	var status_layout := VBoxContainer.new()
	status_panel.add_child(status_layout)

	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", 20)
	status_layout.add_child(_clock_label)

	_energy_label = Label.new()
	status_layout.add_child(_energy_label)

	_energy_bar = ProgressBar.new()
	_energy_bar.custom_minimum_size = Vector2(180.0, 18.0)
	_energy_bar.max_value = 100.0
	_energy_bar.show_percentage = false
	status_layout.add_child(_energy_bar)

	_hint_label = Label.new()
	_hint_label.position = Vector2(16.0, 106.0)
	_hint_label.add_theme_font_size_override("font_size", 15)
	interface.add_child(_hint_label)

	var controls := TouchControls.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interface.add_child(controls)
	controls.interact_pressed.connect(_interact)

	_hint_label.text = "WASD / panah untuk bergerak  |  E untuk berinteraksi"


func _update_hud(_value: int = 0, _minute: int = 0) -> void:
	var game_state = get_node("/root/GameState")
	_clock_label.text = "Hari %d  |  %02d:%02d" % [
		game_state.current_day,
		game_state.current_hour % 24,
		game_state.current_minute,
	]
	_update_energy(game_state.energy)


func _update_energy(value: int) -> void:
	_energy_label.text = "Energi: %d / %d" % [value, 100]
	_energy_bar.value = value


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	_update_hud()


func _interact() -> void:
	if _world.is_near_bed(_player.global_position):
		get_node("/root/TimeSystem").sleep()
		_hint_label.text = "Hari baru dimulai. Energi sudah pulih."
	else:
		_hint_label.text = "Jelajahi jalan menuju desa untuk menemukan tempat beristirahat."
