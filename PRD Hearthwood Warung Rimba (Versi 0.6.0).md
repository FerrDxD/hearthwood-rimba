# PRD: Hearthwood: Warung Rimba (Versi 0.6.0)

**Status:** Draf Lengkap untuk Persetujuan  
**Tanggal:** 2026-11-20  
**Versi Target:** 0.6.0 — Ekosistem & Pembangunan 6 Wilayah Rimba  
**Berdasarkan:** PRD v0.4.0, ARCHITECT.md, DESIGN.md, AGENTS.md, MILESTONES.md  
**Dependen:** Sistem Dunia & Gerbang Zona (`World.gd`, `ZoneGate2D.gd`, Fase 10, v0.5.3)

---

## 1. Ringkasan Eksekutif

Pada Versi 0.5.3, seluruh antarmuka permainan (UI Kit) telah rampung diimplementasikan secara taktil dan lolos uji regresi 100%. Fondasi 6 wilayah hutan rimba telah terdaftar di `World.gd` melalui `ZONE_RECTS` dan `ZONE_NAMES`, lengkap dengan sistem gerbang transisi (`ZoneGate2D`). Namun, area-area tersebut saat ini masih berupa kanvas kosong polos tanpa identitas visual, objek interaktif, atau ekosistem alam yang hidup.

**Versi 0.6.0** berfokus pada **Pembangunan Penuh & Pengisian 6 Wilayah Rimba (Forest Overhaul)**. Pemain tidak lagi hanya berjalan di antara pohon generik acak, melainkan menjelajahi 6 zona tematik yang memiliki:
1. **Landmark Visual & Karakteristik Unik (Tematik Kuat - Opsi A):** Pintu gapura perbatasan, aliran sungai berbatu, pos kemah penebang kayu, semak lembab berawa, lembah akar purba melengkung, dan suaka pohon suci raksasa.
2. **Ekologi Sumber Daya Spesifik per Zona:** Persebaran hasil bumi terkurasi sesuai bioma lingkungan masing-masing.
3. **Interaktivitas Lingkungan Tambahan:** Mekanik interaksi lingkungan yang santai (*cozy-first*), seperti menggoyang pohon buah, memeriksa celah batu sungai/tunggul kayu, desiran semak rimbun, dan membasuh muka di mata air alami untuk memulihkan energi.
4. **Atmosfer & Ambience Menyeluruh:** Suara alam kontekstual (gemericik sungai, desau angin rawa, hening magis) dan partikel visual (kabut tipis, kunang-kunang, dedaunan gugur).
5. **Kehadiran Karakter Rast:** Menghadirkan pos kemah alami milik Rast (penjaga rimba) di Pos Penebang Kayu untuk memperkuat narasi bertahan hidup.

---

## 2. Tujuan dan Non-Tujuan

### 2.1 Tujuan Utama
1. **Ekspansi Visual & Terrain 6 Zona:** Membangun set elemen visual, rintangan alam, dan landmark khas di setiap zona sesuai batas `Rect2` yang telah ditetapkan.
2. **Distribusi Foraging Tematik:** Mengonversi sistem spawn forage kaku menjadi ekosistem berbasis zona yang dinamis dan terbarukan harian (*daily respawn*).
3. **Mekanik Interaksi Baru Ramah Sentuh (Android):**
   - *Shake Tree (Pohon Buah)*: Menggoyang pohon menghasilkan buah segar.
   - *Inspectable Natural Hollows (Celah Bebatuan/Tunggul)*: Menemukan bahan alam tersembunyi.
   - *Fresh Spring (Mata Air Alami)*: Membasuh muka untuk memulihkan +10 energi sekali per hari.
   - *Rustling Foliage (Semak Berdesir)*: Efek visual dan audio saat pemain melintasi semak tebal.
4. **Pos Kemah Rast di Rimba:** Pos Penebang Kayu (Zona 3) menjadi pusat aktivitas Rast sebelum ia berkeliling patroli.
5. **Zero Broken Tests:** Seluruh 21 test suite eksisting di Godot (terutama uji gerbang, aliran permainan, alokasi forage, dan isolasi NPC) wajib dipertahankan kelulusannya 100%.

