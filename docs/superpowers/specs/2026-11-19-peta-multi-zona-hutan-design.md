# Design Spec: Peta Multi-Zona Hutan Terhubung (Versi 0.3.0)

**Tanggal:** 2026-11-19  
**Status:** Siap untuk Persetujuan Akhir  
**Target Rilis:** Versi 0.3.0 (Update Ekspansi Peta Bagian 1 — Rimba)  
**Terkait:** `PRD Hearthwood Warung Rimba (Versi 0.3.0).md`, `AGENTS.md`, `ARCHITECT.md`

---

## 1. Maksud dan Alasan (Intent & Why)

Saat ini (v1.0 dan v0.2.0), dunia *Hearthwood: Warung Rimba* menggunakan satu peta datar tunggal berukuran `Vector2i(1600, 880)` di mana hutan (sisi kiri) dan desa (sisi kanan) berada pada satu kanvas terbuka tanpa batas.

Pemain menginginkan pengalaman eksplorasi ala *Harvest Moon* (seperti *Back to Nature* atau *Friends of Mineral Town*), di mana peta dibagi menjadi beberapa wilayah bermakna yang saling terhubung melalui titik-titik transisi. Pembangunan dimulai dari area rimba/hutan terlebih dahulu sebelum memecah area desa di masa mendatang. Hal ini memperkuat atmosfer petualangan, memperjelas ritme rutinitas harian (*cozy loop*), serta memberi tempat fisik nyata bagi perkembangan quest cerita Rast dan petunjuk *Misteri Asap*.

---

## 2. Tujuan, Non-Tujuan, dan Anti-Tujuan

### 2.1 Tujuan (Goals)
1. **Memecah Hutan Menjadi 6 Wilayah Saling Terhubung**:
   - Memiliki topologi navigasi yang jelas antar-wilayah.
   - Pohon Raksasa (*Great Tree*) berada di posisi paling dalam (Utara / Atas).
   - Seluruh wilayah memiliki objek visual ikonik yang mudah dikenali.
   - Dua wilayah memiliki jejak aktivitas manusia, dan satu wilayah menjadi gerbang transisi menuju Desa (Warung).
2. **Atmosfer Hutan Sunyi & Bebas Ambient NPC**:
   - Menghilangkan kemunculan 32 NPC ambient di seluruh kawasan rimba (NPC ambient dikhususkan hanya di area desa).
   - Hanya NPC yang relevan dengan rimba (khususnya Rast si penebang kayu) yang hadir sesuai jadwal kerjanya di hutan.
3. **Mekanik Transisi Layar Instan & Waktu Alami**:
   - Transisi fade out/in instan saat pemain melangkah melewati batas gerbang zona.
   - Waktu dalam game tetap berjalan normal secara real-time (tidak ada penalti lonjakan waktu instan saat berpindah layar).
4. **Alur Prolog & Progresi Akses Bertahap (Story Gating)**:
   - Tokoh utama terbangun di Wilayah 6 (Pohon Raksasa) saat game baru dimulai.
   - Saat pemain melangkah ke selatan keluar menuju Wilayah 3 (Pos Rast), jalur di belakangnya tertutup oleh batang pohon raksasa yang tumbang.
   - Wilayah 1–4 terbuka untuk kebutuhan harian warung. Wilayah 5 & 6 terkunci sampai pemain menyelesaikan Quest Rast Hati 2 (*"Eksplorasi Hutan Dalam"*), di mana Rast membantu memotong dan menyingkirkan pohon tumbang tersebut.
5. **Indikator Lokasi UI**:
   - Memunculkan toast banner nama wilayah selama 2,5 detik di bagian atas layar saat pemain memasuki wilayah baru.
6. **Performa Ringan & Kompatibilitas State**:
   - Menjamin 14 unit test Godot yang ada tetap lulus dan sistem save/load tetap 100% kompatibel.

### 2.2 Non-Tujuan (Non-Goals)
- Belum memecah area Desa menjadi multi-zona (area Desa tetap sebagai satu kesatuan scene/zona yang terhubung ke Wilayah 1 di versi 0.3.0 ini).
- Tidak menambahkan monster, musuh, sistem pertarungan, atau bahaya kematian di rimba.
- Tidak mengubah mekanik memasak, afeksi, jam operasional toko Giral/Talia, atau tier warung yang sudah ada di 0.2.0.

### 2.3 Anti-Tujuan (Anti-Goals)
- **Anti-Tujuan 1 (Stressful Travel Time):** Mengurangi energi atau memajukan waktu game secara mendadak tiap kali pemain berganti layar. Ini merusak rasa *cozy* dan menyusahkan pemain pemula.
- **Anti-Tujuan 2 (Heavy Loading Screens):** Membuka loading bar lambat antar-layar yang membebani perangkat Android kelas menengah/rendah.

