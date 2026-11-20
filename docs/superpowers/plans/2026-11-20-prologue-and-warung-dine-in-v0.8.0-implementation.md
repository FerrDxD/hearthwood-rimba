# Sekuens Prolog Pembuka & Pengalaman Pelayanan Meja Warung Makan (v0.8.0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menghadirkan sekuens prolog naratif pembuka saat pemain menekan "Mulai Permainan Baru" (latar belakang warteg asal, tragedi kebakaran gudang, dan efek mengerjap bangun di bawah kanopi Suaka Pohon Raksasa) serta sistem pelayanan meja warung makan interaktif (*Dine-In Table Service*) lengkap dengan perabotan meja-kursi, balon pesanan (*order bubble*), penyajian hidangan dari stok inventori, dan modal laporan penjualan harian.

**Architecture:** Membangun `PrologueSequence` berbasis `CanvasLayer` terpisah yang dipicu dari `MainMenu.gd` sebelum transisi ke `Main.tscn`; menambahkan komponen meja makan `WarungTable` dan `OrderBubble` di Distrik Warung pada `World.gd`; memperluas `WarungSystem.gd` untuk mengelola siklus operasional buka warung (16:00–21:00), penempatan tamu duduk, penyajian hidangan, kalkulasi tip koin/reputasi, dan modal rekapitulasi `WarungReportUI`.

**Tech Stack:** Godot Engine 4.7.2 (GL Compatibility, GDScript), CanvasLayer, Area2D, Tween, CPUParticles2D, FileAccess/JSON.

