# MILESTONE.md — Urutan Pengerjaan Hearthwood: Warung Rimba (v1.0)

Dokumen ini adalah **peta jalan kerja (work sequence)** untuk mengembangkan versi awal (MVP) agar tidak melompat-lompat antar fitur. Semua keputusan didasarkan pada **PRD**, **ARCHITECT.md**, **DESIGN.md**, dan **AGENTS.md**.

Jika ada konflik, urutan kebenaran adalah: **PRD > ARCHITECT.md > DESIGN.md > AGENTS.md > MILESTONE.md**.

---

## Prinsip Utama

1. **Fondasi dulu, konten kemudian.** Jangan buat data NPC/resep sebelum sistem yang membacanya selesai.
2. **Satu fase selesai baru ke fase berikutnya.** Tidak ada fitur yang dikerjakan secara paralel jika satu bergantung pada lainnya.
3. **Data-driven dari awal.** Dialog, NPC, resep, selera, dan simpan/muat disimpan sebagai JSON/Resource, bukan hardcode di skrip.
4. **Setiap fase harus lulus checklist "Definition of Done" sebelum melanjutkan.**
5. **Scope v1.0 = alur hutan → desa → izin tinggal → membangun warung.** Main quest Rast/Veral dan misteri asap ditunda.

---

## Ringkasan 11 Fase

| Fase | Fokus | Dependensi |
|------|-------|------------|
| 0 | Inti & Fondasi | — |
| 1 | Waktu & Dunia | Fase 0 |
| 2 | NPC & Dialog | Fase 1 |
| 3 | Toko Pedagang (Giral & Talia) | Fase 1, Fase 2 |
| 4 | Inventori & Item | Fase 1 |
| 5 | Memasak | Fase 1, Fase 4 |
| 6 | Afeksi (Kedekatan NPC) | Fase 2, Fase 5 |
| 7 | Progresi Warung (Tier) | Fase 5, Fase 6 |
| 8 | Simpan/Muat (Save/Load) | Fase 0–7 (semua state) |
| 9 | UI/UX & Aset | Fase 1–8 |
| 10 | Alur Game Utama (Hutan → Desa → Izin Tinggal) | Fase 1–9 |
| 11 | Polish, QA, Build & Rilis | Fase 0–10 |

---

## Fase 0 — Inti & Fondasi (Project Setup)

**Tujuan:** Siapkan project Godot, struktur folder, autoload GameState, dan konvensi penamaan agar semua sistem berikutnya punya tempat yang benar.

**Tugas:**
- [x] Buat project Godot 4.x, atur `project.godot` (rendering: Nearest, pixel snap aktif)
- [x] Buat struktur folder sesuai ARCHITECT.md (`scenes/`, `scripts/`, `data/npcs/`, `data/recipes/`, `data/items/`, `data/warung/`, `assets/`)
- [x] Daftarkan autoload `GameState.gd` di Project Settings
- [x] Implementasi variabel global dasar: `player_name`, `current_day`, `current_hour`, `energy`, `reputation`, `warung_tier`
- [x] Tentukan ukuran tile (16×16 atau 32×32) dan resolusi dasar
- [x] Konvensi penamaan: scene `PascalCase.tscn`, skrip `PascalCase.gd`, node `camelCase`, sinyal `snake_case`, data `snake_case.json`
- [x] Buat `.gitignore` untuk `.godot/`, `*.import`, build output

**Dependensi:** Tidak ada (fase pertama).

**Definition of Done:**
- [x] Project bisa dibuka dan dijalankan di Godot tanpa error
- [x] Autoload `GameState` bisa diakses dari semua skrip
- [x] Tidak ada nama file/skrip yang melanggar konvensi AGENTS.md bagian 2

---

## Fase 1 — Waktu & Dunia (TimeSystem, Player, Tileset)

**Tujuan:** Pemain dapat berjalan di dunia, waktu berjalan (06:00–22:00), hari berganti saat tidur, dan energi berkurang/pulih. Ini adalah jantung hampir semua sistem lain.

