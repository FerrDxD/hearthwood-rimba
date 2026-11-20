extends "res://scripts/world/InteractiveProp.gd"
class_name HearthwoodNoticeBoard

signal notice_read(notice_data: Dictionary)

const CRAVING_HINTS: Array[String] = [
	"Pak Udin terlihat memandangi warung sambil bergumam ingin menyantap masakan bumbu rempah yang gurih...",
	"Casha menyukai hidangan beraroma sayur asam segar dan selalu penasaran mencicipi menu baru...",
	"Budi sang pandai besi membutuhkan santapan hangat berenergi tinggi untuk menemaninya menempa...",
	"Arin sang pustakawan mencari kudapan manis yang menenangkan saat membaca buku sejarah kuno...",
	"Talia sang herbalis menyukai sup herba hangat untuk memulihkan stamina di malam hari...",
	"Giral sang pedagang keliling merindukan olahan ikan sungai berkuah lezat berbumbu tajam...",
	"Rast si penjelajah mengidamkan bekal daging panggang asap untuk ekspedisi menjelajah rimba..."
]

const MAYOR_NOTE: String = "Pesan Kepala Desa Veral: Selamat datang di Hearthwood. Jagalah kebersihan dan kehangatan desa kita."

var is_animating: bool = false


func _init() -> void:
	super._init()
	prop_id = "notice_board"
	prop_type = "notice_board"
	interaction_prompt = "Baca Pengumuman"
	interaction_radius = 48.0


func _ready() -> void:
	super._ready()
	queue_redraw()


func can_interact() -> bool:
	return true


func get_daily_notice() -> Dictionary:
	var weather_name := "Cerah"
	var day_number: int = 1

	var game_state := _get_game_state()
	if game_state != null:
		if "current_weather" in game_state and not str(game_state.current_weather).is_empty():
			weather_name = str(game_state.current_weather).capitalize()
		if "current_day" in game_state:
			day_number = maxi(1, int(game_state.current_day))

	var hint_index := (day_number - 1) % CRAVING_HINTS.size()
	var craving_hint := CRAVING_HINTS[hint_index]

	return {
		"weather": weather_name,
		"craving_hint": craving_hint,
		"mayor_note": MAYOR_NOTE
	}


func interact(player: Node2D = null) -> Dictionary:
	daily_interacted = true
	_play_read_animation()

	var notice := get_daily_notice()
	notice_read.emit(notice)

	var success_result := {
		"success": true,
		"message": "Warta Desa Hearthwood",
		"data": notice
	}
	interacted.emit(success_result)
	return success_result


func reset_daily() -> void:
	super.reset_daily()
	daily_interacted = false


func _play_read_animation() -> void:
	if not is_inside_tree() or is_animating:
		return
	var target: Node2D = get_node_or_null("Sprite2D") as Node2D
	if target == null:
		target = self
	var original_scale := target.scale
	var tween := create_tween()
	if tween == null:
		return

	is_animating = true
	# Gentle scale pulse giving responsive tactile click feedback
	tween.tween_property(target, "scale", original_scale * 1.05, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", original_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): is_animating = false)


func _draw() -> void:
	# Subtle ground contact shadows under wooden posts
	draw_circle(Vector2(-12.0, 18.0), 6.0, Color(0.10, 0.12, 0.10, 0.28))
	draw_circle(Vector2(12.0, 18.0), 6.0, Color(0.10, 0.12, 0.10, 0.28))

	# Left wooden post (#76513A)
	draw_rect(Rect2(-15.0, -12.0, 5.0, 30.0), Color("#76513A"))
	draw_line(Vector2(-15.0, -12.0), Vector2(-15.0, 18.0), Color("#946C51"), 1.0)
	draw_line(Vector2(-11.0, -12.0), Vector2(-11.0, 18.0), Color("#4E3524"), 1.0)

	# Right wooden post (#76513A)
	draw_rect(Rect2(10.0, -12.0, 5.0, 30.0), Color("#76513A"))
	draw_line(Vector2(10.0, -12.0), Vector2(10.0, 18.0), Color("#946C51"), 1.0)
	draw_line(Vector2(14.0, -12.0), Vector2(14.0, 18.0), Color("#4E3524"), 1.0)

	# Wooden backboard backing frame (#5C3A1E)
	draw_rect(Rect2(-19.0, -23.0, 38.0, 26.0), Color("#4A2E17"))
	draw_rect(Rect2(-18.0, -22.0, 36.0, 24.0), Color("#5C3A1E"))

	# Wooden board interior horizontal slats (#76513A)
	draw_rect(Rect2(-16.0, -20.0, 32.0, 20.0), Color("#76513A"))
	draw_line(Vector2(-16.0, -14.0), Vector2(16.0, -14.0), Color("#4E3524"), 1.0)
	draw_line(Vector2(-16.0, -7.0), Vector2(16.0, -7.0), Color("#4E3524"), 1.0)

	# Small protective roof overhang (#5C3A1E)
	var roof_pts: PackedVector2Array = [
		Vector2(-22.0, -22.0),
		Vector2(0.0, -31.0),
		Vector2(22.0, -22.0)
	]
	draw_colored_polygon(roof_pts, Color("#5C3A1E"))
	draw_line(Vector2(-23.0, -21.0), Vector2(0.0, -32.0), Color("#8F654A"), 2.0)
	draw_line(Vector2(0.0, -32.0), Vector2(23.0, -21.0), Color("#3E2614"), 2.0)

	# Parchment notice sheets (#F5F5DC and warm ivory #FAF8EB)
	# Left sheet: Quest / village bulletin
	draw_rect(Rect2(-14.0, -18.0, 12.0, 15.0), Color("#E3DFBF")) # Shadow rim
	draw_rect(Rect2(-13.0, -17.0, 11.0, 14.0), Color("#F5F5DC"))
	draw_line(Vector2(-11.0, -14.0), Vector2(-4.0, -14.0), Color("#7A7265"), 1.0)
	draw_line(Vector2(-11.0, -11.0), Vector2(-5.0, -11.0), Color("#7A7265"), 1.0)
	draw_line(Vector2(-11.0, -8.0), Vector2(-6.0, -8.0), Color("#7A7265"), 1.0)
	draw_line(Vector2(-11.0, -5.0), Vector2(-8.0, -5.0), Color("#7A7265"), 1.0)

	# Right sheet: Craving / market notice
	draw_rect(Rect2(2.0, -16.0, 12.0, 14.0), Color("#E3DFBF")) # Shadow rim
	draw_rect(Rect2(3.0, -15.0, 11.0, 13.0), Color("#FAF8EB"))
	draw_line(Vector2(5.0, -12.0), Vector2(12.0, -12.0), Color("#7A7265"), 1.0)
	draw_line(Vector2(5.0, -9.0), Vector2(11.0, -9.0), Color("#7A7265"), 1.0)
	draw_line(Vector2(5.0, -6.0), Vector2(10.0, -6.0), Color("#7A7265"), 1.0)

	# Red sealing wax pins / dots (#B8482D)
	draw_circle(Vector2(-8.0, -16.0), 1.5, Color("#B8482D"))
	draw_circle(Vector2(-8.5, -16.5), 0.5, Color("#E2725B")) # Wax gloss highlight
	draw_circle(Vector2(8.0, -14.0), 1.5, Color("#B8482D"))
	draw_circle(Vector2(7.5, -14.5), 0.5, Color("#E2725B")) # Wax gloss highlight