**Spec:** [PRD Hearthwood Warung Rimba (Versi 0.8.0).md](file:///C:/Users/Hype%20GLK/hearthwood-rimba/PRD%20Hearthwood%20Warung%20Rimba%20(Versi%200.8.0).md)

---

## Global Constraints

- Android Touch Ergonomics: Seluruh tombol sentuh dan area interaksi meja/lonceng minimal 44×44 dp (radius interaksi ≥ 44–48 px).
- Impeccable & UI-UX Pro Max Craftsmanship: Latar bergaya kayu rustic dan kertas pergamen, tidak ada glitch visual, font terbaca jelas, dan animasi taktil.
- Data-Driven Narrative: Seluruh naskah monolog prolog disimpan di `data/quests/opening_prologue.json` tanpa teks hardcode dalam skrip.
- Strict Spatial Boundaries: Seluruh perabotan warung berada di Distrik Warung Pemain (`Rect2(1040.0, 440.0, 520.0, 440.0)`) tanpa menghalangi jalur navigasi ke Cooking Station `(1210, 478)` atau Tempat Tidur `(1320, 476)`.
- Zero Regression Policy: 100% kelulusan seluruh test suite eksisting (30 test suites) dan tes baru di Godot 4.7.2 headless.

## Review Focus

1. **Prolog Interruption & Skip Consistency:** Menekan tombol "Lewati" (*Skip*) pada frame berapapun harus langsung menghentikan tween narasi, menghapus layer prolog, dan memposisikan pemain tepat di bawah pohon suaka `Vector2(100.0, 1180.0)` dengan state game bersih.
2. **Food Item Inventory Deduction:** Penyajian hidangan ke meja harus memotong porsi item masakan yang tepat dari inventori pemain (termasuk validasi ID masakan, level bintang kualitas, dan tanggal masak).
3. **Table State Recovery on Day Sleep:** Pergantian hari atau tidur paksa saat sesi warung masih aktif harus mereset meja makan yang sedang terisi atau kotor menjadi bersih kembali tanpa kebocoran state.
4. **Non-Blocking Order Bubble Life-Cycle:** Balon pesanan di atas kepala tamu tidak boleh memblokir tap interaksi pemain ke NPC atau objek lain di sekitar meja.
5. **Customer Capacity Bound:** Jumlah tamu yang dilayani dalam sesi warung tidak boleh melebihi batas kapasitas maksimal tier warung saat ini (Tier 1 = 3 tamu, Tier 2 = 5 tamu, dst).

---

### Task 1: Data Model & Naskah Monolog Prolog Pembuka (`opening_prologue.json`)

**Files:**
- Create: `data/quests/opening_prologue.json`
- Test: `tests/PrologueDataTest.gd`

**Interfaces:**
- Produces: `data/quests/opening_prologue.json` berisi array `monologues` (id, text, audio_hint, duration) dan objek `awakening` (text, question).

- [ ] **Step 1: Tulis tes verifikasi skema naskah prolog (`tests/PrologueDataTest.gd`)**

```gdscript
# tests/PrologueDataTest.gd
extends SceneTree

func _init() -> void:
	var file := FileAccess.open("res://data/quests/opening_prologue.json", FileAccess.READ)
	assert(file != null, "opening_prologue.json must exist")
	var data: Variant = JSON.parse_string(file.get_as_text())
	assert(typeof(data) == TYPE_DICTIONARY, "Data must be a Dictionary")
	
	assert(data.has("monologues"), "Must contain monologues array")
	assert(data["monologues"].size() >= 5, "Must contain at least 5 monologue steps")
	
	for entry in data["monologues"]:
		assert(entry.has("id"), "Monologue must have an id")
		assert(entry.has("text"), "Monologue must have text")
		assert(not entry["text"].is_empty(), "Text must not be empty")
	
	assert(data.has("awakening"), "Must contain awakening object")
	assert(data["awakening"].has("text"), "Awakening must have text")
	assert(data["awakening"].has("question"), "Awakening must have question")
	
	print("PrologueDataTest passed.")
	quit(0)
```

- [ ] **Step 2: Jalankan tes untuk memastikan gagal sebelum implementasi**

Jalankan: `& $godot --headless --script res://tests/PrologueDataTest.gd`  
Ekspektasi: FAIL (file `opening_prologue.json` belum ada).

- [ ] **Step 3: Buat data naskah `data/quests/opening_prologue.json`**

Tulis naskah monolog asal-usul warteg, kebakaran gudang, dan aroma sejuk rimba fantasi sesuai PRD v0.8.0.

- [ ] **Step 4: Jalankan tes verifikasi**

Jalankan: `& $godot --headless --script res://tests/PrologueDataTest.gd`  
Ekspektasi: PASS ("PrologueDataTest passed.").

- [ ] **Step 5: Commit**

```bash
git add data/quests/opening_prologue.json tests/PrologueDataTest.gd
git commit -m "feat(data): susun naskah narasi prolog pembuka warteg dan rimba hearthwood"
```

---

### Task 2: Komponen Sekuens Prolog Pembuka (`PrologueSequence.gd`) & Integrasi di `MainMenu.gd`

**Files:**
- Create: `scenes/ui/PrologueSequence.tscn`
- Create: `scripts/ui/PrologueSequence.gd`
- Modify: `scripts/ui/MainMenu.gd`
- Test: `tests/PrologueSequenceTest.gd`

**Interfaces:**
- Produces: `HearthwoodPrologueSequence` (`CanvasLayer`) dengan sinyal `sequence_completed` dan fungsi `start_sequence(player_name: String)`.
- Consumes: `data/quests/opening_prologue.json` dan `scripts/ui/MainMenu.gd` untuk memicu prolog saat "Mulai Permainan Baru".

- [ ] **Step 1: Tulis tes fungsionalitas sekuens prolog (`tests/PrologueSequenceTest.gd`)**

```gdscript
# tests/PrologueSequenceTest.gd
extends SceneTree

const PROLOGUE_SCENE: PackedScene = preload("res://scenes/ui/PrologueSequence.tscn")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var sequence := PROLOGUE_SCENE.instantiate()
	root.add_child(sequence)
	assert(sequence != null, "PrologueSequence instance must be valid")
	
	var completed := false
	sequence.sequence_completed.connect(func(): completed = true)
	
	sequence.start_sequence("Danu")
	assert(sequence.is_running(), "Sequence must be marked running")
	
	# Test skip button functionality
	var skip_btn = sequence.get_skip_button()
	assert(skip_btn != null, "Skip button must exist")
	assert(skip_btn.custom_minimum_size.x >= 44.0 and skip_btn.custom_minimum_size.y >= 44.0, "Skip button must meet touch target minimum")
	
	skip_btn.pressed.emit()
	await process_frame
	
	assert(completed, "Sequence must emit sequence_completed on skip")
	sequence.queue_free()
	print("PrologueSequenceTest passed.")
	quit(0)
```

- [ ] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/PrologueSequenceTest.gd`  
Ekspektasi: FAIL (scene `PrologueSequence.tscn` belum dibuat).

- [ ] **Step 3: Implementasikan `PrologueSequence.gd` dan integrasikan ke `MainMenu.gd`**

Bangun `PrologueSequence.gd` dengan:
- Latar ColorRect hitam pekat.
- RichTextLabel atau Label monolog di tengah dengan efek animasi kemunculan bertahap.
- Tombol "Lewati" di kanan atas (minimal 48×48 px) bergaya pergamen emas.
- Animasi masker kelopak mata (dua panel ColorRect atas-bawah yang mengerjap membuka).
- Pada `MainMenu.gd`, saat `_start_new_game()` dipanggil, instansiasi `PrologueSequence`, tampilkan, dan saat `sequence_completed` terpancar, baru alihkan ke `GAME_SCENE_PATH`.

- [ ] **Step 4: Jalankan tes verifikasi**

Jalankan: `& $godot --headless --script res://tests/PrologueSequenceTest.gd; & $godot --headless --script res://tests/MainMenuTest.gd`  
Ekspektasi: PASS.

- [ ] **Step 5: Commit**

```bash
git add scenes/ui/PrologueSequence.tscn scripts/ui/PrologueSequence.gd scripts/ui/MainMenu.gd tests/PrologueSequenceTest.gd
git commit -m "feat(ui): implementasikan sekuens sinematik prolog pembuka saat mulai permainan baru"
```

---

### Task 3: Komponen Meja Makan Warung (`WarungTable.gd`) & Balon Pesanan (`OrderBubble.gd`)

**Files:**
- Create: `scripts/world/WarungTable.gd`
- Create: `scripts/ui/OrderBubble.gd`
- Test: `tests/WarungTablePropsTest.gd`

**Interfaces:**
- Produces: `HearthwoodWarungTable` (`Area2D`) dengan state enum `TableState { EMPTY, OCCUPIED, WAITING_FOOD, EATING, DIRTY }`, posisi duduk NPC, dan fungsi `seat_customer(npc_id, recipe_id)`, `serve_food(item_id)`, `clear_table()`.
- Produces: `HearthwoodOrderBubble` (`Node2D`) untuk merender balon pesanan mengambang dengan ikon hidangan dan progress bar tenang.

- [ ] **Step 1: Tulis tes komponen meja warung dan balon pesanan (`tests/WarungTablePropsTest.gd`)**

```gdscript
# tests/WarungTablePropsTest.gd
extends SceneTree

const WARUNG_TABLE_SCRIPT = preload("res://scripts/world/WarungTable.gd")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var table = WARUNG_TABLE_SCRIPT.new()
	table.table_id = "table_1"
	table.position = Vector2(1170.0, 520.0)
	root.add_child(table)
	
	assert(table.current_state == table.TableState.EMPTY, "Initial table must be EMPTY")
	assert(table.is_available(), "Empty table must be available")
	
	table.seat_customer("gil", "sup_sayur_bening")
	assert(table.current_state == table.TableState.WAITING_FOOD, "Table must transition to WAITING_FOOD")
	assert(table.current_customer_id == "gil", "Customer ID must match")
	assert(table.requested_recipe_id == "sup_sayur_bening", "Requested recipe must match")
	assert(not table.is_available(), "Occupied table must not be available")
	
	var serve_result = table.serve_food("sup_sayur_bening", 2)
	assert(serve_result, "Serving correct dish must succeed")
	assert(table.current_state == table.TableState.EATING, "Table must transition to EATING")
	
	table.finish_eating()
	assert(table.current_state == table.TableState.DIRTY, "Table must become DIRTY after eating")
	assert(table.uncollected_coins > 0, "Dirty table must have coins to collect")
	
	var collected = table.clear_table()
	assert(collected > 0, "Clearing table must return collected coins")
	assert(table.current_state == table.TableState.EMPTY, "Table must return to EMPTY")
	
	table.queue_free()
	print("WarungTablePropsTest passed.")
	quit(0)
```

- [ ] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/WarungTablePropsTest.gd`  
Ekspektasi: FAIL (file `WarungTable.gd` belum ada).

- [ ] **Step 3: Implementasikan `WarungTable.gd` dan `OrderBubble.gd`**

Bangun `WarungTable.gd`:
- Turunan dari `Area2D` dengan radius sentuh ergonomis (48 px).
- Visual prosedural taktil `_draw()`: Meja kayu rustic bernuansa cokelat tua `#8B4513`, dua bangku kayu di sisi kiri-kanan, taplak meja linen krem `#F5F5DC`.
- `OrderBubble.gd`: Balon mengambang animasi lembut (bobbing tween) menampilkan nama/ikon masakan yang dipesan.
- Metode manajemen siklus hidup: `seat_customer`, `serve_food`, `finish_eating`, `clear_table`.

- [ ] **Step 4: Jalankan tes verifikasi**

Jalankan: `& $godot --headless --script res://tests/WarungTablePropsTest.gd`  
Ekspektasi: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/world/WarungTable.gd scripts/ui/OrderBubble.gd tests/WarungTablePropsTest.gd
git commit -m "feat(world): implementasikan komponen meja makan warung dan balon pesanan tamu"
```

---

### Task 4: Integrasi Meja Warung & Lonceng Operasional di `World.gd`

**Files:**
- Modify: `scripts/world/World.gd`
- Test: `tests/WarungWorldIntegrationTest.gd`

**Interfaces:**
- Produces: Penempatan 2-4 `WarungTable` dan 1 `WarungSign`/Lonceng di Distrik Warung Pemain pada `World.gd`.
- Consumes: Fungsi penempatan landmark di `World.gd` tanpa bertabrakan dengan collider solid atau stasiun memasak.

- [ ] **Step 1: Tulis tes integrasi meja warung di World (`tests/WarungWorldIntegrationTest.gd`)**

```gdscript
# tests/WarungWorldIntegrationTest.gd
extends SceneTree

const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var world = WORLD_SCENE.instantiate()
	root.add_child(world)
	await process_frame
	
	var tables = world.get_warung_tables()
	assert(tables.size() >= 2, "World must have at least 2 dining tables in the warung district")
	
	for table in tables:
		assert(table.position.x >= 1040.0 and table.position.x <= 1560.0, "Table must be inside Warung District X bounds")
		assert(table.position.y >= 440.0 and table.position.y <= 880.0, "Table must be inside Warung District Y bounds")
		# Verify table is not overlapping with CookingStation or Bed
		assert(table.position.distance_to(Vector2(1210.0, 478.0)) > 30.0, "Table must not overlap cooking station")
		assert(table.position.distance_to(Vector2(1320.0, 476.0)) > 30.0, "Table must not overlap bed")
	
	var bell = world.get_warung_bell()
	assert(bell != null, "World must provide warung bell / sign interaction point")
	
	world.queue_free()
	print("WarungWorldIntegrationTest passed.")
	quit(0)
```

- [ ] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/WarungWorldIntegrationTest.gd`  
Ekspektasi: FAIL (metode `get_warung_tables` dan `get_warung_bell` belum ada di `World.gd`).

- [ ] **Step 3: Pasang meja warung dan lonceng operasional di `World.gd`**

Di `World.gd`:
- Tambahkan array `_warung_tables: Array[HearthwoodWarungTable] = []`.
- Instansiasi 2 meja pada posisi nyaman di beranda warung (`Vector2(1150.0, 520.0)` dan `Vector2(1270.0, 520.0)`).
- Buat titik interaksi `WarungBell` pada `Vector2(1170.0, 470.0)` untuk membuka/menutup sesi operasional.
- Implementasikan `get_warung_tables()` dan `get_warung_bell()`.

- [ ] **Step 4: Jalankan tes integrasi meja warung**

Jalankan: `& $godot --headless --script res://tests/WarungWorldIntegrationTest.gd; & $godot --headless --script res://tests/VillageLandmarksTest.gd`  
Ekspektasi: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/world/World.gd tests/WarungWorldIntegrationTest.gd
git commit -m "feat(world): pasang meja makan dan lonceng operasional di distrik warung pemain"
```

---

### Task 5: Pengendali Sesi Pelayanan Warung (*Dine-In Service Loop*) & Modal Rekapitulasi

**Files:**
- Modify: `scripts/systems/WarungSystem.gd`
- Create: `scenes/ui/WarungReportUI.tscn`
- Create: `scripts/ui/WarungReportUI.gd`
- Modify: `scripts/Main.gd`
- Test: `tests/WarungDineInTest.gd`

**Interfaces:**
- Produces: `WarungSystem.start_service_rush()`, `WarungSystem.end_service_rush()`, `WarungSystem.is_service_active()`, `WarungReportUI.show_report(summary_data)`.
- Consumes: `GameState` (inventori masakan, koin, reputasi) dan `TimeSystem` (jam 16:00–21:00).

- [ ] **Step 1: Tulis tes siklus penuh pelayanan warung (`tests/WarungDineInTest.gd`)**

```gdscript
# tests/WarungDineInTest.gd
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/Main.tscn")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")
	
	# Setup state: hour 17 (open window), add 2 cooked dishes to inventory
	game_state.current_day = 2
	game_state.current_hour = 17
	game_state.current_minute = 0
	game_state.warung_tier = 1
	game_state.add_item("sup_sayur_bening", 2, 2, 2)
	
	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	
	var warung_system = main.get_warung_system()
	assert(warung_system != null, "Warung system must exist")
	
	# Test start service rush
	var open_result = warung_system.start_service_rush()
	assert(open_result.get("valid", false), "Service rush must open successfully when conditions met")
	assert(warung_system.is_service_active(), "Service must be marked active")
	
	# Simulate customer seating
	var seated = warung_system.spawn_next_customer()
	assert(seated, "Customer must be seated at an available table")
	
	# Serve customer from inventory
	var tables = main.get_world().get_warung_tables()
	var occupied_table = null
	for t in tables:
		if not t.is_available():
			occupied_table = t
			break
	assert(occupied_table != null, "At least one table must be occupied")
	
	var serve_success = warung_system.serve_table(occupied_table)
	assert(serve_success, "Serving table from inventory must succeed")
	assert(game_state.get_item_count("sup_sayur_bening") == 1, "Inventory dish count must decrease by 1")
	
	# End rush and check daily summary data
	var summary = warung_system.end_service_rush()
	assert(summary.get("customers_served", 0) >= 1, "Summary must record served customers")
	assert(summary.get("total_coins_earned", 0) > 0, "Summary must record earned coins")
	
	main.queue_free()
	print("WarungDineInTest passed.")
	quit(0)