### 2.2 Non-Tujuan (Ditunda ke Fase Berikutnya)
- **Sistem Cuaca Kompleks Berpengaruh pada Forage:** Titik spawn khusus hujan/badai ditunda hingga sistem cuaca dinamis terintegrasi penuh.
- **Sistem Pertarungan & Musuh Agresif:** Tetap mempertahankan filosofi *cozy first* — tidak ada monster atau bahaya mematikan di hutan.
- **Grinding Alat Berat:** Tidak ada alat kapak/cangkul yang menghabiskan stamina berlebih; seluruh interaksi berbasis aksi sentuh/tombol `E`.

---

## 3. Peta & Spesifikasi 6 Wilayah Rimba

Setiap zona memiliki ukuran standar **560 × 480 px** (skala layar Godot) dengan batas koordinat yang tersambung melalui gerbang transisi:

```
                  [ Zona 4: Semak Belukar Lembab ]
                                 ▲
                                 │
 [ Zona 5: Lembah Akar Purba ] ◄─┼─► [ Zona 3: Pos Penebang Kayu ] ◄─► [ Desa Hearthwood ]
            ▲                    │                  ▲
            │                    ▼                  │
 [ Zona 6: Suaka Pohon Raksasa ] ◄── [ Zona 1: Pintu Rimba ] ◄────────┘
                                 │
                                 ▼
                     [ Zona 2: Aliran Sungai Bebatuan ]
```

---

### 3.1 Zona 1: Pintu Rimba (`forest_zone_1`)
- **Nama Tampilan:** "Pintu Rimba"
- **Koordinat:** `Rect2(0.0, 960.0, 560.0, 480.0)`
- **Karakter Visual & Landmark:**
  - Pintu gapura kayu sederhana penanda batas antara wilayah desa beradab dan hutan liar.
  - Papan penunjuk arah bertuliskan petunjuk ke arah desa, pos penebang, dan aliran sungai.
  - Jalan setapak kerikil yang mulai ditumbuhi rumput liar.
- **Sumber Daya & Foraging:**
  - Sayur Liar (`sayur_liar`)
  - Daun Hutan (`daun_hutan`)
  - Ranting Kayu Kering (`kayu`)
- **Interaktivitas Khusus:**
  - Papan Penunjuk Arah (`Signpost`): Tombol `E` menampilkan panduan arah peta 6 wilayah rimba.
- **Suasana & Audio:**
  - Ambience burung hutan pagi hari yang menenangkan, cahaya matahari menyelinap di sela dedaunan.

---

### 3.2 Zona 2: Aliran Sungai Bebatuan (`forest_zone_2`)
- **Nama Tampilan:** "Aliran Sungai Bebatuan"
- **Koordinat:** `Rect2(-560.0, 960.0, 560.0, 480.0)`
- **Karakter Visual & Landmark:**
  - Sungai jernih yang membelah area secara diagonal dari barat laut ke tenggara.
  - Formasi bebatuan kali besar dan batu loncatan (*stepping stones*) untuk menyeberang.
  - Jembatan kayu lapuk kecil di sisi hilir.
  - Tepian berpasir basah dan rumput air tebal.
- **Sumber Daya & Foraging:**
  - Ikan Sungai (`ikan_sungai`) — dapat ditangkap di tepi ceruk batu dangkal.
  - Batu Kali Halus (`batu`)
  - Lumut Sungai Segar (bahan herbal baru: `lumut_sungai`)
- **Interaktivitas Khusus:**
  - **Mata Air Alami / Tepian Air Bersih:** Pemain dapat membasuh muka sekali per hari untuk memulihkan **+10 energi** (muncul dialog hangat: *"Air sungai pegunungan terasa dingin dan menyegarkan wajahmu. Energi bertambah +10."*).
- **Suasana & Audio:**
  - Suara ambient air mengalir deras dan gemericik bebatuan kali (`sfx_river_loop`).

---

### 3.3 Zona 3: Pos Penebang Kayu (`forest_zone_3`)
- **Nama Tampilan:** "Pos Penebang Kayu"
- **Koordinat:** `Rect2(0.0, 480.0, 560.0, 480.0)`
- **Karakter Visual & Landmark:**
  - Pos kemah peristirahatan Rast: tenda kain kanvas, bangku balok kayu, dan perapian batu dengan abu hangat.
  - Tumpukan kayu gelondongan rapi dan tunggul-tunggul pohon tua berlumut.
  - Kapak tua berkarat yang menancap di salah satu tunggul sebagai dekorasi cerita.
