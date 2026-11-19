# tests/ZoneGateTest.gd
extends SceneTree

func _init() -> void:
	var script = load("res://scripts/world/ZoneGate2D.gd")
	assert(script != null, "ZoneGate2D.gd must exist")
	var gate = script.new()
	gate.target_zone_id = "forest_zone_3"
	gate.target_spawn_position = Vector2(250.0, 100.0)
	gate.is_blocked = false
	
	var received: Dictionary = {"zone": "", "pos": Vector2.ZERO}
	gate.gate_triggered.connect(func(z, p):
		received["zone"] = z
		received["pos"] = p
	)
	
	gate.trigger_transition()
	assert(received["zone"] == "forest_zone_3", "Target zone must match")
	assert(received["pos"] == Vector2(250.0, 100.0), "Spawn pos must match")
	
	# Blocked gate test
	gate.is_blocked = true
	var blocked_triggered: Array = [false]
	var blocked_connection = gate.gate_triggered.connect(func(z, p): blocked_triggered[0] = true)
	gate.trigger_transition()
	assert(blocked_triggered[0] == false, "Blocked gate must not emit transition")
	
	# Dialog trigger on blocked attempt
	assert("blocked_dialog_key" in gate, "Gate must have blocked_dialog_key")
	gate.blocked_dialog_key = "forest_gate_blocked"
	assert(gate.blocked_dialog_key == "forest_gate_blocked", "Gate blocked_dialog_key must store string")

	var blocked_attempt_called: Array = [false]
	var received_dialog_key: Array = [""]
	gate.blocked_attempted.connect(func(g, k):
		blocked_attempt_called[0] = true
		received_dialog_key[0] = k
	)
	gate.trigger_transition()
	assert(blocked_attempt_called[0] == true, "blocked_attempted must be emitted when blocked")
	assert(received_dialog_key[0] == "forest_gate_blocked", "dialog key must match")
	
	# Test body entered handling
	gate.is_blocked = false
	received["zone"] = ""
	received["pos"] = Vector2.ZERO
	
	# Random node should not trigger
	var dummy_node = Node2D.new()
	dummy_node.name = "Rock"
	gate._on_body_entered(dummy_node)
	assert(received["zone"] == "", "Non-player node should not trigger gate")
	dummy_node.free()
	
	# Player body should trigger
	var player_body = CharacterBody2D.new()
	player_body.name = "Player"
	gate._on_body_entered(player_body)
	assert(received["zone"] == "forest_zone_3", "Player body must trigger gate")
	player_body.free()

	gate.free()
	print("ZoneGateTest passed.")
	quit(0)