**Tugas:**
- [x] Buat `TimeSystem.gd` (signal `hour_changed`, `day_changed`, `sleep_started`)
- [x] Implementasi jam aktif 06:00–22:00, konversi 1 menit game = 1,5 detik nyata
- [x] Implementasi logika tidur dan bangun kesiangan (22:00–24:00 → 08:00/80%, 24:00–03:00 → 10:00/60%, 03:00+ → 12:00/40%, tidur paksa 06:00)
- [x] Buat `Player.gd` (CharacterBody2D, gerakan, energi, interaksi tile)
- [x] Buat `main_tileset.tscn` (satu tileset Eropa abad pertengahan, Nearest + pixel snap)
- [x] Buat scene dunia awal: hutan (awal) dan desa (tujuan alur v1.0)
- [x] Tampilkan UI jam dan hari (non-intrusif, pojok layar)
- [x] Tampilkan indikator energi

**Dependensi:** Fase 0 (GameState, konvensi).

**Definition of Done:**
- [x] Pemain dapat berjalan di hutan dan desa dengan joystick virtual / keyboard
- [x] Jam berjalan sendiri, hari berganti saat tidur (tidur paksa di 06:00)
- [x] Energi berkurang saat berjalan/mengolah dan pulih saat tidur
- [x] UI jam/hari/energi tampil dengan benar

---

## Fase 2 — NPC & Dialog (npc.tscn, Data JSON, Dialog UI)

**Tujuan:** NPC bernama bisa diinteraksi dengan dialog yang dimuat dari JSON (data-driven, tidak hardcode). 11 NPC bernama (9 pelanggan + Rast + Veral) dan 32 NPC ambient.

**Tugas:**
- [x] Buat `npc.tscn` (satu scene dipakai ulang, dialog lewat data JSON)
- [x] Buat `NPC.gd` (perilaku dasar: jalan acak di zona, tampilkan dialog)
- [x] Buat `dialog_ui.tscn` (kotak teks besar, nama NPC di kiri, tombol Lanjutkan/Next)
- [x] Buat file JSON untuk 11 NPC bernama di `data/npcs/` (skema: nama, peran, sifat, suka, tidak_suka, jam_buka, ciri_khas, dialog.dialog_1, dialog_2, hadiah.hati_1/2/3)
- [x] Isi 2 dialog per NPC (pertemuan awal + setelah progres)
- [x] Buat 32 variasi NPC ambient (sprite berlapis + variasi warna, tidak interaktif)
- [x] Masukkan NPC ke scene dunia sesuai lokasi dan jendela waktu

**Dependensi:** Fase 1 (Player, TimeSystem untuk jadwal, DialogUI untuk tampilan).

**Definition of Done:**
- [x] Pemain dapat berbicara ke semua 11 NPC bernama dan melihat 2 dialog masing-masing
- [x] Dialog diisi dari JSON, tidak ada hardcode dialog di skrip (lolos checklist AGENTS.md bagian 7)
- [x] NPC ambient berjalan-jalan di peta tanpa crash

---

## Fase 3 — Toko Pedagang (Giral & Talia)

**Tujuan:** Pedagang buka sesuai jam buka, menjual bahan/perkakas, dan memberikan diskon berdasarkan tingkat hati.

**Tugas:**
- [x] Buat `shop_npc.tscn` (warisan NPC + UI toko)
- [x] Buat `ShopNPC.gd` (cek jam buka dari data NPC, tampilkan UI toko jika buka)
- [x] Implementasi jadwal: Giral 07:00–12:00 (bahan), Talia 13:00–18:00 (perkakas)
- [x] Buat UI toko (daftar barang + harga, tombol Beli/Batal, diskon otomatis)
- [x] Diskon: hati 2 = 5%, hati 3 = 15% (hanya pedagang)
- [x] Siapkan state tingkat hati untuk diskon; nilai akan diisi oleh `AffectionSystem` pada Fase 6

