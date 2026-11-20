# Implementasi Ekosistem & Pembangunan 6 Wilayah Rimba (Versi 0.6.0)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Membangun seluruh 6 wilayah hutan rimba (`forest_zone_1` s/d `forest_zone_6`) dengan landmark visual tematik, persebaran sumber daya alam terkurasi, interaktivitas lingkungan baru (goyang pohon buah, mata air pemulih energi, celah tunggul/akar periksa, dan semak berdesir), pos kemah Rast, serta efek partikel suasana dengan mempertahankan 100% kelulusan test suite eksisting.

**Architecture:** Menerapkan pendekatan *data-driven* modular di Godot 4.x. Data spesifikasi landmark dan objek interaktif disimpan dalam `data/world/forest_zones.json`. Objek interaktif diimplementasikan sebagai komponen `InteractiveProp` (`FruitTree`, `FreshSpring`, `InspectableHollow`, `RustlingBush`) yang menangkap interaksi sentuh/tombol `E` dan terhubung dengan reset harian `TimeSystem`. Visual terrain dan landmark digambar secara prosedural kanvas `_draw()` dan objek 2D terstruktur di `World.gd` tanpa merusak kontrak pengujian gerbang, prolog, dan isolasi NPC.

**Tech Stack:** Godot Engine 4.7.2 (GL Compatibility), GDScript, Node2D / Area2D / CollisionShape2D, JSON Data, Conventional Commits.