---

## 3. Batasan Teknis & Desain (Constraints)

1. **Android-First & Performa Perangkat Rendah:** UI interaksi minimal 44×44 dp, memory footprint rendah, transisi layar zero-stutter.
2. **Godot 4.x & Pixel Snap:** Rendering Nearest, koordinat tile berbasis kelipatan 16×16 piksel.
3. **Data-Driven:** Konfigurasi titik spawn foraging dan transisi gerbang terstruktur dalam data, bukan hardcode acak di skrip.
4. **Backward Compatibility & Save Safety:** File save `user://savegame.json` dari v1.0 dan 0.2.0 tetap valid tanpa migrasi schema; pemain lama yang sudah menyelesaikan Quest Rast Hati 2 otomatis memiliki status pembukaan rute hutan dalam.

---

## 4. Pendekatan Arsitektur (Approaches Considered)

Tiga pendekatan telah dievaluasi:

### Pendekatan A: Multi-Scene Berpindah (Satu Scene `.tscn` Mandiri per Wilayah)
- **Deskripsi:** Tiap wilayah menjadi scene terpisah dan berganti via `change_scene_to_packed()`.
- **Trade-off:** Memerlukan serialisasi status foraging harian dan cuaca berulang kali ke disk; risiko stutter saat loading di Android.

### Pendekatan B: Zone Container Architecture dalam World Manager (Dipilih)
- **Deskripsi:** `World.gd` bertindak sebagai container yang menaungi 6 sub-zona hutan dan 1 zona desa menggunakan **koordinat global terpisah (non-overlapping offset bounds)**. Saat pemain menyentuh area gerbang (`ZoneGate2D`), `World.gd` memicu fade out/in, menonaktifkan proses sub-zona lama, mengaktifkan sub-zona baru, dan menyesuaikan batas kamera (*Camera2D limits*).
- **Trade-off:**
  - *Kelebihan:* Transisi instan zero-latency, tidak ada reload overhead, kompatibel 100% dengan save data lama dan seluruh 14 automated unit tests Godot.
  - *Alasan Dipilih:* Performa terbaik di perangkat mobile dan arsitektur paling stabil.

### Pendekatan C: Seamless Room Bounds (Satu Peta Kontinu dengan Kamera Terkunci)
- **Deskripsi:** Seluruh wilayah digambar berdampingan pada kanvas raksasa dengan kamera terkunci per kamar.
- **Trade-off:** Batas wilayah menjadi kaku mengikuti rasio layar dan GPU tetap memproses geometri di luar pandangan.

---

## 5. Rincian Desain 6 Wilayah Hutan Rimba

### 5.1 Struktur Topologi dan Konektivitas

```
                  [ Wilayah 6: Suaka Pohon Raksasa ]
                        (Paling Dalam / Utara)
                                  ▲
                                  │ (Tertutup Batang Pohon Tumbang setelah Prolog;
                                  │  Terbuka via Quest Rast Hati 2)
      [ Wilayah 5: Lembah Akar ] ◄─┼─► [ Wilayah 3: Pos Penebang ] ◄───► [ Wilayah 4: Semak Belukar ]
         (Menhir & Akar Gantung)   │       (Gubuk Perkakas Rast)            (Fairy Ring & Buah Liar)
                  ▲                │                   ▲                               ▲
                  │                ▼                   │                               │
      [ Wilayah 2: Aliran Sungai ] ◄───────────────────┴───► [ Wilayah 1: Pintu Rimba ]
         (Jembatan Gelondongan)                                 (Lentera & Akses Desa) ──► KE DESA
```

### 5.2 Rincian Spesifikasi Wilayah

