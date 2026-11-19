# Peta Multi-Zona Hutan Terhubung Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Memecah area hutan Hearthwood menjadi 6 wilayah terhubung ala Harvest Moon dengan transisi layar instan, gating pohon tumbang via quest Rast Hati 2, redistribusi foraging tematik, dan toast UI nama lokasi.

**Architecture:** Menggunakan arsitektur Zone Container di `World.gd` dengan koordinat global terpisah (non-overlapping offset bounds). Pergantian wilayah dipicu oleh `ZoneGate2D`, mengeksekusi fade out/in instan 0,2 detik pada CanvasLayer, memperbarui batas `Camera2D`, dan menjaga data entitas tetap hidup di memori tanpa reload scene.

**Tech Stack:** Godot 4.7.2 (GDScript), 2D Pixel Snap, Nearest Texture Filter, JSON Data-Driven.

**Spec:** [docs/superpowers/specs/2026-11-19-peta-multi-zona-hutan-design.md](file:///C:/Users/Hype%20GLK/hearthwood-rimba/docs/superpowers/specs/2026-11-19-peta-multi-zona-hutan-design.md) dan [PRD Hearthwood Warung Rimba (Versi 0.3.0).md](file:///C:/Users/Hype%20GLK/hearthwood-rimba/PRD%20Hearthwood%20Warung%20Rimba%20(Versi%200.3.0).md)

## Global Constraints

- Engine: Godot 4.7.2 stable standar, render Nearest, pixel snap aktif.
- Gaya Penamaan: Scene `PascalCase.tscn`, Skrip `PascalCase.gd`, Node `camelCase`, Sinyal `snake_case`, Variabel `snake_case`, File Data `snake_case.json`.
- Kompatibilitas Save: File `user://savegame.json` versi v1.0 dan v0.2.0 harus tetap bisa dimuat tanpa crash.
- Mobile First: Touch area minimal 44×44 dp, transisi layar zero-stutter di Android.
- Alur Waktu: 1 menit game = 1,5 detik nyata, waktu mengalir alami secara real-time tanpa penalti waktu instan saat berpindah zona.

## Review Focus

1. **Pemain menyentuh batas zona saat sedang bergerak cepat / analog joystick tertahan:** Posisi kedatangan pemain di zona baru harus berjarak aman dari trigger gerbang masuk agar tidak terjadi loop teleportasi bolak-balik tanpa akhir.
2. **Pemain memuat save game versi lama (v0.2.0) di mana Quest Rast Hati 2 sudah selesai:** State `is_deep_forest_unlocked` harus otomatis terinisialisasi `true` agar jalur hutan dalam langsung terbuka.
3. **Pemain mencoba kembali ke Wilayah 6 sebelum Quest Rast Hati 2 selesai:** Batang pohon tumbang harus secara konsisten memblokir fisik pemain dan memunculkan dialog petunjuk tanpa crash.
4. **NPC ambient saat pergantian hari atau cuaca hujan:** Sistem spawn ambient NPC tidak boleh menaruh karakter apa pun di koordinat 6 zona hutan.
5. **Transisi zona saat jam operasional toko atau cuaca badai:** Sinyal pergantian jam dan cuaca harus tetap diterima dengan benar oleh entitas di zona aktif maupun yang disembunyikan.

---

### Task 1: Fondasi State `is_deep_forest_unlocked` & Serialisasi Save/Load

**Files:**
- Modify: `scripts/autoload/GameState.gd`
- Test: `tests/ZoneStateSaveTest.gd`

**Interfaces:**
- Consumes: `GameState` save/load structure.
- Produces: `GameState.is_deep_forest_unlocked: bool`, `GameState.deep_forest_unlocked_changed(unlocked: bool)`.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/ZoneStateSaveTest.gd
extends SceneTree

func _init() -> void:
	var game_state = load("res://scripts/autoload/GameState.gd").new()
	assert(game_state.get("is_deep_forest_unlocked") != null, "GameState must have is_deep_forest_unlocked")
	assert(game_state.is_deep_forest_unlocked == false, "Default is_deep_forest_unlocked must be false")
	
	# Test backward compatibility auto-unlock when Rast Heart 2 quest is already completed
	var mock_old_save = {
		"nama": "Pemain",
		"hari": 5,
		"jam": 10,
		"energi": 100,
		"reputasi": 20,
		"tier_warung": 2,
		"koin": 500,
		"inventori": [],
		"posisi": {"x": 1320.0, "y": 476.0},
		"quests": {
			"rast": {"current_chapter": 3, "heart_level": 2, "objective_index": 0, "completed": false}
		}
	}
	game_state._load_save_data(mock_old_save)
	assert(game_state.is_deep_forest_unlocked == true, "Save with Rast heart >= 2 must auto unlock deep forest")
	print("ZoneStateSaveTest passed.")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/ZoneStateSaveTest.gd`
Expected: FAIL with error that `is_deep_forest_unlocked` is not found or `_load_save_data` does not set it.

- [ ] **Step 3: Implement `is_deep_forest_unlocked` in `scripts/autoload/GameState.gd`**

Add variable `var is_deep_forest_unlocked: bool = false`, signal `signal deep_forest_unlocked_changed(unlocked: bool)`, include it in `_create_save_data()`, and in `_load_save_data()` add backward compatibility check: if `quests["rast"]["heart_level"] >= 2`, set `is_deep_forest_unlocked = true`.

- [ ] **Step 4: Run test to verify it passes**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/ZoneStateSaveTest.gd`
Expected: PASS with "ZoneStateSaveTest passed."

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/GameState.gd tests/ZoneStateSaveTest.gd
git commit -m "feat(zone): tambah state is_deep_forest_unlocked dan kompatibilitas save game"
```

---

### Task 2: Komponen Pemicu Transisi `ZoneGate2D`

**Files:**
- Create: `scripts/world/ZoneGate2D.gd`
- Test: `tests/ZoneGateTest.gd`

**Interfaces:**
- Consumes: `CollisionShape2D`, `Area2D`.
- Produces: `class_name ZoneGate2D`, `signal gate_triggered(target_zone_id: String, target_spawn_pos: Vector2)`.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/ZoneGateTest.gd
extends SceneTree

func _init() -> void:
	var script = load("res://scripts/world/ZoneGate2D.gd")
	assert(script != null, "ZoneGate2D.gd must exist")
	var gate = script.new()
	gate.target_zone_id = "forest_zone_3"
	gate.target_spawn_position = Vector2(250.0, 100.0)
	gate.is_blocked = false
	
	var received_zone = ""
	var received_pos = Vector2.ZERO
	gate.gate_triggered.connect(func(z, p):
		received_zone = z
		received_pos = p
	)
	
	gate.trigger_transition()
	assert(received_zone == "forest_zone_3", "Target zone must match")
	assert(received_pos == Vector2(250.0, 100.0), "Spawn pos must match")
	
	# Blocked gate test
	gate.is_blocked = true
	var blocked_triggered = false
	gate.gate_triggered.connect(func(z, p): blocked_triggered = true)
	gate.trigger_transition()
	assert(blocked_triggered == false, "Blocked gate must not emit transition")
	
	print("ZoneGateTest passed.")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/ZoneGateTest.gd`
Expected: FAIL because `ZoneGate2D.gd` does not exist yet.

- [ ] **Step 3: Implement `ZoneGate2D.gd` in `scripts/world/ZoneGate2D.gd`**

Create `ZoneGate2D.gd` extending `Area2D` with properties `target_zone_id: String`, `target_spawn_position: Vector2`, `is_blocked: bool = false`, `blocked_dialog_key: String = ""`, and method `trigger_transition()`. Connect `body_entered` to trigger transition if the body is player and not blocked.

- [ ] **Step 4: Run test to verify it passes**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/ZoneGateTest.gd`
Expected: PASS with "ZoneGateTest passed."

- [ ] **Step 5: Commit**

```bash
git add scripts/world/ZoneGate2D.gd tests/ZoneGateTest.gd
git commit -m "feat(zone): tambah komponen ZoneGate2D untuk pemicu transisi zona"
```

---

### Task 3: Arsitektur 6 Zona Rimba & Transisi Fade di `World.gd`

**Files:**
- Modify: `scripts/world/World.gd`
- Test: `tests/WorldZoneManagerTest.gd`

**Interfaces:**
- Consumes: `ZoneGate2D`, `GameState`.
- Produces: `current_zone_id: String`, `get_zone_rect(zone_id: String) -> Rect2`, `change_zone(zone_id: String, target_pos: Vector2, animated: bool)`.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/WorldZoneManagerTest.gd
extends SceneTree

func _init() -> void:
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	assert(world.has_method("get_zone_rect"), "World must implement get_zone_rect")
	assert(world.has_method("change_zone"), "World must implement change_zone")
	
	# Verify all 6 forest zones and village exist
	var expected_zones = ["village", "forest_zone_1", "forest_zone_2", "forest_zone_3", "forest_zone_4", "forest_zone_5", "forest_zone_6"]
	for zid in expected_zones:
		var rect: Rect2 = world.get_zone_rect(zid)
		assert(rect.size.x > 0 and rect.size.y > 0, "Zone " + zid + " must have valid rect size")
	
	# Verify village rect preserves existing world bounds
	var village_rect: Rect2 = world.get_zone_rect("village")
	assert(village_rect.has_point(world.BED_POSITION), "Village rect must contain bed position")
	assert(village_rect.has_point(world.COOKING_STATION_POSITION), "Village rect must contain cooking station")
	
	# Test changing zone
	world.change_zone("forest_zone_1", Vector2(100.0, 500.0), false)
	assert(world.current_zone_id == "forest_zone_1", "current_zone_id must update to forest_zone_1")
	
	world.free()
	print("WorldZoneManagerTest passed.")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/WorldZoneManagerTest.gd`
Expected: FAIL with `get_zone_rect` / `change_zone` not defined on `World`.

- [ ] **Step 3: Implement multi-zone container and transition in `scripts/world/World.gd`**

Define dictionaries for `ZONE_RECTS` mapping `village` to `Rect2(560.0, 0.0, 1040.0, 880.0)`, `forest_zone_6` to `Rect2(0.0, 0.0, 560.0, 480.0)`, `forest_zone_3` to `Rect2(0.0, 480.0, 560.0, 480.0)`, `forest_zone_1` to `Rect2(0.0, 960.0, 560.0, 480.0)`, `forest_zone_2` to `Rect2(-560.0, 960.0, 560.0, 480.0)`, `forest_zone_4` to `Rect2(560.0, -480.0, 560.0, 480.0)`, `forest_zone_5` to `Rect2(-560.0, 480.0, 560.0, 480.0)`. Implement `get_zone_rect(zone_id: String) -> Rect2`, `change_zone(zone_id: String, target_pos: Vector2, animated: bool)`, and zone gates connecting them with a 0.2s fade overlay.

- [ ] **Step 4: Run test to verify it passes**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/WorldZoneManagerTest.gd`
Expected: PASS with "WorldZoneManagerTest passed."

- [ ] **Step 5: Commit**

```bash
git add scripts/world/World.gd tests/WorldZoneManagerTest.gd
git commit -m "feat(zone): implementasi multi-zona rect dan pergantian zona di World.gd"
```

---

### Task 4: Pembatasan Ambient NPC & Jadwal Rast 06:00–16:00 di Wilayah 3

**Files:**
- Modify: `scripts/world/World.gd`
- Modify: `data/schedules.json`
- Test: `tests/ForestNPCIsolationTest.gd`

**Interfaces:**
- Consumes: `World._spawn_ambient_npcs()`, `World._named_npcs`.
- Produces: Ambient NPCs spawned strictly within `village` bounding box; Rast spawned in `forest_zone_3` during 06:00-16:00.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/ForestNPCIsolationTest.gd
extends SceneTree

func _init() -> void:
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	
	# Verify no ambient NPC is spawned in forest coordinates (x < 560.0)
	for npc in world._ambient_npcs:
		assert(npc.global_position.x >= 560.0, "Ambient NPC must only spawn in village: " + str(npc.global_position))
	
	# Verify Rast is placed in forest_zone_3 at 06:00
	var time_system = load("res://scripts/systems/TimeSystem.gd").new()
	time_system.current_hour = 6
	var rast_npc = world.get_named_npc("rast")
	assert(rast_npc != null, "Rast NPC must exist")
	var f3_rect = world.get_zone_rect("forest_zone_3")
	assert(f3_rect.has_point(rast_npc.global_position), "Rast must be located in forest_zone_3 during work hours")
	
	world.free()
	time_system.free()
	print("ForestNPCIsolationTest passed.")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/ForestNPCIsolationTest.gd`
Expected: FAIL if ambient NPCs or Rast spawn outside the specified boundaries.

- [ ] **Step 3: Update `World.gd` and `schedules.json`**

In `World._spawn_ambient_npcs()`, ensure all random spawn points are constrained to `Rect2(580.0, 100.0, 950.0, 700.0)` in the village. Update `schedules.json` to ensure Rast's work location targets `forest_zone_3` position from 06:00 to 16:00.

- [ ] **Step 4: Run test to verify it passes**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/ForestNPCIsolationTest.gd`
Expected: PASS with "ForestNPCIsolationTest passed."

- [ ] **Step 5: Commit**

```bash
git add scripts/world/World.gd data/schedules.json tests/ForestNPCIsolationTest.gd
git commit -m "feat(zone): batasi NPC ambient hanya di desa dan atur jadwal Rast di Wilayah 3"
```

---

### Task 5: Redistribusi Titik Foraging Tematik 6 Zona

**Files:**
- Modify: `scripts/world/World.gd`
- Test: `tests/ForageDistributionTest.gd`

**Interfaces:**
- Consumes: `FORAGE_SPAWN_POINTS` in `World.gd`.
- Produces: 12 forage items distributed across `forest_zone_1` through `forest_zone_6`.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/ForageDistributionTest.gd
extends SceneTree

func _init() -> void:
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	
	# Verify that each of the 6 zones contains forage spawn points according to spec
	var zones_with_forage = {}
	for spawn in world.FORAGE_SPAWN_POINTS:
		var pos: Vector2 = spawn["position"]
		var found_zone = ""
		for zid in ["forest_zone_1", "forest_zone_2", "forest_zone_3", "forest_zone_4", "forest_zone_5", "forest_zone_6"]:
			if world.get_zone_rect(zid).has_point(pos):
				found_zone = zid
				break
		assert(found_zone != "", "Forage point must belong to a defined zone: " + str(pos))
		zones_with_forage[found_zone] = true
	
	assert(zones_with_forage.size() >= 5, "At least 5 distinct forest zones must have forage spawns")
	
	world.free()
	print("ForageDistributionTest passed.")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/ForageDistributionTest.gd`
Expected: FAIL because forage spawn points currently all reside in the old single forest area.

- [ ] **Step 3: Update `FORAGE_SPAWN_POINTS` in `scripts/world/World.gd`**

Update the coordinates of the 12 forage spawn points so that sayur liar and daun hutan spawn in `forest_zone_1`, ikan sungai and batu in `forest_zone_2`, kayu in `forest_zone_3`, jamur and buah liar in `forest_zone_4`, akar rempah in `forest_zone_5`, and ancient items in `forest_zone_6`.

- [ ] **Step 4: Run test to verify it passes**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/ForageDistributionTest.gd`
Expected: PASS with "ForageDistributionTest passed."

- [ ] **Step 5: Commit**

```bash
git add scripts/world/World.gd tests/ForageDistributionTest.gd
git commit -m "feat(zone): redistribusikan titik foraging tematik ke 6 wilayah rimba"
```

---

### Task 6: Alur Prolog & Rintangan Batang Pohon Tumbang Terkunci

**Files:**
- Modify: `scripts/world/World.gd`
- Modify: `scripts/systems/QuestSystem.gd`
- Test: `tests/FallenTreeBarrierTest.gd`

**Interfaces:**
- Consumes: `GameState.is_deep_forest_unlocked`, `QuestSystem.quest_completed`.
- Produces: Fallen tree obstacle blocking gates to `forest_zone_5` & `forest_zone_6` until Rast Heart 2 quest is completed.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/FallenTreeBarrierTest.gd
extends SceneTree

func _init() -> void:
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	var game_state = load("res://scripts/autoload/GameState.gd").new()
	game_state.is_deep_forest_unlocked = false
	world._game_state = game_state
	world._update_fallen_tree_barriers()
	
	# Verify gate to forest_zone_6 from forest_zone_3 is blocked
	var gate_to_6 = world.get_zone_gate("forest_zone_3", "forest_zone_6")
	assert(gate_to_6 != null and gate_to_6.is_blocked == true, "Gate to forest_zone_6 must be blocked when locked")
	
	# Simulate completing Rast Heart 2 quest
	game_state.is_deep_forest_unlocked = true
	world._update_fallen_tree_barriers()
	assert(gate_to_6.is_blocked == false, "Gate to forest_zone_6 must be unblocked when is_deep_forest_unlocked is true")
	
	world.free()
	game_state.free()
	print("FallenTreeBarrierTest passed.")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/FallenTreeBarrierTest.gd`
Expected: FAIL because barrier methods and gates do not exist.

- [ ] **Step 3: Implement barrier logic in `World.gd` and trigger in `QuestSystem.gd`**

In `World.gd`, implement `_update_fallen_tree_barriers()`, blocking gate triggers to zones 5 and 6 if `GameState.is_deep_forest_unlocked` is false. In `QuestSystem.gd`, when completing Rast Heart 2 (`rast_heart_2`), set `GameState.is_deep_forest_unlocked = true`.

- [ ] **Step 4: Run test to verify it passes**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/FallenTreeBarrierTest.gd`
Expected: PASS with "FallenTreeBarrierTest passed."

- [ ] **Step 5: Commit**

```bash
git add scripts/world/World.gd scripts/systems/QuestSystem.gd tests/FallenTreeBarrierTest.gd
git commit -m "feat(zone): implementasi rintangan pohon tumbang dan pembukaan via quest Rast Hati 2"
```

---

### Task 7: UI Location Toast Banner

**Files:**
- Create: `scenes/LocationToastUI.tscn`
- Create: `scripts/ui/LocationToastUI.gd`
- Modify: `scripts/Main.gd`
- Test: `tests/LocationToastTest.gd`

**Interfaces:**
- Consumes: `World.zone_changed(zone_id: String, zone_name: String)`.
- Produces: `show_location(zone_name: String)` displaying top banner for 2.5s.

- [ ] **Step 1: Write the failing test**

```gdscript
# tests/LocationToastTest.gd
extends SceneTree

func _init() -> void:
	var script = load("res://scripts/ui/LocationToastUI.gd")
	assert(script != null, "LocationToastUI.gd must exist")
	var toast = script.new()
	assert(toast.has_method("show_location"), "Toast must have show_location method")
	
	toast.show_location("Pos Penebang Kayu")
	assert(toast.get_location_text() == "Pos Penebang Kayu", "Location text must be set")
	assert(toast.is_visible_or_animating(), "Toast must be visible when shown")
	
	toast.free()
	print("LocationToastTest passed.")
	quit(0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/LocationToastTest.gd`
Expected: FAIL because `LocationToastUI.gd` does not exist.

- [ ] **Step 3: Implement `LocationToastUI.gd` and instantiate in `Main.gd`**

Create `LocationToastUI.gd` with a Label and Panel container centered at top of screen. Connect `World.zone_changed` to `show_location(zone_name)`. Animate fade in (0.3s), display delay (2.5s), and fade out (0.3s).

- [ ] **Step 4: Run test to verify it passes**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/LocationToastTest.gd`
Expected: PASS with "LocationToastTest passed."

- [ ] **Step 5: Commit**

```bash
git add scenes/LocationToastUI.tscn scripts/ui/LocationToastUI.gd scripts/Main.gd tests/LocationToastTest.gd
git commit -m "feat(ui): tambah location toast banner saat memasuki wilayah baru"
```

---

### Task 8: Regresi Keseluruhan Test Suite & Pembaruan Versi 0.3.0

**Files:**
- Modify: `project.godot`
- Modify: `RELEASE.md`
- Test: Semua 14+ unit test di `tests/`

**Interfaces:**
- Consumes: Seluruh test suite `tests/*Test.gd`.
- Produces: 100% green tests, `project.godot` version 0.3.0.

- [ ] **Step 1: Write the failing test / check version**

Verify that `project.godot` still reflects 0.2.0 before updating to 0.3.0.

- [ ] **Step 2: Update version in `project.godot` and documentation in `RELEASE.md`**

Update `config/version="0.3.0"` in `project.godot`. Add release documentation notes in `RELEASE.md` for 0.3.0.

- [ ] **Step 3: Run the full test suite**

Run all test scripts in `tests/`:
```powershell
Get-ChildItem -Path tests -Filter "*Test.gd" | ForEach-Object {
    & Godot_v4.7.2-stable_win64_console.exe --headless --path . --script $_.FullName
    if ($LASTEXITCODE -ne 0) { throw ("Test failed: " + $_.Name) }
}
```
Expected: All tests pass with exit code 0.

- [ ] **Step 4: Commit**

```bash
git add project.godot RELEASE.md
git commit -m "chore(release): perbarui versi project ke 0.3.0 dan dokumentasi rilis"
```