**Dependensi:** Fase 1 (TimeSystem untuk jam buka), Fase 2 (NPC scene, dialog UI).

**Definition of Done:**
- [x] Giral hanya tampil dan bisa berbelanja pukul 07:00–12:00
- [x] Talia hanya tampil dan bisa berbelanja pukul 13:00–18:00
- [x] Di luar jam buka, toko tidak muncul (tidak ada crash)

---

## Fase 4 — Inventori & Item

**Tujuan:** Pemain dapat menahan item, bahan, dan hasil masakan. Diperlukan sebelum sistem memasak (bahan masuk, hasil keluar).

**Tugas:**
- [x] Buat entri item di `data/items/` (ID unik, nama tampilan, nilai energi jika bisa dimakan)
- [x] Implementasi sistem inventori (array item dengan jumlah)
- [x] Buat `inventory_ui.tscn` (grid item, ikon, jumlah, nilai energi untuk makanan)
- [x] Tampilkan tanggal masak pada hasil masakan (untuk hitung basi 3 hari)
- [x] Integrasi interaksi pemain untuk mengambil item, lalu menyimpannya ke inventori

**Dependensi:** Fase 1 (Player, energi), Fase 2 (NPC untuk interaksi ambil item).

**Definition of Done:**
- [x] Pemain dapat mengambil item di dunia dan melihatnya di inventori
- [x] Makanan menunjukkan nilai energi
- [x] Hasil masakan menunjukkan tanggal masak

---

## Fase 5 — Memasak (CookingSystem, Resep, Mini-game)

**Tujuan:** Pemain dapat memilih resep, porsi, alat, memasak, dan mendapatkan hasil dengan kualitas 1–3 bintang. Energi berkurang −5 per porsi.

**Tugas:**
- [x] Buat file JSON resep di `data/recipes/` (8 resep versi awal: Sup Sayur Bening, Ikan Bakar Rempah, Bubur Hangat Hutan, Sambal Tumisan Pedas, Sayur Asam Segar, Kue Manis Liar, Nasi Goreng Hutan, Hidangan Rempah Khusus)
- [x] Buat `CookingSystem.gd` (pilih resep → porsi → alat → cek alat minimum → hitung kualitas → kurangi energi → simpan hasil ke inventori dengan tanggal)
- [x] Implementasi pembagian porsi per alat: api unggun (2), tungku (3), dapur warteg (5)
- [x] Implementasi kualitas dasar 2 bintang, modifier timing, dan batas 1–3
- [x] Durasi tahan: 3 hari, basi hari ke-4 (otomatis dibuang)
- [x] Buat `cooking_ui.tscn` (resep, porsi, alat, bahan, mini-game timing opsional, tombol Masak)
- [x] Implementasi mini-game timing opsional (zona hijau/kuning/merah)

**Dependensi:** Fase 1 (TimeSystem untuk tanggal masak, energi), Fase 4 (Inventori untuk bahan dan hasil).

**Definition of Done:**
- [x] Pemain dapat memasak 8 resep dengan alat yang sesuai
- [x] Kualitas dihitung dengan benar (1–3 bintang)
- [x] Energi berkurang −5 per porsi
- [x] Hasil masakan masuk inventori dengan tanggal masak

---

## Fase 6 — Afeksi (Kedekatan NPC)

**Tujuan:** Pemain dapat memberi masakan ke NPC bernama, naik hati (0→1→2→3), dan menerima hadiah (info, diskon, resep).

**Tugas:**
- [x] Buat `AffectionSystem.gd` (poin dan hati per NPC)
- [x] Implementasi aturan: 1 pemberian per NPC per hari, reset setelah tidur
- [x] Poin reaksi: Netral +1, Suka +3, Favorit +5, Spesial +8, Tidak suka +0, Benci −3
- [x] Potongan kualitas: −20% poin positif per turun 1 tingkat, dibulatkan ke bawah
- [x] Hati: 0→1 (10 poin), 1→2 (30 poin), 2→3 (50 poin, total 90)
- [x] Hadiah kumulatif per hati dan per NPC sesuai tabel PRD bagian 9.1
- [x] Diskon pedagang otomatis (hati 2: 5%, hati 3: 15%)
- [x] Pemberian spesial +8 (saat cuaca dingin, Rast baru pulang dari hutan) — siapkan struktur