| ID Wilayah | Nama Wilayah | Posisi Relatif | Objek Ikonik | Jejak Manusia? | Jalur Terhubung | Sumber Bahan (Foraging) |
|---|---|---|---|---|---|---|
| `forest_zone_1` | **Pintu Rimba** | Tenggara / Gerbang | Tiang lentera minyak tua & papan arah kayu retak ke desa | **Ada (#1)** | Timur: ke Desa (Warung)<br>Barat: ke Wilayah 2<br>Utara: ke Wilayah 3 & 4 | Daun hutan, sayur liar tepi jalur setapak |
| `forest_zone_2` | **Aliran Sungai Bebatuan** | Barat Daya | Jembatan gelondongan kayu alami melintasi riam air jernih | Tidak ada | Timur: ke Wilayah 1<br>Utara: ke Wilayah 5 | Ikan sungai, batu kali, tanaman air |
| `forest_zone_3` | **Pos Penebang Kayu** | Tengah / Pusat Rimba | Gubuk perkakas beratap jerami, tumpukan kayu gelondong, & tungku perapian | **Ada (#2)** (Pos kerja Rast) | Selatan: ke Wilayah 1<br>Barat: ke Wilayah 5<br>Timur: ke Wilayah 4<br>Utara: Rintangan Pohon Tumbang ke Wilayah 6 | Kayu tebang, ranting kering, resin pohon |
| `forest_zone_4` | **Semak Belukar Lembab** | Timur Tengah | Lingkaran jamur purba (*Fairy Ring*) & semak berry lebat | Tidak ada | Barat: ke Wilayah 3<br>Selatan: ke Wilayah 1 | Buah liar, daun aromatik, jamur hutan (melimpah saat hujan) |
| `forest_zone_5` | **Lembah Akar Purba** | Barat Laut | Batu menhir purba terbelah & sulur akar gantung raksasa | Tidak ada (Zona rintangan) | Selatan: ke Wilayah 2<br>Timur: ke Wilayah 3<br>Utara: ke Wilayah 6 | Akar rempah kualitas tinggi, lumut herba |
| `forest_zone_6` | **Suaka Pohon Raksasa** | Paling Utara / Terdalam | Pohon Beringin Raksasa (*Great Tree*) berongga & kanopi berkas cahaya | Tidak ada (Titik awal MC bangun) | Selatan: Jalur keluar ke Wilayah 3 & 5 | Bahan langka purba, serpihan kayu terbakar (*Misteri Asap*) |

### 5.3 Alur Prolog & Mekanik Penguncian Batang Pohon Tumbang

1. **Awal Game Baru (Prologue Awakening):**
   - Tokoh utama terbangun di Suaka Pohon Raksasa (Wilayah 6) di bawah Pohon Purba pada posisi `Vector2(210.0, 462.0)`.
   - Jalur ke Selatan menuju Wilayah 3 terbuka untuk dilewati keluar pertama kali.
2. **Pemicu Rintangan Pohon Tumbang:**
   - Begitu pemain melangkah melewati batas gerbang menuju Wilayah 3, jalur di belakangnya tertutup oleh batang pohon raksasa yang roboh dan reruntuhan akar berduri.
   - Jika pemain mencoba kembali ke Utara, muncul dialog singkat MC: *"Batang pohon besar tumbang menutup jalan kembali ke pohon raksasa itu... Jalurnya buntu."*
3. **Pembuka Kunci (Quest Rast Hati 2):**
   - Saat pemain menjalankan Quest Rast Hati 2 (*"Eksplorasi Hutan Dalam"*), Rast menggunakan keahlian dan kapaknya untuk memotong dan menyingkirkan batang pohon tumbang tersebut.
   - Status tersimpan dalam `GameState.is_deep_forest_unlocked = true` dan jalur ke Wilayah 5 & 6 terbuka bebas secara permanen.

### 5.4 Penempatan & Jadwal NPC

- **NPC Ambient:** Dinonaktifkan di seluruh kawasan hutan rimba (`_spawn_ambient_npcs()` hanya berlaku untuk area desa).
- **Rast (Penebang Kayu):**
  - **Pukul 06:00–16:00:** Berada di **Wilayah 3 (Pos Penebang Kayu)** di dekat tumpukan gelondong kayu dan gubuk perkakasnya.
  - **Pukul 16:00–22:00:** Kembali ke pemukiman desa.
  - Penjadwalan mulai pukul 06:00 memastikan Rast langsung dapat ditemui saat pemain tiba di Wilayah 3 pada Hari 1 Prolog tanpa jeda tunggu.

---

## 6. Antarmuka Pengguna (UI/UX)

1. **Location Toast Banner:**
   - Muncul otomatis selama 2,5 detik di bagian atas layar setiap kali pemain memasuki wilayah baru (misal: `[ Pos Penebang Kayu ]` atau `[ Suaka Pohon Raksasa ]`).
   - Warna latar hitam transparan elegan dengan tipografi putih ramah sentuh.
2. **Papan Peta Pintu Rimba:**
   - Objek papan penunjuk di Wilayah 1 dapat diinteraksi untuk menampilkan dialog informasi tata letak rimba dan arah menuju desa.

---

## 7. Hal yang Diserahkan kepada Pelaksana (Left to Builder)

1. **Ukuran Bounding Box Per-Wilayah:** Builder mengatur dimensi kanvas masing-masing wilayah (rata-rata `40×25` tile per zona pada koordinat global non-overlapping).
2. **Detail Ornamen Visual:** Dekorasi tepian pohon, tebing batu, dan pola jembatan kayu menggunakan aset yang ada di `main_tiles.png`.
3. **Koordinat Titik Foraging:** Penempatan presisi posisi `Vector2` untuk 12 titik foraging yang dipindahkan ke dalam ke-6 zona baru.
4. **Parameter Tween Transisi:** Durasi fade out 0,2 detik dan fade in 0,2 detik menggunakan ColorRect transisi di CanvasLayer.
