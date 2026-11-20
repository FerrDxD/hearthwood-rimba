# Implementasi Ekspansi Desa Hearthwood (Versi 0.7.0)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun ekspansi penuh Desa Hearthwood ke dalam 4 distrik terpadu (Pasar, Balai Desa, Warung Rimba, Pemukiman), mendirikan fasilitas fisik lengkap (Balai Desa, fasad toko Giral & Talia, lumbung komunal, pondok warga), menghadirkan Sumur Desa dan Papan Pengumuman interaktif, serta menerapkan sistem klaster sosial dinamis untuk 32 NPC ambient dengan mempertahankan 100% kelulusan seluruh test suite.

**Architecture:** Menerapkan pendekatan prosedural modular berbasis *data-driven* di Godot 4.x. Spesifikasi distrik, fasad bangunan, dan area klaster NPC disimpan dalam `data/world/village_zones.json`. Objek interaktif desa (`VillageWell` dan `NoticeBoard`) diturunkan dari `HearthwoodInteractiveProp` dan disinkronkan dengan `interacted_props_today` di `GameState` & `SaveSystem`. Pergerakan 32 NPC ambient dikontrol dinamis oleh `_update_ambient_npc_clustering(hour)` yang dipicu oleh sinyal waktu harian tanpa melanggar batas isolasi rimba (`x >= 560.0`).

**Tech Stack:** Godot Engine 4.7.2 (GL Compatibility), GDScript, Area2D, CollisionShape2D, CPUParticles2D, JSON Data, Conventional Commits.