**Dependensi:** Fase 2 (NPC data JSON), Fase 5 (CookingSystem untuk hasil masakan yang diberikan).

**Definition of Done:**
- [x] Pemain dapat memberi masakan ke NPC bernama (maks 1 kali per NPC per hari)
- [x] Naik hati terbuka hadiah sesuai tabel PRD
- [x] Diskon pedagang berlaku otomatis di toko
- [x] Reset pemberian harian setelah tidur

---

## Fase 7 — Progresi Warung (Tier)

**Tujuan:** Warung berkembang dari gubuk → warung kecil → warteg penuh berdasarkan reputasi dan biaya upgrade.

**Tugas:**
- [x] Buat `WarungSystem.gd` (cek reputasi dan biaya, naikkan tier)
- [x] Implementasi tier: Gubuk (0, reputasi 0), Warung Kecil (1, reputasi 10, 500 koin + kayu), Warteg Penuh (2, reputasi 25, 1500 koin + kayu + batu)
- [x] Alat per tier: api unggun → tungku → dapur warteg
- [x] Maks porsi per tier: 2 → 3 → 5
- [x] Veral memberikan izin usaha saat naik ke Warung Kecil dan Warteg Penuh
- [x] Reputasi naik saat pelanggan puas dengan masakan sesuai selera
- [x] Setiap tier membuka pelanggan baru dan alat untuk resep tingkat lanjut (resep tetap harus terbuka lewat bahan)

**Catatan implementasi:** PRD tidak menentukan jumlah bahan upgrade, harga jual, atau kapasitas harian. Konfigurasi v1 memakai 1 kayu untuk tier 1, 1 kayu + 1 batu untuk tier 2, harga dasar masakan 40 koin pada kualitas 2 (diskalakan menurut kualitas), reputasi +1 per layanan yang disukai, serta kapasitas 2/4/7 pelanggan per hari. Data tier ada di `data/warung/tiers.json`; resep tetap mengikuti unlock berbasis bahan.

**Dependensi:** Fase 5 (CookingSystem untuk masakan yang disajikan), Fase 6 (AffectionSystem untuk reputasi/kedekatan), Fase 3 (Toko untuk bahan upgrade).

**Definition of Done:**
- [x] Pemain dapat naik tier warung dengan memenuhi ambang reputasi dan biaya
- [x] Alat dan maks porsi bertambah per tier
- [x] Veral memberikan izin usaha saat naik ke Warung Kecil dan Warteg Penuh

---

## Fase 8 — Simpan/Muat (Save/Load)

**Tujuan:** Pemain dapat menyimpan dan memuat game. Auto-save saat tidur, naik tier, selesai quest. Manual save tersedia dari menu jeda dan progres disimpan saat kembali ke main menu.

**Tugas:**
- [x] Buat `SaveSystem.gd` (baca/tulis JSON via `FileAccess`, file `user://savegame.json`)
- [x] Implementasi struktur data save sesuai PRD bagian 10.1 (nama_pemain, hari, jam, energi, reputasi, posisi, inventori, resep_terbuka, hati_npc, tier_warung, item_dihadikan)
- [x] Auto-save: tidur (hari berganti), naik tier warung, selesai quest
- [x] Manual save: menu pause; simpan progres sebelum kembali ke main menu
- [x] Continue dan load game tersedia dari main menu
- [x] `GameState` sebagai titik masuk load/save

**Catatan implementasi:** Main menu menjadi scene awal, menawarkan Continue, New Game, Load Game, Pengaturan, dan Keluar. New Game meminta konfirmasi jika slot tunggal berisi save. Save yang rusak atau berasal dari scene berbeda ditolak tanpa menerapkan sebagian state.