```

- [ ] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/WarungDineInTest.gd`  
Ekspektasi: FAIL (metode `start_service_rush`, `spawn_next_customer`, `serve_table` belum ada).

- [ ] **Step 3: Implementasikan logika sesi warung dan UI rekapitulasi penjualan**

1. Pada `WarungSystem.gd`:
   - Tambahkan variabel: `_is_service_active: bool`, `_daily_rush_customers: int`, `_daily_rush_coins: int`, `_daily_rush_rep: int`.
   - Implementasikan fungsi `start_service_rush()`, `end_service_rush()`, `spawn_next_customer()`, `serve_table(table)`.
   - Validasi jam buka (16:00–21:00) dan ketersediaan minimal 1 masakan di inventori.
   - Perhitungan koin: harga dasar + kualitas (1-3 bintang) + tip afeksi NPC.
2. Buat `WarungReportUI.gd`:
   - Modal estetik bergaya plakat kayu dan perkamen menampilkan: judul "Warta Penjualan Warung", jumlah pelanggan terlayani, koin diperoleh, kenaikan reputasi, dan tombol "Tutup Toko / Selesai".
3. Pada `Main.gd`:
   - Hubungkan interaksi lonceng warung ke `start_service_rush()`.
   - Saat pemain mendekati meja yang sedang memesan (`WAITING_FOOD`), munculkan prompt tombol interaksi "Sajikan Pesanan".