**Spec:** [PRD Hearthwood Warung Rimba (Versi 0.7.0).md](file:///C:/Users/Hype%20GLK/hearthwood-rimba/PRD%20Hearthwood%20Warung%20Rimba%20(Versi%200.7.0).md)

## Global Constraints

- **Batas Wilayah Desa:** Seluruh elemen desa, bangunan, dan NPC desa wajib berada di dalam batas kanvas `Rect2(560.0, 0.0, 1040.0, 880.0)`.
- **Isolasi Rimba (Forest NPC Isolation):** Tidak boleh ada satupun ambient NPC atau warga desa yang berada di koordinat `x < 560.0` (diuji ketat oleh `ForestNPCIsolationTest.gd`).
- **Koordinat Kontrak Alur Tutorial Prolog:**
  - Posisi Veral di `Vector2(1390.0, 342.0)` (di teras depan Balai Desa) wajib dapat dijangkau dan diinteraksi pada jam 08.00 (`MainGameFlowTest.gd`).
  - Stasiun Memasak di `Vector2(1210.0, 478.0)` dan Ranjang Tidur di `Vector2(1320.0, 476.0)` wajib bebas halangan collider (`MainGameFlowTest.gd`).
- **Gerbang Pintu Rimba:** Area gerbang `village <-> forest_zone_1` di `Vector2(565.0, 440.0)` wajib steril dari collider rintangan bangunan atau pagar.
- **Standar Visual Impeccable & UI-UX Pro Max:** Desain visual fasad bangunan dan ornamen desa wajib menggunakan palet resmi `DESIGN.md` (Papan Kayu `#76513A`, Sirap Kayu `#5C3A1E`, Terakota `#B8482D`, Emas `#CD853F`, Krem `#F5F5DC`, Hijau Sage `#8FBC8F`) tanpa visual AI-slop yang acak.
- **Radius Interaksi Sentuh (Android):** Objek interaktif `VillageWell` dan `NoticeBoard` wajib memiliki radius interaksi minimum 44–48 px.
- **Zero Broken Tests:** Seluruh 25 test suite eksisting wajib dipertahankan kelulusannya 100% pada setiap task.

## Review Focus

1. **Jalur Jalan Menuju Balai Desa Bebas Halangan:** Rintangan collider Balai Desa dan taman bunga tidak boleh memblokir rute pemain dari Stasiun Masak `(1210, 478)` ke Veral `(1390, 342)`.
2. **Batas Klaster Ambient NPC Tidak Menyeberang ke Hutan:** Pergerakan klaster ambient NPC pada jam berapapun harus dibatasi `movement_zone.position.x >= 560.0` agar `ForestNPCIsolationTest.gd` tidak gagal.
3. **Penyimpanan State Air Sumur Harian:** Pengambilan air sumur (+5 energi & 1 `air_bersih`) hanya boleh dilakukan 1x per hari; status ini harus tersimpan di `SaveSystem` dan bersih kembali saat tidur.
4. **Warta Harian Papan Pengumuman Dinamis:** Teks gosip makanan favorit NPC harian pada papan pengumuman harus sinkron dengan data NPC dan cuaca aktif tanpa error jika data kosong.
5. **Kinerja Render Objek Desa di Mobile:** Fasad bangunan digambar efisien di `_draw()` atau via sprite terstruktur tanpa beban draw call berlebih.

---

### Task 1: Data Model & Schema Distrik Desa (`village_zones.json` & Items)

**Files:**
- Create: `data/world/village_zones.json`
- Modify: `data/items/items.json`
- Test: `tests/VillageZonesDataTest.gd`

**Interfaces:**
- Produces: `data/world/village_zones.json` berisi metadata 4 distrik desa, koordinat fasad bangunan, posisi prop interaktif, dan zona klaster ambient NPC.
- Consumes: `data/items/items.json` menambahkan item `air_bersih`.

- [ ] **Step 1: Tulis tes verifikasi skema data desa (`tests/VillageZonesDataTest.gd`)**

```gdscript
# tests/VillageZonesDataTest.gd
extends SceneTree

func _init() -> void:
	var file := FileAccess.open("res://data/world/village_zones.json", FileAccess.READ)
	assert(file != null, "village_zones.json must exist")
	var data: Variant = JSON.parse_string(file.get_as_text())
	assert(typeof(data) == TYPE_DICTIONARY, "Data must be a Dictionary")
	
	# Verify 4 districts
	assert(data.has("districts"), "Must contain districts")
	for d in ["market_district", "civic_district", "tavern_district", "residential_district"]:
		assert(data["districts"].has(d), "Must contain district: " + d)
	
	# Verify building landmarks
	assert(data.has("buildings"), "Must contain buildings")
	assert(data["buildings"].has("town_hall"), "Must contain town_hall")
	assert(data["buildings"].has("giral_store"), "Must contain giral_store")
	assert(data["buildings"].has("talia_store"), "Must contain talia_store")
	assert(data["buildings"].has("village_granary"), "Must contain village_granary")
	
	# Verify interactive props
	assert(data.has("props"), "Must contain props")
	assert(data["props"].has("village_well"), "Must contain village_well")
	assert(data["props"].has("notice_board"), "Must contain notice_board")
	
	# Verify items.json contains air_bersih
	var ifile := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	assert(ifile != null, "items.json must exist")
	var idata: Variant = JSON.parse_string(ifile.get_as_text())
	var has_water := false
	for it in idata.get("items", []):
		if it.get("id") == "air_bersih":
			has_water = true
			break
	assert(has_water, "items.json must contain air_bersih")
	print("VillageZonesDataTest passed.")
	quit(0)
```

- [ ] **Step 2: Jalankan tes untuk memastikan gagal sebelum implementasi**

Jalankan: `& $godot --headless --script res://tests/VillageZonesDataTest.gd`  
Ekspektasi: FAIL (file `village_zones.json` belum ada).

- [ ] **Step 3: Buat `data/world/village_zones.json` dan perbarui `data/items/items.json`**

Buat data 4 distrik desa dengan koordinat yang rapi di dalam batas `x >= 560.0`, tambahkan item `air_bersih` ke `data/items/items.json`. Perbarui katalog assertion di `InventorySystemTest.gd` (33 -> 34).

- [ ] **Step 4: Jalankan tes verifikasi**

Jalankan: `& $godot --headless --script res://tests/VillageZonesDataTest.gd; & $godot --headless --script res://tests/InventorySystemTest.gd`  
Ekspektasi: PASS.

- [ ] **Step 5: Commit**

```bash
git add data/world/village_zones.json data/items/items.json tests/VillageZonesDataTest.gd tests/InventorySystemTest.gd
git commit -m "feat(data): tambahkan skema data tata kota desa hearthwood dan item air bersih"
```

---

### Task 2: Framework Objek Interaktif Desa (`VillageWell.gd` & `NoticeBoard.gd`)

**Files:**
- Create: `scripts/world/VillageWell.gd`
- Create: `scripts/world/NoticeBoard.gd`
- Test: `tests/VillageInteractivePropsTest.gd`

**Interfaces:**
- Produces:
  - `HearthwoodVillageWell`: turunan `HearthwoodInteractiveProp` (`prop_type = "village_well"`), memulihkan +5 energi, memberikan 1 `air_bersih`, 1x per hari.
  - `HearthwoodNoticeBoard`: turunan `HearthwoodInteractiveProp` (`prop_type = "notice_board"`), menghasilkan teks warta desa harian (cuaca, tips masak, gosip selera makanan NPC), dapat dibaca berulang.

- [ ] **Step 1: Tulis tes fungsionalitas sumur desa dan papan pengumuman (`tests/VillageInteractivePropsTest.gd`)**

Uji bahwa `VillageWell` memberikan 1 `air_bersih` dan memulihkan +5 energi pada interaksi pertama, menolak interaksi ganda harian, dan dapat di-reset via `reset_daily()`. Uji bahwa `NoticeBoard` mengembalikan warta harian yang memuat info cuaca dan gosip NPC.

- [ ] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/VillageInteractivePropsTest.gd`  
Ekspektasi: FAIL (kelas-kelas belum ada).

- [ ] **Step 3: Implementasikan `VillageWell.gd` dan `NoticeBoard.gd`**

Tulis `VillageWell.gd` dan `NoticeBoard.gd` mengacu pada `HearthwoodInteractiveProp` dengan visual draw taktil (atap sirap sumur, roda katrol, kertas perkamen papan pengumuman bersegel merah).

- [ ] **Step 4: Jalankan tes untuk memverifikasi kelulusan**

Jalankan: `& $godot --headless --script res://tests/VillageInteractivePropsTest.gd`  
Ekspektasi: PASS ("VillageInteractivePropsTest passed.").

- [ ] **Step 5: Commit**

```bash
git add scripts/world/VillageWell.gd scripts/world/NoticeBoard.gd tests/VillageInteractivePropsTest.gd
git commit -m "feat(world): implementasikan objek interaktif sumur desa dan papan pengumuman"
```

---

### Task 3: Pembangunan Landmark Visual & Fasad Bangunan Desa di `World.gd`

**Files:**
- Modify: `scripts/world/World.gd`
- Test: `tests/VillageLandmarksTest.gd`, `tests/ZoneGateTest.gd`

**Interfaces:**
- Produces:
  - Fasad Balai Desa (*Town Hall*) di `Rect2(1330.0, 240.0, 130.0, 84.0)` dengan tiang bendera dan taman bunga.
  - Fasad Toko Giral yang dipercantik dengan kanopi garis-garis pedagang dan peti komoditas.
  - Fasad Toko Talia yang dipercantik dengan kanopi bengkel dan display perkakas.
  - Lumbung Padi Komunal (*Village Granary*) di `Rect2(680.0, 640.0, 100.0, 76.0)`.
  - Deretan fasad rumah pondok warga di Distrik 4 dengan pagar kayu rustic.
  - Plaza paving batu bulat di sekitar koordinat `(1050, 460)`.
  - Query API: `get_village_buildings() -> Array[Dictionary]`, `get_village_building(id: String) -> Dictionary`.

- [ ] **Step 1: Tulis tes verifikasi kehadiran landmark desa (`tests/VillageLandmarksTest.gd`)**

Verifikasi bahwa Balai Desa, toko Giral & Talia, lumbung padi, dan rumah warga terdaftar dan tidak bertabrakan dengan gerbang rimba atau posisi Veral, stasiun masak, dan ranjang.

- [ ] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/VillageLandmarksTest.gd`  
Ekspektasi: FAIL.

- [ ] **Step 3: Implementasikan rendering landmark dan collider solid desa di `World.gd`**

Gantikan 3 kotak polos dengan arsitektur desa tematik lengkap berstandar Impeccable + UI-UX Pro Max, menambahkan visual Balai Desa, lumbung, pondok hunian, dan paving plaza.

- [ ] **Step 4: Jalankan tes landmark desa dan tes gerbang rimba**

Jalankan: `& $godot --headless --script res://tests/VillageLandmarksTest.gd; & $godot --headless --script res://tests/ZoneGateTest.gd`  
Ekspektasi: PASS (kedua tes lulus).

- [ ] **Step 5: Commit**

```bash
git add scripts/world/World.gd tests/VillageLandmarksTest.gd
git commit -m "feat(world): bangun fasad balai desa, lumbung padi, pondok warga, dan plaza pasar desa"
```

---

### Task 4: Integrasi Objek Interaktif Desa & Penyelarasan State di `World.gd`

**Files:**
- Modify: `scripts/world/World.gd`
- Test: `tests/VillagePropsIntegrationTest.gd`, `tests/InteractivePropTest.gd`

**Interfaces:**
- Produces:
  - Instansiasi `HearthwoodVillageWell` di `Vector2(1050.0, 460.0)`.
  - Instansiasi `HearthwoodNoticeBoard` di `Vector2(1130.0, 460.0)`.
  - Query APIs: `get_village_well() -> HearthwoodVillageWell`, `get_notice_board() -> HearthwoodNoticeBoard`.
  - Penyelarasan otomatis dengan `game_state.interacted_props_today` dan `_on_day_changed()`.

- [ ] **Step 1: Tulis tes integrasi objek desa di World (`tests/VillagePropsIntegrationTest.gd`)**

Uji bahwa `World` menginstansiasi sumur dan papan pengumuman di koordinat yang tepat, menghubungkannya ke sistem interaksi pemain, dan mereset status sumur saat hari berganti.

- [ ] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/VillagePropsIntegrationTest.gd`  
Ekspektasi: FAIL.

- [ ] **Step 3: Implementasikan penempatan dan registrasi objek desa di `World.gd`**

Tambahkan pemanggilan instansiasi props desa dari `village_zones.json` ke dalam `_setup_interactive_props()`, hubungkan sinyal interaksi ke `_game_state.mark_prop_interacted()`.

- [ ] **Step 4: Jalankan tes integrasi props dan tes prop umum**

Jalankan: `& $godot --headless --script res://tests/VillagePropsIntegrationTest.gd; & $godot --headless --script res://tests/InteractivePropTest.gd`  
Ekspektasi: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/world/World.gd tests/VillagePropsIntegrationTest.gd
git commit -m "feat(world): integrasikan sumur desa dan papan pengumuman interaktif ke dalam dunia"
```

---

### Task 5: Dinamika Sosial Warga Desa (Ambient Crowd Clustering)

**Files:**
- Modify: `scripts/world/World.gd`
- Test: `tests/VillageAmbientClusteringTest.gd`, `tests/ForestNPCIsolationTest.gd`

**Interfaces:**
- Produces:
  - Method `_update_ambient_npc_clustering(hour: int) -> void` di `World.gd`:
    - 08:00 – 12:00: 24 NPC diarahkan ke Klaster Pasar (`Rect2(920, 220, 260, 160)`).
    - 12:00 – 16:00: 24 NPC diarahkan ke Klaster Alun-Alun / Sumur (`Rect2(1000, 380, 240, 160)`).
    - 16:00 – 20:00: 24 NPC diarahkan ke Klaster Warung Pemain (`Rect2(1180, 380, 200, 160)`).
    - 20:00 – 08:00: 24 NPC menyebar di Klaster Pemukiman (`Rect2(650, 560, 350, 200)`).
    - 8 NPC tetap sebagai pengelana bebas (*free wanderers*) di seluruh `VILLAGE_AMBIENT_RECT`.
    - Batas keras `movement_zone.position.x >= 560.0`.
  - Terkoneksi otomatis dengan sinyal `time_system.hour_changed`.

- [ ] **Step 1: Tulis tes klaster pergerakan ambient NPC (`tests/VillageAmbientClusteringTest.gd`)**

Verifikasi pembagian klaster pada jam 9 (pasar), jam 13 (alun-alun), jam 18 (warung), dan jam 22 (pemukiman), serta memastikan 100% NPC ambient tidak pernah keluar dari desa (`x >= 560.0`).

- [ ] **Step 2: Jalankan tes untuk memverifikasi kegagalan**

Jalankan: `& $godot --headless --script res://tests/VillageAmbientClusteringTest.gd`  
Ekspektasi: FAIL.

- [ ] **Step 3: Implementasikan logika klaster dinamis di `World.gd`**

Tulis method `_update_ambient_npc_clustering(hour)` dan sambungkan ke pembaruan waktu dunia.

- [ ] **Step 4: Jalankan tes klaster dan tes isolasi rimba**

Jalankan: `& $godot --headless --script res://tests/VillageAmbientClusteringTest.gd; & $godot --headless --script res://tests/ForestNPCIsolationTest.gd`  
Ekspektasi: PASS (kedua tes lulus).

- [ ] **Step 5: Commit**

```bash
git add scripts/world/World.gd tests/VillageAmbientClusteringTest.gd
git commit -m "feat(world): terapkan sistem klaster dinamis ambient NPC sesuai jam aktivitas desa"
```

---

### Task 6: Verifikasi Alur Game Utama & Penyimpanan State

**Files:**
- Modify: `tests/SaveSystemTest.gd` (jika diperlukan verifikasi tambahan)
- Test: `tests/MainGameFlowTest.gd`, `tests/ZoneStateSaveTest.gd`, `tests/SaveSystemTest.gd`

**Interfaces:**
- Memastikan alur prolog tutorial dari awal permainan (hutan -> temu Rast -> petik sayur -> temu Veral di Balai Desa -> masak sup -> tidur -> layani tamu) berjalan mulus tanpa hambatan collider atau regresi state.

- [ ] **Step 1: Jalankan `MainGameFlowTest.gd`**

Jalankan: `& $godot --headless --script res://tests/MainGameFlowTest.gd`  
Ekspektasi: PASS ("Forest awakening, Rast, foraging, Veral, cooking, residence, settlement, service, and save flow passed.").

- [ ] **Step 2: Jalankan tes penyimpanan state**

Jalankan: `& $godot --headless --script res://tests/ZoneStateSaveTest.gd; & $godot --headless --script res://tests/SaveSystemTest.gd`  
Ekspektasi: PASS.

- [ ] **Step 3: Commit**

```bash
git add tests/SaveSystemTest.gd
git commit -m "test(flow): verifikasi kelancaran alur permainan utama dan simpan-muat desa ekspansi"
```

---

### Task 7: Uji Regresi Penuh Seluruh 29 Test Suites & Dokumentasi Rilis 0.7.0

**Files:**
- Modify: `MILESTONES.md`
- Modify: `docs/superpowers/plans/2026-11-20-village-expansion-v0.7.0-implementation.md`
- Test: Seluruh 29 test suite di direktori `tests/` (25 eksisting + 4 baru)

**Interfaces:**
- Produces: 100% kelulusan dari 29 test suites tanpa galat.

- [ ] **Step 1: Eksekusi seluruh 29 file test suite secara headless**

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

Ekspektasi: 29 PASSED, 0 FAILED.

- [ ] **Step 2: Dokumentasikan penyelesaian Versi 0.7.0 di `MILESTONES.md`**

Tambahkan rincian deliverable dan checklist Definition of Done v0.7.0 di `MILESTONES.md`.

- [ ] **Step 3: Centang seluruh daftar tugas di dokumen rencana ini**

Ubah seluruh `- [ ]` menjadi `- [x]` di `docs/superpowers/plans/2026-11-20-village-expansion-v0.7.0-implementation.md`.

- [ ] **Step 4: Commit penyelesaian rilis v0.7.0**

```bash
git add MILESTONES.md docs/superpowers/plans/2026-11-20-village-expansion-v0.7.0-implementation.md
git commit -m "chore(release): rampungkan implementasi penuh ekspansi desa hearthwood v0.7.0"
```