**Dependensi:** Fase 0–7 (semua state yang perlu disimpan harus sudah ada).

**Definition of Done:**
- [x] Game dapat disimpan dan dimuat ulang tanpa data hilang
- [x] Auto-save berfungsi saat tidur, naik tier, menyelesaikan quest, dan kembali ke main menu
- [x] Load ulang memulihkan hari, jam, energi, inventori, hati NPC, tier warung, posisi, dan state dunia

---

## Fase 9 — UI/UX & Aset (Sprite, Tiles, Audio, Android)

**Tujuan:** Semua antarmuka terlihat rapi dan nyaman disentuh pada layar Android, aset visual dan audio lengkap untuk v1.0.

**Tugas:**
- [x] Lengkapi UI `CookingUI.tscn`, `InventoryUI.tscn`, `DialogUI.tscn`, `MainMenu.tscn`, `PauseMenu.tscn`, `ShopUI.tscn`, dan `ShopNPC.tscn`
- [x] Tombol sentuh minimal 44×44 dp, joystick virtual kiri bawah, tombol interaksi kanan bawah
- [x] Buat sprite berlapis MC (rambut, wajah, baju, celana, sepatu) — tampilan tetap
- [x] Buat sprite NPC berlapis dengan variasi warna (11 NPC bernama + 32 ambient)
- [x] Buat ciri khas visual setiap NPC (keranjang, palu, kain, tongkat, tombak, dll.)
- [x] Buat tileset utama bergaya Eropa abad pertengahan dengan Nearest dan pixel snap
- [x] Buat audio: musik hutan, desa, malam; SFX memasak, interaksi, tidur, naik hati
- [x] Tampilkan jam dan hari di pojok layar (non-intrusif)

**Catatan implementasi:** Sprite karakter menggunakan layer PNG pixel-art yang dipakai ulang dan diwarnai dari palet NPC; tileset atlas 16×16 dan audio WAV dibuat lokal untuk game ini. Menu utama menyediakan pengaturan volume dan layar penuh. Uji perangkat Android fisik dan penyempurnaan aset final tetap masuk Fase 11.

**Dependensi:** Fase 1–8 (semua sistem UI yang dipanggil harus sudah ada).

**Definition of Done:**
- [x] Semua UI layak disentuh pada layar kecil (minimal 44×44 dp)
- [x] Aset visual dan audio tersedia untuk semua scene v1.0
- [x] Estetika cozy (palet warna hangat, tekstur piksel)

---

## Fase 10 — Alur Game Utama (Hutan → Desa → Izin Tinggal → Warung)

**Tujuan:** Menyatukan semua sistem menjadi alur utuh v1.0: pemain terbangun di hutan, bertemu Rast, ke Veral, mendapat izin tinggal, menetap, dan mulai membangun warung.

**Tugas:**
- [ ] Implementasi scene awal: pemain terbangun di bawah pohon besar di hutan
- [ ] Tutorial bertemu Rast (penebang kayu) yang menjelaskan bertahan hidup
- [ ] Tutorial menemui Veral (kepala desa) untuk izin tinggal
- [ ] Tutorial memasak pertama (momen izin tinggal = tutorial memasak)
- [ ] Pemain menetap di gubuk kosong di pinggir desa
- [ ] Implementasi alur membangun kembali warung (gubuk → kecil → penuh)
- [ ] Hubungkan semua sinyal (waktu, afeksi, memasak, warung) ke UI
- [ ] Uji alur dari awal sampai akhir (start → hutan → desa → izin → warung)

**Dependensi:** Fase 1–9 (semua sistem harus siap).

**Definition of Done:**
- Pemain dapat menyelesaikan alur v1.0 dari awal sampai akhir tanpa crash
- Semua sinyal terhubung dan UI terupdate otomatis
- Tidak ada hardcode dialog di skrip

---

## Fase 11 — Polish, QA, Build & Rilis

**Tujuan:** Memastikan game stabil, nyaman dimainkan di Android, dan siap dirilis di itch.io / Play Store.

