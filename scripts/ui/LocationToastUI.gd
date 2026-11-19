extends Control
class_name HearthwoodLocationToastUI

var _label: Label
var _tween: Tween
var _location_text: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0
	_get_label()
	if _label != null and not _location_text.is_empty():
		_label.text = _location_text


func _get_label() -> Label:
	if _label == null:
		_label = find_child("Label", true, false) as Label
	return _label


func show_location(zone_name: String) -> void:
	_location_text = zone_name
	var lbl := _get_label()
	if lbl != null:
		lbl.text = zone_name
	visible = true
	if is_inside_tree():
		if _tween != null and _tween.is_valid():
			_tween.kill()
		modulate.a = 0.0
		_tween = create_tween()
		_tween.tween_property(self, "modulate:a", 1.0, 0.25)
		_tween.tween_interval(2.5)
		_tween.tween_property(self, "modulate:a", 0.0, 0.35)
		_tween.tween_callback(func():
			visible = false
			modulate.a = 0.0
		)
	else:
		modulate.a = 1.0


func get_location_text() -> String:
	var lbl := _get_label()
	if lbl != null:
		return lbl.text
	return _location_text


func is_visible_or_animating() -> bool:
	if not visible:
		return false
	if _tween != null and _tween.is_valid() and _tween.is_running():
		return true
	return modulate.a > 0.01