- [ ] **Step 4: Jalankan tes verifikasi**

Jalankan: `& $godot --headless --script res://tests/WarungDineInTest.gd; & $godot --headless --script res://tests/WarungSystemTest.gd`  
Ekspektasi: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/WarungSystem.gd scenes/ui/WarungReportUI.tscn scripts/ui/WarungReportUI.gd scripts/Main.gd tests/WarungDineInTest.gd
git commit -m "feat(warung): terapkan siklus aktif pelayanan meja warung dan modal laporan harian"
```

---

### Task 6: Verifikasi Alur Game Utama & Simpan-Muat State Warung

**Files:**
- Modify: `tests/SaveSystemTest.gd`
- Modify: `tests/MainGameFlowTest.gd`
- Test: `tests/SaveSystemTest.gd`, `tests/MainGameFlowTest.gd`

**Interfaces:**
- Produces: Memastikan alur permainan dari pembukaan prolog, awakening rimba, tutorial, eksplorasi desa, hingga pelayanan warung berjalan mulus.
- Consumes: `GameState` save/load round-trip untuk memverifikasi kompatibilitas data meja dan pendapatan warung.

- [ ] **Step 1: Tingkatkan `tests/SaveSystemTest.gd` dan `tests/MainGameFlowTest.gd`**

- Verifikasi bahwa save/load mempertahankan state warung tanpa korupsi data.
- Verifikasi bahwa fungsi tidur (`GameState.sleep()`) mereset meja makan yang kotor/terisi menjadi bersih untuk hari berikutnya.

- [ ] **Step 2: Jalankan tes alur utama dan simpan-muat**

Jalankan: `& $godot --headless --script res://tests/SaveSystemTest.gd; & $godot --headless --script res://tests/MainGameFlowTest.gd`  
Ekspektasi: PASS.

