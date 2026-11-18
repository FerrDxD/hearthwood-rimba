# MILESTONE.md — Urutan Pengerjaan Hearthwood: Warung Rimba (v1.0 + 0.2.0)

Dokumen ini adalah **peta jalan kerja (work sequence)** untuk mengembangkan versi awal (MVP) agar tidak melompat-lompat antar fitur. Semua keputusan didasarkan pada **PRD**, **ARCHITECT.md**, **DESIGN.md**, dan **AGENTS.md**.

Jika ada konflik, urutan kebenaran adalah: **PRD > ARCHITECT.md > DESIGN.md > AGENTS.md > MILESTONE.md**.

---

## Prinsip Utama

1. **Fondasi dulu, konten kemudian.** Jangan buat data NPC/resep sebelum sistem yang membacanya selesai.
2. **Satu fase selesai baru ke fase berikutnya.** Tidak ada fitur yang dikerjakan secara paralel jika satu bergantung pada lainnya.
3. **Data-driven dari awal.** Dialog, NPC, resep, selera, dan simpan/muat disimpan sebagai JSON/Resource, bukan hardcode di skrip.
4. **Setiap fase harus lulus checklist "Definition of Done" sebelum melanjutkan.**
5. **Scope v1.0 = alur hutan → desa → izin tinggal → membangun warung.** Main quest Rast/Veral dan misteri asap ditunda.
6. **Scope 0.2.0 = ekspansi quest, konten, dan sistem.** Melanjutkan dari fondasi v1.0 dengan main quest Rast/Veral hati 0-3, konten baru, dan penyelesaian build target.

---

## Ringkasan 11 Fase v1.0 + 10 Fase 0.2.0

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

### 0.2.0 Expansion Phases (Baru setelah v1.0 selesai)

| Fase | Fokus | Dependensi |
|------|-------|------------|
| 12 | Main Quest Rast & Veral (hati 0-3) | Fase 6 (Afeksi), Fase 7 (Warung) |
| 13 | NPC Baru & Data JSON | Fase 2 (NPC scene) |
| 14 | Resep Masakan Baru & Sistem Cuaca | Fase 5 (CookingSystem) |
| 15 | Tier 4 Warung "Warung Besar" | Fase 7 (Progresi Warung) |
| 16 | Quest Tracker & Quest Log UI | Fase 9 (UI/UX) |
| 17 | Build Target & Release Completion (0.2.0) | Fase 11 (Polish) |

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
- [x] Implementasi scene awal: pemain terbangun di bawah pohon besar di hutan
- [x] Tutorial bertemu Rast (penebang kayu) yang menjelaskan bertahan hidup
- [x] Tutorial menemui Veral (kepala desa) untuk izin tinggal
- [x] Tutorial memasak pertama (momen izin tinggal = tutorial memasak)
- [x] Pemain menetap di gubuk kosong di pinggir desa
- [x] Implementasi alur membangun kembali warung (gubuk → kecil → penuh)
- [x] Hubungkan semua sinyal (waktu, afeksi, memasak, warung) ke UI
- [x] Uji alur dari awal sampai akhir (start → hutan → desa → izin → warung)

**Catatan implementasi:** Dialog dan objective prolog disimpan di `data/story/prologue.json`; progresnya memakai quest selesai yang sudah tercakup dalam save. Rast mengarahkan pemain mencari sayur liar, Veral menyediakan garam untuk ujian memasak, dan izin tinggal membuka langkah menetap di gubuk. Setelah menetap, layanan pelanggan dan permintaan izin upgrade warung tersedia. Visual bangunan warung berubah saat tier naik.

**Dependensi:** Fase 1–9 (semua sistem harus siap).

**Definition of Done:**
- [x] Pemain dapat menyelesaikan alur v1.0 dari awal sampai akhir tanpa crash
- [x] Semua sinyal terhubung dan UI terupdate otomatis
- [x] Tidak ada hardcode dialog di skrip

---

## Fase 11 — Polish, QA, Build & Rilis

**Tujuan:** Memastikan game stabil, nyaman dimainkan di Android, dan siap dirilis di itch.io / Play Store.

**Tugas:**
- [ ] Uji coba pada perangkat Android rendah (performa, sentuh, ukuran tombol) — belum ada perangkat Android terhubung
- [x] Uji otomatis alur utama; tidak ditemukan crash atau bug baru
- [x] Pastikan save/load tidak crash dan tidak menyimpan data sensitif/bug — uji round-trip dan validasi lulus
- [x] Uji ulang checklist sebelum commit (AGENTS.md bagian 7); catat item fallback JSON yang belum terpenuhi di `RELEASE.md`
- [ ] Build untuk Android (Play Store) dan itch.io (web/desktop) — tertahan template/SDK/signing yang belum tersedia
- [x] Dokumentasi build dan rilis di `RELEASE.md`
- [x] Catat pertanyaan terbuka (jadwal rilis, misteri asap) di `RELEASE.md`