- **Sumber Daya & Foraging:**
  - Balok Kayu Berkualitas (`kayu`)
  - Jamur Kayu Tiram di tunggul lapuk (`jamur_kayu`)
  - Kulit Kayu Berserat (`kulit_kayu`)
- **Interaktivitas Khusus:**
  - **Tunggul Lapuk Periksa (`Inspectable Stump`):** Memeriksa tunggul berongga sekali sehari untuk mendapatkan jamur tersembunyi atau serangga kecil.
  - **Kemah Rast:** Rast akan berada di sini pada waktu istirahat siangnya (12.00–14.00) dan malam hari.
- **Suasana & Audio:**
  - Suara hembusan angin rimba dan derit dahan kayu kering.

---

### 3.4 Zona 4: Semak Belukar Lembab (`forest_zone_4`)
- **Nama Tampilan:** "Semak Belukar Lembab"
- **Koordinat:** `Rect2(560.0, -480.0, 560.0, 480.0)`
- **Karakter Visual & Landmark:**
  - Rerumputan liar setinggi pinggang dan vegetasi semak lebat.
  - Genangan air rawa kecil berlumpur dengan tanaman paku-pakuan raksasa.
  - Formasi pohon rindang dengan kanopi rapat yang membuat suasana sedikit temaram.
- **Sumber Daya & Foraging:**
  - Buah Beri Rimba Manis (`buah_liar`)
  - Jamur Hutan Payung Lembab (`jamur_hutan`)
  - Daun Aromatik Hutan (`daun_hutan`)
- **Interaktivitas Khusus:**
  - **Pohon Buah Rimbun (Shake Fruit Tree):** Pohon berdaun lebat dengan buah merah menggantung; dekati dan tekan `E` untuk menggoyang pohon -> 2–3 buah liar jatuh berhamburan ke tanah.
  - **Semak Berdesir (Rustling Bushes):** Semak yang bergoyang dan memutar suara desau gemerisik halus saat dilintasi tubuh pemain.
- **Suasana & Audio:**
  - Partikel kabut tipis (*ground mist*) melayang perlahan di atas tanah.
  - Suara serangga hutan, tonggeret sore hari, dan kicau katak rawa.

---

### 3.5 Zona 5: Lembah Akar Purba (`forest_zone_5`)
- **Nama Tampilan:** "Lembah Akar Purba" (Bagian dari Rimba Dalam / *Deep Forest*)
- **Koordinat:** `Rect2(-560.0, 480.0, 560.0, 480.0)`
- **Status Akses:** Terkunci oleh rintangan batang pohon tumbang hingga pemain menerima Izin Jelajah Rimba Dalam dari Veral/Rast.
- **Karakter Visual & Landmark:**
  - Akar raksasa melengkung setinggi dua kali tubuh pemain, membentuk terowongan dan kanopi alami.
  - Fosil bebatuan purba tertutup lumut tebal kehijauan.
  - Tanah lembab berwarna kehitaman kaya humus.
- **Sumber Daya & Foraging:**
  - Akar Rempah Wangi Langka (`akar_rempah`) — bahan masakan bergengsi untuk masakan warung tier tinggi.
  - Getah Pinus Harum (`getah_pinus`)
  - Jamur Fosfor Redup (`jamur_hutan`)
- **Interaktivitas Khusus:**
  - **Celah Akar Purba (Inspectable Root Cleft):** Memeriksa celah akar berongga untuk memungut akar rempah berkualitas tinggi (jaminan bintang 2/3).
- **Suasana & Audio:**
  - Partikel spora hutan melayang redup di udara.
  - Musik bernuansa sunyi, misterius, dan damai (*deep_forest_theme*).

---