- [ ] **Step 3: Commit**

```bash
git add tests/SaveSystemTest.gd tests/MainGameFlowTest.gd
git commit -m "test(flow): verifikasi kelancaran alur prolog, pelayanan meja warung, dan simpan-muat v0.8.0"
```

---

### Task 7: Uji Regresi Penuh Seluruh 33 Test Suites & Dokumentasi Rilis 0.8.0

**Files:**
- Modify: `MILESTONES.md`
- Modify: `RELEASE.md`
- Modify: `project.godot`
- Modify: `docs/superpowers/plans/2026-11-20-prologue-and-warung-dine-in-v0.8.0-implementation.md`
- Test: Seluruh 33 test suite di direktori `tests/` (30 eksisting + 3 baru)

**Interfaces:**
- Produces: 100% kelulusan dari 33 test suites tanpa galat.

- [ ] **Step 1: Eksekusi seluruh 33 file test suite secara headless**

```powershell
$godot = "C:\Users\Hype GLK\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
$tests = Get-ChildItem -Path tests -Filter "*Test.gd"
$passed = 0
$failed = 0
foreach ($t in $tests) {
    & $godot --headless --script ("res://tests/" + $t.Name) | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PASS: $($t.Name)"
        $passed++
    } else {
        Write-Host "FAIL: $($t.Name) with code $LASTEXITCODE"
        $failed++
    }
}
Write-Host "=== TEST RUN COMPLETE: $passed PASSED, $failed FAILED out of $($tests.Count) ==="
```

Ekspektasi: 33 PASSED, 0 FAILED.

- [ ] **Step 2: Perbarui versi ke 0.8.0 di `project.godot`**

- [ ] **Step 3: Dokumentasikan penyelesaian Versi 0.8.0 di `MILESTONES.md` dan `RELEASE.md`**

- [ ] **Step 4: Centang seluruh daftar tugas di dokumen rencana ini**

Ubah seluruh `- [ ]` menjadi `- [x]` di dokumen rencana ini.

- [ ] **Step 5: Commit penyelesaian rilis v0.8.0**

```bash
git add project.godot MILESTONES.md RELEASE.md docs/superpowers/plans/2026-11-20-prologue-and-warung-dine-in-v0.8.0-implementation.md
git commit -m "chore(release): rampungkan implementasi penuh sekuens prolog dan pelayanan meja warung v0.8.0"
```