**Tugas:**
- [ ] Uji coba pada perangkat Android rendah (performa, sentuh, ukuran tombol)
- [ ] Perbaiki bug yang ditemukan saat uji alur utama
- [ ] Pastikan save/load tidak crash dan tidak menyimpan data sensitif/bug
- [ ] Uji ulang checklist sebelum commit (AGENTS.md bagian 7)
- [ ] Build untuk Android (Play Store) dan itch.io (web/desktop)
- [ ] Dokumentasi build dan rilis
- [ ] Catat pertanyaan terbuka (jadwal rilis, misteri asap) untuk versi berikutnya

**Dependensi:** Fase 0–10.

**Definition of Done:**
- Game dapat di-build dan dijalankan di Android
- Tidak ada bug crash pada alur v1.0
- Siap dirilis

---

## Tabel Dependensi Antar Fase

```
Fase 0 (Fondasi)
    ↓
Fase 1 (Waktu & Dunia)
    ↓
Fase 2 (NPC & Dialog)     Fase 4 (Inventori & Item)
    ↓                         ↓
Fase 3 (Toko Pedagang)     Fase 5 (Memasak)
    ↓                         ↓
                      Fase 6 (Afeksi)
                            ↓
                      Fase 7 (Progresi Warung)
                            ↓
                      Fase 8 (Save/Load)
                            ↓
                      Fase 9 (UI/UX & Aset)
                            ↓
                      Fase 10 (Alur Game Utama)
                            ↓
                      Fase 11 (Polish, QA, Build & Rilis)
```

---

## Peringatan: Jangan Melompat-Lompat

| Kesalahan | Mengapa berbahaya | Fase yang benar |
|-----------|-------------------|-----------------|
| Buat resep/NPC sebelum `TimeSystem` | Tidak ada tanggal masak, jam buka, dan reset harian | Fase 1 sebelum Fase 2/5 |
| Buat `AffectionSystem` sebelum `CookingSystem` | Tidak ada masakan yang dapat diberikan ke NPC | Fase 5 sebelum Fase 6 |
| Buat `SaveSystem` sebelum semua sistem state | Save akan kurang lengkap / crash saat load | Fase 8 adalah fase terakhir sebelum UI |
| Buat UI sebelum sistem yang dipanggil | UI tidak punya data untuk ditampilkan | Fase 9 setelah Fase 1–8 |
| Hardcode dialog di skrip | Melanggar prinsip data-driven, sulit diubah | Selalu pakai JSON (AGENTS.md bagian 7) |

---

## Non-Goal v1.0 (Tidak Dikerjakan Sekarang)

- Main quest Rast dan Veral (detail quest ditunda)
- Misteri asap (ditunda)
- Makhluk gaib atau ras fantasi lain
- Konflik besar, perang, atau ancaman dunia
- Penjelasan dimensi / asal isekai kepada tokoh lain
- Fitur lanjutan setelah warteg penuh

---

## Checklist Sebelum Pindah Fase (Setiap Fase)

- [ ] Semua tugas di fase ini dicentang
- [ ] Tidak ada hardcode dialog/magic number jam buka di skrip
- [ ] Semua sinyal sudah dihubungkan di `_ready` atau editor
- [ ] Skrip tidak crash jika data JSON kosong atau hilang (fallback default)
- [ ] UI masih layak disentuh pada layar kecil
- [ ] Save/load diuji (jika fase terkait state)
- [ ] Commit mengikuti Conventional Commits (contoh: `feat: tambah sistem waktu dan jam buka toko`)

---

## Catatan Commit

Setiap fase selesai, commit dengan pesan Conventional Commits:

```
feat(fase X): <ringkasan fitur>
```

Contoh:
```
feat(fase 1): tambah sistem waktu, player, dan tileset dunia
fix(fase 5): perbaiki perhitungan kualitas memasak batas 1-3 bintang
docs: update milestone urutan pengerjaan
```

Jangan commit file `.godot/`, `*.import`, atau build output (sudah di `.gitignore`).

---