**Dependensi:** Fase 0–10.

**Definition of Done:**
- [ ] Game dapat di-build dan dijalankan di Android
- [x] Tidak ada crash pada alur v1.0 yang tercakup tes otomatis
- [ ] Siap dirilis setelah ekspor dan uji perangkat fisik lulus
- [x] Semua state v1.0 tersimpan kompatibel (save/load, quest tracking, warung tier)
- [x] Fondasi siap untuk fase 0.2.0 (waktu, NPC, cooking, affection, warung, save/load)

**Status:** QA otomatis lulus, Fase 11 v1.0 selesai. Fondasi v1.0 lengkap dan siap untuk ekspansi 0.2.0.

---

## Fase 12 — Main Quest Rast & Veral (hati 0–3)

**Tujuan:** Main quest dua tokoh utama berjalan dari hati 0 sampai hati 3, dengan objective yang terlihat, penyerahan bahan, hadiah, dan clue misteri asap.

**Tugas:**
- [x] `data/story/quests.json`: 4 bab per NPC (hati 0–3) berisi objective, dialog aktif, kebutuhan item/koin, dialog selesai, hadiah, dan petunjuk asap
- [x] `QuestSystem.gd`: memuat data, gerbang hati, validasi kebutuhan, penyerahan hadiah, dan penandaan quest selesai lewat `GameState.complete_quest`
- [x] State baru `bab_quest`, `petunjuk_asap`, `fitur_terbuka` disimpan di save dan kompatibel dengan save v1.0
- [x] HUD menampilkan objective warung dan objective quest Rast/Veral yang sedang berjalan
- [x] Interaksi Rast/Veral memakai dialog bab aktif dan menyerahkan bahan saat syarat terpenuhi; tombol layani/izin warung tetap berfungsi
- [x] Hadiah bab: koin, reputasi, alat pertahanan, fitur baru, dan 3 clue misteri asap
- [x] `tests/QuestSystemTest.gd`: gerbang hati, kebutuhan, hadiah, clue, integrasi dialog, dan round-trip save

**Dependensi:** Fase 6, Fase 7, Fase 10.

**Definition of Done:**
- [x] Rast dan Veral masing-masing punya 4 bab yang hanya bisa diserahkan pada hati yang sesuai
- [x] Penyerahan memakai bahan/koin, memberi hadiah, dan tidak bisa diulang
- [x] Tiga clue misteri asap terkumpul dari bab yang ditentukan
- [x] Save/load mempertahankan progres bab, clue, dan fitur terbuka

---

## Fase 13 — NPC Baru & Data JSON

**Tujuan:** Empat NPC baru (Arin, Budi, Siti, Pak Udin) hidup di jadwalnya, punya dialog data-driven, dan bisa diberi masakan.

**Tugas:**
- [x] `data/npcs/arin.json`, `budi.json`, `siti.json`, `pak_udin.json` dengan skema NPC yang sama (2 dialog, selera, hadiah hati 1–3)
- [x] `palet.aksesori` baru didukung `CharacterVisual.gd` (tangkong, tas, jaring, pipa)
- [x] Jadwal keempat NPC di `data/schedules.json` sesuai PRD bagian 6.2
- [x] NPC baru masuk daftar NPC bernama dunia dan bisa menerima hadiah/afeksi
- [x] `tests/NPCSystemTest.gd` diperluas untuk memuat, menjadwalkan, dan memberi hadiah ke NPC baru

**Dependensi:** Fase 2, Fase 12.

**Definition of Done:**
- [x] Keempat NPC muncul sesuai jam dan lokasi masing-masing
- [x] Dialog dan selera dimuat dari JSON tanpa hardcode
- [x] Pemberian masakan ke NPC baru memakai aturan afeksi yang sama

---

## Fase 14 — Resep Masakan Baru & Sistem Cuaca

**Tujuan:** Enam resep baru terhubung ke bahan/quest, dan cuaca harian sederhana memengaruhi masakan serta respons NPC.

**Tugas:**
- [x] Item dan 6 resep baru di `data/recipes/` sesuai PRD bagian 5.2 (Sup Kaldu Kayu, Nasi Kuning Rempah, Kue Coklat, Ikan Goreng Tegal, Sayur Tumis Pedas, Bubur Ayam Hutan)
- [x] Pembuka resep: quest Rast/Veral dan pembelian Giral; tidak ada resep yang mustahil terbuka
- [x] Cuaca harian Cerah/Hujan/Badai di `GameState` (berubah saat tidur, deterministik dari hari)
- [x] Pengaruh cuaca: pertumbuhan ulang bahan, zona mini-game, respons NPC, dan jam buka toko
- [x] Ikon cuaca di HUD dan data ramalan tidak termasuk (non-goal)
- [x] `tests/WeatherSystemTest.gd` dan perluasan `CookingSystemTest.gd`

**Dependensi:** Fase 5, Fase 12.