### 3.6 Zona 6: Suaka Pohon Raksasa (`forest_zone_6`)
- **Nama Tampilan:** "Suaka Pohon Raksasa"
- **Koordinat:** `Rect2(0.0, 0.0, 560.0, 480.0)`
- **Signifikansi Cerita:** Lokasi prolog di mana pemain pertama kali terbangun di awal permainan tanpa ingatan lengkap.
- **Karakter Visual & Landmark:**
  - **Pohon Raksasa Purba (The Great Tree):** Pohon mahabesar di tengah suaka dengan diameter batang megah dan dahan menjulang melindungi seluruh suaka.
  - **Altar Batu Bertulis Misterius:** Altar batu kuno di dekat pangkal pohon tempat kelak petunjuk utama "Misteri Asap" terungkap.
  - Lentera kuno tergantung di dahan bawah pohon raksasa yang menyala redup saat senja dan malam.
- **Sumber Daya & Foraging:**
  - Daun Suci Raksasa (`daun_hutan`)
  - Buah Manis Embun Pagi (`buah_liar`)
- **Interaktivitas Khusus:**
  - **Altar Batu Misteri:** Interaksi `E` menampilkan narasi refleksi pemain mengenai kedatangannya di Rimba Hearthwood dan desau asap yang samar di kejauhan.
  - **Tempat Rehat di Bawah Pohon:** Area teduh yang mengembalikan pemain ke suasana nostalgia awal petualangan.
- **Suasana & Audio:**
  - Pendaran partikel kunang-kunang keemasan (*golden fireflies*) berhamburan perlahan.
  - Suara desau daun keramat dan hembusan angin damai yang hangat.

---

## 4. Mekanik Interaktivitas Lingkungan Baru

Seluruh interaktivitas lingkungan dirancang tanpa antarmuka rumit, cukup menggunakan sentuhan pada layar atau tombol interaksi standar (`E` / tombol aksi layar sentuh):

| Tipe Interaksi | Objek | Mekanik Gameplay | Batas Harian / Cooldown |
|----------------|-------|------------------|-------------------------|
| **Goyang Pohon (Shake Tree)** | Pohon Beri di Zona 4 & Pohon Apel Hutan di Zona 1 | Tekan `E`: Batang bergetar, 1–3 buah jatuh ke tanah sebagai `ItemPickup`. | 1 kali per pohon per hari (reset saat tidur). |
| **Basuh Muka (Fresh Water Spring)** | Tepian Air Alami di Zona 2 | Tekan `E`: Suara gemericik segar, memulihkan **+10 energi**. | 1 kali per hari per pemain. |
| **Periksa Celah (Inspect Hollow)** | Tunggul Lapuk di Zona 3 & Celah Akar di Zona 5 | Tekan `E`: Pemain meraba ke dalam celah, mendapatkan 1 item acak (jamur, rempah, atau umpan). | 1 kali per celah per hari. |
| **Semak Berdesir (Rustling Foliage)** | Semak Rimbun di Zona 1, 3, dan 4 | Pemain berjalan menembus semak: Sprite semak meliuk 10-15 derajat disertai efek suara krosak daun halus. | Tidak ada batas (kosmetik/feedback fisik). |
| **Membaca Prasasti / Altar** | Papan Petunjuk Zona 1 & Altar Purba Zona 6 | Tekan `E`: Membuka kotak dialog lore/arah tanpa jeda menu. | Kapan saja. |

---

## 5. Taksonomi Sumber Daya Foraging per Zona

| ID Item | Nama Tampilan | Zona Persebaran | Nilai Energi Masak | Kegunaan Utama |
|---------|---------------|-----------------|--------------------|----------------|
| `sayur_liar` | Sayur Liar Segar | Zona 1, Zona 3 | +10 energi | Bahan dasar Sup Sayur Bening, disukai Veral & Talia. |
| `daun_hutan` | Daun Herbal Rimba | Zona 1, Zona 4, Zona 6 | +5 energi | Bahan aromatik lalapan dan bumbu rebusan. |
| `kayu` | Kayu Gelondongan | Zona 1, Zona 3 | — | Bahan upgrade warung dan tungku masak. |
| `batu` | Batu Kali Halus | Zona 2 | — | Bahan perbaikan cobek/alat masak batu. |
| `ikan_sungai` | Ikan Sungai Segar | Zona 2 | +25 energi | Masakan bergizi tinggi, disukai Giral & Casha. |
| `lumut_sungai` | Lumut Sungai Halus | Zona 2 | +5 energi | Campuran ramuan herbal & penyejuk masakan. |
| `buah_liar` | Buah Beri Hutan | Zona 4, Zona 6 | +15 energi | Camilan segar instan, hadiah favorit Rave & Arin. |
| `jamur_hutan` | Jamur Payung Hutan | Zona 4, Zona 5 | +12 energi | Resep Tumis Jamur Rimba, disukai Jev & Gil. |
| `akar_rempah` | Akar Rempah Purba | Zona 5 | +30 energi | Resep masakan spesial warung tier 3/4 & hadiah bernilai tinggi. |

