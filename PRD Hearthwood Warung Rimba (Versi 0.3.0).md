# PRD: Hearthwood: Warung Rimba (Versi 0.3.0)

**Status:** Draf Lengkap untuk Persetujuan  
**Tanggal:** 2026-11-19  
**Berdasarkan:** PRD Versi Awal, PRD 0.2.0, ARCHITECT.md, AGENTS.md, Hasil Brainstorming Peta Multi-Zona  
**Dependen:** Seluruh sistem v1.0 dan 0.2.0 (Fase 0–17)

---

## 1. Ringkasan Eksekutif

Update **0.3.0** berfokus pada **Ekspansi Peta Multi-Zona Terhubung (Fase 1: Rimba Raya)**. Menjawab kebutuhan pemain akan dunia yang lebih hidup dan terstruktur ala *Harvest Moon*, peta hutan yang sebelumnya bersatu dengan desa kini dimekarkan menjadi **6 wilayah terpisah yang saling terhubung** dengan titik transisi layar, objek ikonik unik, dan sebaran bahan baku yang tematik.

Update ini juga memperkuat alur cerita prolog dan quest Rast (Penebang Kayu) melalui mekanik rintangan pohon tumbang yang mengunci rute hutan dalam setelah pemain pertama kali melangkah keluar, sebelum akhirnya dibuka kembali melalui progres ekspedisi bersama Rast.

---

## 2. Tujuan dan Non-Tujuan

### 2.1 Tujuan Utama (Keputusan)
1. **Peta Multi-Zona Hutan Terhubung:** Menghadirkan 6 wilayah hutan yang saling terhubung dengan navigasi yang jelas:
   - Pohon Raksasa berada di bagian paling dalam (Utara / Atas).
   - Seluruh wilayah memiliki objek visual ikonik.
   - Dua wilayah memiliki jejak aktivitas manusia, dan satu wilayah menjadi akses gerbang menuju desa.
2. **Atmosfer Hutan Khusus:** Menghilangkan NPC ambient di seluruh kawasan rimba agar hutan terasa alami dan tenang; NPC ambient hanya berada di area desa.
3. **Mekanik Transisi Layar Instan:** Transisi fade out/in yang cepat saat menyentuh batas gerbang zona dengan waktu game yang terus mengalir alami secara real-time.
4. **Alur Prolog & Gating Pohon Tumbang:**
   - MC bangun di Wilayah 6 (Pohon Raksasa) saat game baru.
   - Saat melangkah keluar ke Wilayah 3 (Pos Rast), jalan di belakangnya tertutup oleh batang pohon tumbang.
   - Wilayah 1–4 terbuka untuk kebutuhan harian warung; Wilayah 5 & 6 terbuka kembali secara permanen setelah menyelesaikan Quest Rast Hati 2 (*Eksplorasi Hutan Dalam*).
5. **UI Banner Lokasi:** Menampilkan toast nama wilayah selama 2,5 detik saat pemain melangkah ke wilayah baru.

### 2.2 Non-Tujuan (Bisa Dilanjutkan di 0.4.0+)
- Pemecahan area Desa menjadi multi-zona (Desa tetap satu kesatuan zona yang terhubung ke Wilayah 1).
- Musuh, monster, atau sistem pertarungan di rimba.
- Sistem mini-game memancing lanjutan (penangkapan ikan tetap memakai sistem interaksi foraging yang ada).
- Jawaban akhir misteri asap (hanya petunjuk fisik lanjutan di Wilayah 6).

---

## 3. Struktur 6 Wilayah Hutan Rimba

### 3.1 Peta Topologi

```
                  [ Wilayah 6: Suaka Pohon Raksasa ]
                        (Paling Dalam / Utara)
                                  ▲
                                  │ (Tertutup Batang Pohon Tumbang pasca-Prolog;
                                  │  Terbuka via Quest Rast Hati 2)
      [ Wilayah 5: Lembah Akar ] ◄─┼─► [ Wilayah 3: Pos Penebang ] ◄───► [ Wilayah 4: Semak Belukar ]
         (Menhir & Akar Gantung)   │       (Gubuk Perkakas Rast)            (Fairy Ring & Buah Liar)
                  ▲                │                   ▲                               ▲
                  │                ▼                   │                               │
      [ Wilayah 2: Aliran Sungai ] ◄───────────────────┴───► [ Wilayah 1: Pintu Rimba ]
         (Jembatan Gelondongan)                                 (Lentera & Akses Desa) ──► KE DESA
```

### 3.2 Spesifikasi Wilayah

