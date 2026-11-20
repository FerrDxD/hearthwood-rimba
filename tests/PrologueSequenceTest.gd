# tests/PrologueSequenceTest.gd
extends SceneTree

const PROLOGUE_SCENE: PackedScene = preload("res://scenes/ui/PrologueSequence.tscn")

func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# --- Test 1: Instantiation, touch targets, and skip button ---
	var sequence := PROLOGUE_SCENE.instantiate()
	root.add_child(sequence)
	if sequence == null:
		_fail("PrologueSequence instance must be valid")
		return

	if sequence.is_running():
		_fail("Sequence should not be running before start_sequence is called")
		return

	var skip_btn: Button = sequence.get_skip_button()
	if skip_btn == null:
		_fail("Skip button must exist")
		return

	if skip_btn.custom_minimum_size.x < 44.0 or skip_btn.custom_minimum_size.y < 44.0:
		_fail("Skip button must meet touch target minimum (>= 44x44)")
		return

	var completed := [false]
	sequence.sequence_completed.connect(func() -> void: completed[0] = true)

	sequence.start_sequence("Danu")
	if not sequence.is_running():
		_fail("Sequence must be marked running after start_sequence")
		return

	# Test Skip Button emit sequence_completed
	skip_btn.pressed.emit()
	await process_frame

	if not completed[0]:
		_fail("Sequence must emit sequence_completed on skip")
		return

	if sequence.is_running():
		_fail("Sequence must not be running after skip")
		return

	sequence.queue_free()
	await process_frame

	# --- Test 2: Advancing lines, typewriter reveal, and completion ---
	var seq2 := PROLOGUE_SCENE.instantiate()
	root.add_child(seq2)
	var seq2_completed := [false]
	seq2.sequence_completed.connect(func() -> void: seq2_completed[0] = true)

	seq2.start_sequence("Bima")
	if not seq2.is_running():
		_fail("Seq2 must be running")
		return

	# First line should format player_name
	var first_text: String = seq2.get_current_line_text()
	if not first_text.contains("Bima"):
		_fail("First monologue text should format player_name 'Bima'")
		return

	# Fast typewriter complete on click/advance
	if seq2.is_typing():
		seq2.advance_sequence()
		if seq2.is_typing():
			_fail("Advancing while typing should complete typewriter immediately")
			return

	# Advance through all lines until completion
	var max_steps := 25
	var step_count := 0
	while not seq2_completed[0] and step_count < max_steps:
		step_count += 1
		seq2.advance_sequence()
		await process_frame

	if not seq2_completed[0]:
		_fail("Advancing through all lines should emit sequence_completed")
		return

	seq2.queue_free()
	await process_frame

	print("PrologueSequenceTest passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error("PrologueSequenceTest FAILED: " + message)
	quit(1)