**Spec:** [PRD Hearthwood Warung Rimba (Versi 0.6.0).md](file:///C:/Users/Hype%20GLK/hearthwood-rimba/PRD%20Hearthwood%20Warung%20Rimba%20(Versi%200.6.0).md)

## Global Constraints

- **Batas Wilayah & Koordinat:** Seluruh landmark dan objek wajib berada di dalam batas `ZONE_RECTS` resmi masing-masing zona:
  - `forest_zone_1`: `Rect2(0.0, 960.0, 560.0, 480.0)` (Pintu Rimba)
  - `forest_zone_2`: `Rect2(-560.0, 960.0, 560.0, 480.0)` (Aliran Sungai Bebatuan)
  - `forest_zone_3`: `Rect2(0.0, 480.0, 560.0, 480.0)` (Pos Penebang Kayu)
  - `forest_zone_4`: `Rect2(560.0, -480.0, 560.0, 480.0)` (Semak Belukar Lembab)
  - `forest_zone_5`: `Rect2(-560.0, 480.0, 560.0, 480.0)` (Lembah Akar Purba)
  - `forest_zone_6`: `Rect2(0.0, 0.0, 560.0, 480.0)` (Suaka Pohon Raksasa)
- **Kontrak Prolog & Foraging:** Titik awal sayur liar prolog di `Vector2(104.0, 1178.0)` wajib tetap ada agar `MainGameFlowTest.gd` tidak gagal.
- **Kontrak Gerbang & Batang Tumbang:** Gerbang `forest_zone_3 <-> 6`, `3 <-> 5`, dan `2 <-> 5` wajib mematuhi status `is_deep_forest_unlocked` untuk `FallenTreeBarrierTest.gd` dan `ZoneGateTest.gd`.
- **Target Sentuh & Kontrol Android:** Semua objek interaktif lingkungan memiliki radius sentuh minimum 32–48 px dan dapat diakses dengan tombol aksi `interact` (`E`).
- **Zero Broken Tests:** Seluruh 21 test suite eksisting wajib lolos 100% pada setiap akhir task.
- **Palet Warna:** Mengikuti palet resmi `DESIGN.md` (Coklat `#76513A`, Hijau Rimba `#294D35`, Hijau Sage `#8FBC8F`, Emas `#CD853F`, Krem `#F5F5DC`, Air `#6B9DB3`).

## Review Focus

1. **Prolog Sayur Liar Tidak Boleh Tergeser:** Koordinat `Vector2(104.0, 1178.0)` di Zona 1 harus tetap menghasilkan `sayur_liar` pertama agar tutorial Rast di awal permainan tidak macet.
2. **Tabrakan Fisik dengan Gerbang:** Objek dekorasi landmark dan collider pohon baru tidak boleh menutupi area pemicu gerbang `ZoneGate2D` yang bisa menyebabkan pemain terjebak saat transisi antar zona.
3. **Penyimpanan Status Interaktif Harian:** Membasuh muka di mata air (+10 energi) dan menggoyang pohon buah hanya boleh terjadi sekali per hari; status ini harus bersih kembali saat tidur dan tersimpan di `SaveSystem`.
4. **Isolasi Ambient NPC:** Tidak boleh ada ambient NPC desa yang ter-spawn di koordinat 6 wilayah rimba (`x < 560.0` atau `y > 880.0` atau `y < 0.0`).
5. **Kinerja Rendah di Mobile:** Partikel kabut, kunang-kunang, dan spora harus ringan (menggunakan `CPUParticles2D` atau gambar kanvas hemat draw call) agar tidak menurunkan frame rate di perangkat Android spek rendah.

---

### Task 1: Data Model & Schema Ekosistem Hutan (`forest_zones.json` & Items)

**Files:**
- Create: `data/world/forest_zones.json`
- Modify: `data/items/items.json`
- Test: `tests/ForestZonesDataTest.gd`

**Interfaces:**
- Produces: `data/world/forest_zones.json` berisi entri 6 zona dengan struktur `{"landmarks": [...], "props": [...], "forages": [...]}`.
- Consumes: `data/items/items.json` menambahkan item `lumut_sungai` (`#5b8a54`).

- [x] **Step 1: Tulis tes verifikasi data ekosistem hutan (`tests/ForestZonesDataTest.gd`)**

```gdscript
# tests/ForestZonesDataTest.gd
extends SceneTree

func _init() -> void:
	var file := FileAccess.open("res://data/world/forest_zones.json", FileAccess.READ)
	assert(file != null, "forest_zones.json must exist")
	var data: Variant = JSON.parse_string(file.get_as_text())
	assert(typeof(data) == TYPE_DICTIONARY, "Data must be a Dictionary")
	for i in range(1, 7):
		var zid := "forest_zone_%d" % i
		assert(data.has(zid), "Must contain entry for " + zid)
		assert(data[zid].has("landmarks"), zid + " must have landmarks")
		assert(data[zid].has("props"), zid + " must have props")
		assert(data[zid].has("forages"), zid + " must have forages")
	
	# Verify items.json contains lumut_sungai
	var ifile := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	assert(ifile != null, "items.json must exist")
	var idata: Variant = JSON.parse_string(ifile.get_as_text())
	var has_moss := false
	for it in idata.get("items", []):
		if it.get("id") == "lumut_sungai":
			has_moss = true
			break
	assert(has_moss, "items.json must contain lumut_sungai")
	print("ForestZonesDataTest passed.")
	quit(0)
```

- [x] **Step 2: Jalankan tes untuk memastikan gagal sebelum implementasi**

Jalankan: `& $godot --headless --script res://tests/ForestZonesDataTest.gd`  
Ekspektasi: FAIL (file `forest_zones.json` belum ada).

- [x] **Step 3: Buat `data/world/forest_zones.json` dan perbarui `data/items/items.json`**

Buat struktur data 6 zona lengkap dengan koordinat landmark, objek interaktif, dan spawn forage. Tambahkan `lumut_sungai` ke `data/items/items.json`.

- [x] **Step 4: Jalankan tes verifikasi**

Jalankan: `& $godot --headless --script res://tests/ForestZonesDataTest.gd`  
Ekspektasi: PASS ("ForestZonesDataTest passed.").

- [x] **Step 5: Commit**

```bash
git add data/world/forest_zones.json data/items/items.json tests/ForestZonesDataTest.gd
git commit -m "feat(data): tambahkan metadata ekosistem 6 wilayah hutan dan item lumut sungai"
```

---

### Task 2: Framework Komponen Objek Interaktif Lingkungan (`InteractiveProp.gd` & Turunannya)

**Files:**
- Create: `scripts/world/InteractiveProp.gd`
- Create: `scripts/world/FruitTree.gd`
- Create: `scripts/world/FreshSpring.gd`
- Create: `scripts/world/InspectableHollow.gd`
- Test: `tests/InteractivePropTest.gd`

**Interfaces:**
- Produces: 
  - `HearthwoodInteractiveProp`: basis kelas objek interaktif lingkungan (`prop_id`, `prop_type`, `can_interact()`, `interact(player)`, `reset_daily()`).
  - `HearthwoodFruitTree`: pohon buah yang bergetar lembut dan memunculkan `ItemPickup` di tanah.
  - `HearthwoodFreshSpring`: mata air alami yang memulihkan energi pemain sebesar +10 sekali per hari.
  - `HearthwoodInspectableHollow`: ceruk bebatuan/akar/tunggul yang memberikan 1 bahan tersembunyi per hari.

- [x] **Step 1: Tulis tes fungsional objek interaktif (`tests/InteractivePropTest.gd`)**

Uji fungsionalitas pohon buah (goyang -> spawn item), mata air (+10 energi, 1x sehari), ceruk periksa (drop item, 1x sehari), dan reset harian (`reset_daily()`).

- [x] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/InteractivePropTest.gd`  
Ekspektasi: FAIL (kelas-kelas belum ada).

- [x] **Step 3: Implementasikan kelas-kelas objek interaktif**

Tulis `InteractiveProp.gd`, `FruitTree.gd`, `FreshSpring.gd`, dan `InspectableHollow.gd` dengan collision shape 2D, integrasi sinyal, feedback visual, dan proteksi interaksi ganda harian.

- [x] **Step 4: Jalankan tes untuk memverifikasi kelulusan**

Jalankan: `& $godot --headless --script res://tests/InteractivePropTest.gd`  
Ekspektasi: PASS ("InteractivePropTest passed.").

- [x] **Step 5: Commit**

```bash
git add scripts/world/InteractiveProp.gd scripts/world/FruitTree.gd scripts/world/FreshSpring.gd scripts/world/InspectableHollow.gd tests/InteractivePropTest.gd
git commit -m "feat(world): buat framework objek interaktif lingkungan pohon buah, mata air, dan ceruk"
```

---

### Task 3: Pembangunan Landmark Visual & Karakteristik Tematik di `World.gd`

**Files:**
- Modify: `scripts/world/World.gd`
- Test: `tests/ForestLandmarksTest.gd`, `tests/ForageDistributionTest.gd`

**Interfaces:**
- Produces: Fungsi `_build_forest_landmarks()` di `World.gd` yang merender:
  - Zona 1: Gapura kayu perbatasan, jalan setapak kerikil, papan petunjuk arah.
  - Zona 2: Aliran sungai bebatuan melintang diagonal, jembatan kayu lapuk, stepping stones, tepian pasir.
  - Zona 3: Pos kemah Rast (tenda kanvas, tunggul tebang, perapian batu, tumpukan kayu gelondongan).
  - Zona 4: Rawa kecil berlumut, semak vegetasi lebat, pohon buah rimbun.
  - Zona 5: Lengkungan lorong akar raksasa, fosil batu lumut, celah akar purba.
  - Zona 6: Altar batu kuno berpahat, lentera suaka, pohon raksasa agung.
- Consumes: `data/world/forest_zones.json` untuk konfigurasi penempatan.

- [x] **Step 1: Tulis tes verifikasi kehadiran landmark (`tests/ForestLandmarksTest.gd`)**

Verifikasi setiap zona memiliki node/komponen landmark khusus dan collider rintangan yang tidak bertabrakan dengan gerbang transisi `ZoneGate2D`.

- [x] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/ForestLandmarksTest.gd`  
Ekspektasi: FAIL.

- [x] **Step 3: Implementasikan rendering landmark dan struktur visual di `World.gd`**

Gantikan pohon acak generik dengan penataan vegetasi dan landmark tematik terstruktur, menambahkan visual sungai, gapura, tenda Rast, dan lorong akar.

- [x] **Step 4: Jalankan tes landmark dan tes gerbang**

Jalankan: `& $godot --headless --script res://tests/ForestLandmarksTest.gd; & $godot --headless --script res://tests/ZoneGateTest.gd`  
Ekspektasi: PASS (kedua tes lulus).

- [x] **Step 5: Commit**

```bash
git add scripts/world/World.gd tests/ForestLandmarksTest.gd
git commit -m "feat(world): bangun visual landmark tematik dan rintangan alam di 6 wilayah rimba"
```

---

### Task 4: Integrasi Objek Interaktif, Semak Berdesir & Ambience Partikel

**Files:**
- Create: `scripts/world/RustlingBush.gd`
- Modify: `scripts/world/World.gd`
- Test: `tests/RustlingBushTest.gd`, `tests/MainGameFlowTest.gd`

**Interfaces:**
- Produces:
  - `HearthwoodRustlingBush`: `Area2D` yang mendeteksi langkah kaki pemain, memutar getaran dahan dan desau daun tanpa menghalangi jalan.
  - Partikel kanvas atmosfer: kabut melayang di Zona 4, spora redup di Zona 5, kunang-kunang di Zona 6.
  - Integrasi reset harian objek interaktif di `World.gd` saat menerima sinyal `time_system.day_changed`.

- [x] **Step 1: Tulis tes interaksi semak dan pemulihan harian (`tests/RustlingBushTest.gd`)**

Uji deteksi pemain pada `RustlingBush`, pemutaran sinyal tanpa tabrakan keras, serta reset harian prop interaktif.

- [x] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/RustlingBushTest.gd`  
Ekspektasi: FAIL.

- [x] **Step 3: Implementasikan `RustlingBush.gd` dan efek suasana zona di `World.gd`**

Tambahkan semak berdesir pada jalur semak lebat dan pasang partikel suasana alami pada zona 4, 5, dan 6. Hubungkan `_on_day_changed` ke semua `InteractiveProp`.

- [x] **Step 4: Jalankan tes unit dan alur permainan utama**

Jalankan: `& $godot --headless --script res://tests/RustlingBushTest.gd; & $godot --headless --script res://tests/MainGameFlowTest.gd`  
Ekspektasi: PASS.

- [x] **Step 5: Commit**

```bash
git add scripts/world/RustlingBush.gd scripts/world/World.gd tests/RustlingBushTest.gd
git commit -m "feat(world): tambahkan semak berdesir, partikel atmosfer zona, dan reset harian prop"
```

---

### Task 5: Penempatan Pos Rast & Penyesuaian Jadwal Patroli Rimba

**Files:**
- Modify: `data/schedules.json`
- Modify: `scripts/world/World.gd`
- Test: `tests/ForestNPCIsolationTest.gd`, `tests/NPCSystemTest.gd`

**Interfaces:**
- Consumes: Jadwal Rast di `data/schedules.json`.
- Produces: Penyesuaian rutinitas harian Rast:
  - 06.00 – 09.00: Pos Penebang Kayu (Zona 3)
  - 09.00 – 14.00: Patroli Pintu Rimba (Zona 1)
  - 14.00 – 18.00: Aliran Sungai Bebatuan (Zona 2)
  - 18.00 – 22.00: Kembali istirahat di tenda kemah Zona 3

- [x] **Step 1: Pastikan `ForestNPCIsolationTest.gd` memverifikasi posisi Rast di Zona 3 jam 06.00**

Jalankan: `& $godot --headless --script res://tests/ForestNPCIsolationTest.gd`  
Ekspektasi: PASS (memastikan ekspektasi baseline valid).

- [x] **Step 2: Perbarui segmen jadwal Rast di `data/schedules.json`**

Sesuaikan titik koordinat patroli Rast agar singgah di kemah Zona 3, gapura Zona 1, dan sungai Zona 2.

- [x] **Step 3: Jalankan tes isolasi NPC dan dialog**

Jalankan: `& $godot --headless --script res://tests/ForestNPCIsolationTest.gd; & $godot --headless --script res://tests/NPCSystemTest.gd`  
Ekspektasi: PASS.

- [x] **Step 4: Commit**

```bash
git add data/schedules.json scripts/world/World.gd
git commit -m "feat(npc): integrasikan jadwal patroli rimba dan kemah peristirahatan Rast di Zona 3"
```

---

### Task 6: Integrasi Penyimpanan Status Interaktif Rimba (`SaveSystem.gd`)

**Files:**
- Modify: `scripts/autoload/GameState.gd`
- Modify: `scripts/systems/SaveSystem.gd`
- Modify: `scripts/world/World.gd`
- Test: `tests/ZoneStateSaveTest.gd`, `tests/SaveSystemTest.gd`

**Interfaces:**
- Produces: Serialisasi `interacted_props_today: Array[String]` di `GameState` dan `SaveSystem`.
- Consumes: State yang dipulihkan saat pemain memuat game (`load_game`) untuk menyelaraskan status pohon buah/mata air yang sudah digunakan di hari berjalan.

- [x] **Step 1: Jalankan `ZoneStateSaveTest.gd` sebagai baseline**

Jalankan: `& $godot --headless --script res://tests/ZoneStateSaveTest.gd`  
Ekspektasi: PASS.

- [x] **Step 2: Tambahkan array `interacted_props_today` di `GameState.gd` dan `SaveSystem.gd`**

Simpan dan pulihkan status interaksi harian prop hutan ke file `user://savegame.json`. Reset array ini saat `sleep()`.

- [x] **Step 3: Jalankan tes penyimpanan menyeluruh**

Jalankan: `& $godot --headless --script res://tests/ZoneStateSaveTest.gd; & $godot --headless --script res://tests/SaveSystemTest.gd`  
Ekspektasi: PASS.

- [x] **Step 4: Commit**

```bash
git add scripts/autoload/GameState.gd scripts/systems/SaveSystem.gd scripts/world/World.gd
git commit -m "feat(save): simpan dan muat status interaksi harian objek lingkungan hutan"
```

---

### Task 7: Uji Regresi Penuh Seluruh 25 Test Suites & Pembaruan Milestone 0.6.0

**Files:**
- Modify: `MILESTONES.md`
- Test: Seluruh test suites di direktori `tests/` (21 eksisting + 4 baru)

**Interfaces:**
- Produces: Laporan kelulusan 100% dari seluruh 25 test suite tanpa galat.

- [x] **Step 1: Eksekusi seluruh 25 file test suite secara headless**

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

Ekspektasi: 25 PASSED, 0 FAILED.

- [x] **Step 2: Dokumentasikan penyelesaian Versi 0.6.0 di `MILESTONES.md`**

Tambahkan rincian deliverable dan checklist Definition of Done v0.6.0 di `MILESTONES.md`.

- [x] **Step 3: Centang seluruh daftar tugas di dokumen rencana ini**

Ubah seluruh `- [x]` menjadi `- [x]` di `docs/superpowers/plans/2026-11-20-forest-ecosystem-v0.6.0-implementation.md`.

- [x] **Step 4: Commit penyelesaian rilis v0.6.0**

```bash
git add MILESTONES.md docs/superpowers/plans/2026-11-20-forest-ecosystem-v0.6.0-implementation.md
git commit -m "chore(release): rampungkan implementasi penuh ekosistem 6 wilayah rimba v0.6.0"
```