| Wilayah | Nama | Ikonik Landmark | Status Jejak Manusia | Akses Terhubung | Bahan Foraging Utama |
|---|---|---|---|---|---|
| **1** | **Pintu Rimba** | Tiang lentera minyak kuno & papan penunjuk arah kayu retak | **Ada (#1)** | Timur: ke Desa<br>Barat: Wilayah 2<br>Utara: Wilayah 3 & 4 | Sayur liar, daun hutan |
| **2** | **Aliran Sungai Bebatuan** | Jembatan gelondongan kayu alami melintasi riam air jernih | Tidak ada | Timur: Wilayah 1<br>Utara: Wilayah 5 | Ikan sungai, batu kali, tanaman air |
| **3** | **Pos Penebang Kayu** | Gubuk perkakas terbuka, tumpukan kayu gelondong, & tungku perapian | **Ada (#2)** (Pos kerja Rast) | Selatan: Wilayah 1<br>Barat: Wilayah 5<br>Timur: Wilayah 4<br>Utara: Rintangan ke Wilayah 6 | Kayu tebang, ranting kering, resin pohon |
| **4** | **Semak Belukar Lembab** | Lingkaran jamur purba (*Fairy Ring*) & rumpun semak berry lebat | Tidak ada | Barat: Wilayah 3<br>Selatan: Wilayah 1 | Buah liar, daun aromatik, jamur hutan (melimpah saat hujan) |
| **5** | **Lembah Akar Purba** | Batu menhir purba retak & belitan akar gantung raksasa | Tidak ada (Area rintangan) | Selatan: Wilayah 2<br>Timur: Wilayah 3<br>Utara: Wilayah 6 | Akar rempah kualitas tinggi, lumut herba |
| **6** | **Suaka Pohon Raksasa** | Pohon beringin raksasa (*Great Tree*) berongga & kanopi berkas cahaya | Tidak ada (Titik awal bangun MC) | Selatan: Jalur keluar ke Wilayah 3 & 5 | Bahan langka purba, clue serpihan kayu *Misteri Asap* |

---

## 4. Mekanik & Perubahan Sistem

### 4.1 Arsitektur Zone Container (`World.gd`)
- `World.gd` menaungi sub-zona dengan sistem aktivasi dinamis (`set_visible`, pause collision zona tidak aktif) pada koordinat global non-overlapping.
- Transisi dipicu oleh `ZoneGate2D` yang mengirim sinyal perpindahan ke `World.gd`.
- Animasi transisi menggunakan layar menggelap sesaat (*fade out/in*) dengan durasi ~0,2 detik tanpa jeda loading baca file.

### 4.2 Aliran Waktu & Energi
- Waktu permainan berjalan secara real-time alami (1 menit game = 1,5 detik nyata).
- Tidak ada lonjakan waktu buatan atau potongan energi instan saat melintasi gerbang antar-zona.

### 4.3 Jadwal & Keberadaan NPC di Rimba
- Seluruh 32 NPC ambient dilarang *spawn* di area hutan.
- Rast hadir di **Wilayah 3 (Pos Penebang Kayu)** pada pukul 06:00–16:00 untuk bekerja menebang kayu. Di luar jam kerja, Rast kembali ke pemukiman desa.
- Menjamin Rast langsung dapat ditemui saat pemain tiba dari prolog tanpa jeda waktu tunggu.

### 4.4 Integrasi Progresi & Save Game
- Status pembukaan hutan dalam disimpan dalam save file: `is_deep_forest_unlocked` (default: `false`).
- Pemain yang memuat save lama (v1.0 / 0.2.0) di mana Quest Rast Hati 2 sudah selesai akan otomatis memiliki status `is_deep_forest_unlocked = true`.

---

## 5. Rencana Fase Pengerjaan (Milestones 0.3.0)

1. **Fase 18 — Fondasi Zone Manager & Sistem Gerbang Transisi**
   - Buat komponen `ZoneGate2D` dan controller transisi layar di `World.gd`.
   - Implementasikan sistem fade out/in dan reposisi pemain.
2. **Fase 19 — Pemisahan Peta & Visual 6 Wilayah Hutan**
   - Konstruksi layout tilemap dan landmark ikonik untuk masing-masing dari 6 wilayah.
   - Implementasi event pohon tumbang pasca-prolog dan rintangan Wilayah 5 & 6.
3. **Fase 20 — Redistribusi Titik Foraging & Jadwal Rast**
   - Petakan titik spawn sayur liar, kayu, batu, ikan, jamur, dan buah ke zona yang sesuai.
   - Atur jadwal kerja Rast di Wilayah 3 (06:00–16:00) dan hilangkan NPC ambient dari hutan.
4. **Fase 21 — UI Toast Nama Lokasi & Integrasi Quest Rast**
   - Implementasikan banner notifikasi nama wilayah saat masuk.
   - Hubungkan selesainya Quest Rast Hati 2 untuk membuka rintangan pohon tumbang secara permanen.
5. **Fase 22 — Pengujian Otomatis, QA Mobile & Rilis 0.3.0**
   - Jalankan seluruh tes unit Godot, validasi save/load v0.2.0 -> v0.3.0, dan update build docs.