---

## 6. Integrasi Narasi: Pos Kemah Rast

Rast tidak lagi hanya berdiri statis di koordinat prolog. Di v0.6.0:
1. **Pusat Rumah Rimba:** Tenda kanvas dan perapian di Zona 3 menjadi titik kumpul alami Rast saat tidak sedang berpatroli.
2. **Jadwal Harian Rast:**
   - 06.00 – 09.00: Berada di Pos Penebang Kayu (Zona 3), menyiapkan kayu bakar.
   - 09.00 – 14.00: Patroli ke Pintu Rimba (Zona 1) dan mengawasi perbatasan desa.
   - 14.00 – 18.00: Berpatroli ke Aliran Sungai (Zona 2) untuk memeriksa perangkap ikan.
   - 18.00 – 22.00: Kembali ke Pos Penebang Kayu (Zona 3), duduk di dekat perapian.
3. **Pemberian Hadiah & Dialog:** Pemain dapat menghampiri Rast di tendanya pada malam hari untuk menyerahkan masakan hangat tanpa harus mencarinya di semak-semak liar.

---

## 7. Desain Teknis & Arsitektur Implementasi

### 7.1 Struktur Data & File Baru
- `data/world/forest_zones.json`: Menyimpan metadata landmark, posisi objek interaktif (pohon buah, mata air, tunggul), dan koordinat spawn forage harian.
- `scripts/world/InteractiveProp.gd`: Kelas dasar untuk objek lingkungan yang dapat diinteraksikan (`shake`, `inspect`, `refresh_daily`).
- `scripts/world/FruitTree.gd`: Turunan `InteractiveProp` khusus pohon yang bergetar dan menjatuhkan buah.

### 7.2 Modifikasi `World.gd`
- Mengganti fungsi `_place_trees()` generik dengan pemanggilan pembuatan landmark spesifik per zona.
- Menambahkan `_draw_zone_landmarks()` untuk merender sungai, gapura kayu, kemah Rast, akar melengkung, dan altar pohon raksasa secara prosedural atau berbasis `TileMapLayer`.
- Menghubungkan fungsi reset harian (`TimeSystem.day_changed`) untuk menyegarkan pohon buah, mata air, dan celah tunggul.

### 7.3 Kompatibilitas Test Suites (Strict Contract)
- Mempertahankan koordinat spawn sayur prolog (`FOREST_VEGETABLE_POSITION = Vector2(104.0, 1178.0)`) di Zona 1 agar `MainGameFlowTest.gd` tetap lulus 100%.
- Menjaga penghalang batang tumbang (`_update_fallen_tree_barriers`) di gerbang Zona 3-5, 3-6, dan 2-5 agar `FallenTreeBarrierTest.gd` dan `ZoneGateTest.gd` tetap valid.
- Menjaga isolasi 32 ambient NPC desa di `VILLAGE_AMBIENT_RECT` agar `ForestNPCIsolationTest.gd` tetap hijau.

---

## 8. Definition of Done (DoD) Versi 0.6.0

- [ ] Seluruh 6 zona rimba memiliki landmark visual yang dapat dibedakan dengan jelas dalam sekali pandang.
- [ ] Tersedia mekanik interaktif: Pohon buah bisa digoyang, mata air memulihkan energi, tunggul bisa diperiksa, dan semak berdesir saat dilewati.
- [ ] Hasil alam terdistribusi tematik dan terisi penuh di masing-masing 6 zona dengan reset harian yang stabil.
- [ ] Kemah Rast berdiri di Zona 3 dan jadwal patroli Rast di rimba berjalan akurat.
- [ ] Seluruh 21 test suites di direktori `tests/` lulus pengujian headless tanpa galat (21/21 passed).
- [ ] Progres status interaktivitas harian tersimpan rapi di `SaveSystem` (`user://savegame.json`).
