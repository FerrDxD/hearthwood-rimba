extends Control
class_name TouchControls

signal interact_pressed
signal inventory_pressed

const JOYSTICK_RADIUS: float = 54.0
const BUTTON_RADIUS: float = 42.0
const INVENTORY_RADIUS: float = 35.0

var _joystick_touch: int = -1
var _interact_touch: int = -1
var _mouse_joystick: bool = false
var _mouse_interact: bool = false
var _stick_vector: Vector2 = Vector2.ZERO
var _stick_center: Vector2
var _button_center: Vector2
var _inventory_center: Vector2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_update_centers)
	_update_centers()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		if event.index == _joystick_touch:
			_update_stick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _mouse_joystick:
		_update_stick(event.position)


func _draw() -> void:
	draw_circle(_stick_center, JOYSTICK_RADIUS, Color(0.14, 0.17, 0.14, 0.36))
	draw_circle(_stick_center, JOYSTICK_RADIUS - 3.0, Color(0.89, 0.84, 0.68, 0.35))
	draw_circle(
		_stick_center + _stick_vector * (JOYSTICK_RADIUS - 18.0),
		20.0,
		Color(0.47, 0.40, 0.27, 0.76)
	)
	draw_circle(_button_center, BUTTON_RADIUS, Color(0.56, 0.32, 0.19, 0.72))
	draw_circle(_button_center, BUTTON_RADIUS - 4.0, Color(0.78, 0.58, 0.36, 0.86))
	draw_string(
		ThemeDB.fallback_font,
		_button_center + Vector2(-14.0, 6.0),
		"E",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		20,
		Color("#fff9e7")
	)
	draw_circle(_inventory_center, INVENTORY_RADIUS, Color(0.56, 0.32, 0.19, 0.72))
	draw_circle(
		_inventory_center,
		INVENTORY_RADIUS - 4.0,
		Color(0.78, 0.58, 0.36, 0.86)
	)
	draw_string(
		ThemeDB.fallback_font,
		_inventory_center + Vector2(-7.0, 6.0),
		"I",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		20,
		Color("#fff9e7")
	)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if event.position.distance_to(_stick_center) <= JOYSTICK_RADIUS * 1.7:
			_joystick_touch = event.index
			_update_stick(event.position)
		elif event.position.distance_to(_button_center) <= BUTTON_RADIUS * 1.5:
			_interact_touch = event.index
			Input.action_press("interact")
			interact_pressed.emit()
		elif event.position.distance_to(_inventory_center) <= INVENTORY_RADIUS * 1.5:
			inventory_pressed.emit()
	else:
		if event.index == _joystick_touch:
			_joystick_touch = -1
			_set_movement(Vector2.ZERO)
		if event.index == _interact_touch:
			_interact_touch = -1
			Input.action_release("interact")


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.pressed:
		if event.position.distance_to(_stick_center) <= JOYSTICK_RADIUS * 1.7:
			_mouse_joystick = true
			_update_stick(event.position)
		elif event.position.distance_to(_button_center) <= BUTTON_RADIUS * 1.5:
			_mouse_interact = true
			Input.action_press("interact")
			interact_pressed.emit()
		elif event.position.distance_to(_inventory_center) <= INVENTORY_RADIUS * 1.5:
			inventory_pressed.emit()
	else:
		if _mouse_joystick:
			_mouse_joystick = false
			_set_movement(Vector2.ZERO)
		if _mouse_interact:
			_mouse_interact = false
			Input.action_release("interact")


func _update_stick(position: Vector2) -> void:
	var offset := position - _stick_center
	_stick_vector = offset.limit_length(JOYSTICK_RADIUS) / JOYSTICK_RADIUS
	_set_movement(_stick_vector)
	queue_redraw()


func _set_movement(direction: Vector2) -> void:
	_set_action_strength("move_left", maxf(0.0, -direction.x))
	_set_action_strength("move_right", maxf(0.0, direction.x))
	_set_action_strength("move_up", maxf(0.0, -direction.y))
	_set_action_strength("move_down", maxf(0.0, direction.y))
	if direction == Vector2.ZERO:
		_stick_vector = Vector2.ZERO
		queue_redraw()


func _set_action_strength(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _update_centers() -> void:
	_stick_center = Vector2(92.0, size.y - 104.0)
	_button_center = Vector2(size.x - 92.0, size.y - 104.0)
	_inventory_center = Vector2(size.x - 92.0, size.y - 202.0)
	queue_redraw()