**Definition of Done:**
- [x] Enam resep bisa dibuka, dimasak, dan disukai NPC yang ditentukan
- [x] Cuaca berubah tiap hari dan hanya memberi efek yang tercantum di PRD
- [x] Save/load menyimpan cuaca hari itu

---

## Fase 15 — Tier 4 Warung "Warung Besar"

**Tujuan:** Warung bisa naik ke tier 4 dengan alat baru, kapasitas 8 porsi, pelanggan quest, dan fitur gudang.

**Tugas:**
- [ ] `data/warung/tiers.json` tier 4: reputasi 40, 3000 koin + 2 kayu + 1 batu, alat `dapur_besar`, maks porsi 8, kapasitas 8
- [ ] `GameState.MAX_WARUNG_TIER` menjadi 3 dan validasi save mengikuti
- [ ] Pelanggan tier 4 memakai NPC quest (Rast/Veral/Arin) dan mendukung dialog izin Veral
- [ ] Visual bangunan tier 4 dan alat `dapur_besar` di UI memasak
- [ ] Save v1.0/v0.2.0 dengan tier 0–2 tetap valid
- [ ] `tests/WarungSystemTest.gd` diperluas untuk tier 4

**Dependensi:** Fase 7, Fase 12, Fase 14.

**Definition of Done:**
- [ ] Upgrade ke tier 4 memakai biaya dan syarat baru
- [ ] Masak 8 porsi dan layani pelanggan tier 4 bekerja
- [ ] Tidak ada save lama yang ditolak karena tier

---

## Fase 16 — Quest Tracker & Quest Log UI

**Tujuan:** Pemain dapat membuka quest log untuk melihat progres hati, objective, hadiah berikutnya, dan clue misteri asap.

**Tugas:**
- [ ] `QuestUI.gd` + `QuestUI.tscn`: daftar quest Rast/Veral, hati, status bab, objective, hadiah berikutnya
- [ ] Daftar clue misteri asap yang sudah terkumpul
- [ ] Tombol `Quest` di HUD dan tombol `J` untuk membuka/menutup
- [ ] UI menjadi modal: menahan input dunia selama terbuka
- [ ] Tombol memenuhi minimum 44×44 dan tes `UITouchTargetTest.gd` diperluas

**Dependensi:** Fase 12, Fase 16 memakai `QuestSystem`.

**Definition of Done:**
- [ ] Quest log menampilkan semua progres quest tanpa crash saat data kosong
- [ ] Clue hanya tampil jika sudah terkumpul
- [ ] Membuka quest log menahan input dan tombolnya layak disentuh

---

## Fase 17 — Build Target & Release Completion (0.2.0)

**Tujuan:** Menghasilkan build Windows, Web, dan Android non-debug untuk rilis 0.2.0.

**Tugas:**
- [ ] Perbarui versi project menjadi 0.2.0
- [ ] Ekspor Windows Desktop, Web, dan Android AAB bertanda tangan non-debug
- [ ] Uji build Web dan desktop pada mesin bersih; uji save/load rilis
- [ ] Uji perangkat Android kelas rendah jika perangkat tersedia
- [ ] Perbarui `RELEASE.md` dengan hasil build, keterbatasan, dan checklist rilis

**Dependensi:** Fase 12–16, prasyarat ekspor di `RELEASE.md`.

**Definition of Done:**
- [ ] Ketiga target build dihasilkan atau blocker dicatat eksplisit di `RELEASE.md`
- [ ] Build yang dihasilkan bisa dimainkan dan memuat save
- [ ] Versi project dan dokumentasi rilis sesuai 0.2.0

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
                      Fase 11 (Polish, QA, Build & Rilis v1.0)
                            ↓
                      Fase 12 (Main Quest Rast & Veral 0.2.0)
                            ↓
                      Fase 13 (NPC Baru & Data 0.2.0)
                            ↓
                      Fase 14 (Resep & Cuaca 0.2.0)
                            ↓
                      Fase 15 (Tier 4 Warung 0.2.0)
                            ↓
                      Fase 16 (Quest Tracker 0.2.0)
                            ↓
                      Fase 17 (Build & Release 0.2.0)
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

- Makhluk gaib atau ras fantasi lain
- Konflik besar, perang, atau ancaman dunia
- Penjelasan dimensi / asal isekai secara eksplikasi
- Fitur lanjutan setelah warteg penuh (telah ditambahkan tier 4 di 0.2.0)

---

## Non-Goal 0.2.0 (Bisa Dilanjutkan di 0.3.0)

- Penjelasan final soal dimensi/isekai tokoh utama
- Sistem ekonomi komplit di luar warung
- Main quest Rast/Veral hati 4 (lanjut ke versi berikutnya)
- Sistem cuaca yang kompleks (multi-faktor, prediksi)
- Fitur multiplayer atau komunitas
- Penjelasan lengkap misteri asap (jawaban definitive)
- Sistem day/night cycle yang mempengaruhi seluruh sistem secara realistis (bukan hanya konteks)

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