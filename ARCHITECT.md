# ARCHITECT.md — Hearthwood: Warung Rimba

Dokumen arsitektur teknis untuk pengembangan game dengan Godot 4.x. Semua keputusan diambil dari PRD (`PRD Hearthwood Warung Rimba (Versi Awal).md`).

---

## 1. Ringkasan Teknis

| Item | Keputusan |
|------|-----------|
| Engine | Godot 4.x |
| Genre | Cozy, 2D piksel, kamera top-down |
| Platform target | itch.io (web/desktop), Play Store (Android) |
| Tile ukuran | 16x16 atau 32x32 (ditetapkan saat mulai implementasi) |
| Texture filter | Nearest, pixel snap aktif |
| Data penyimpanan | `Resource` atau JSON via `FileAccess` |
| Autoload | `GameState` (nama pemain, state global) |
| Save file | `user://savegame.json` |
| Kontrol | Joystick virtual + tombol interaksi besar (sentuh Android) |

---

## 2. Struktur Scene (Scene Tree)

```
res://
├── scenes/
│   ├── main.tscn              # Scene utama (world)
│   ├── player.tscn            # CharacterBody2D + Sprite2D berlapis
│   ├── npc.tscn               # Satu scene NPC dipakai ulang (dialog lewat data)
│   ├── shop_npc.tscn          # NPC pedagang (Giral, Talia) dengan UI toko
│   ├── warung.tscn            # Bangunan warung pemain (tier: gubuk, kecil, penuh)
│   ├── cooking_ui.tscn        # UI memasak (resep, porsi, alat, mini-game)
│   ├── inventory_ui.tscn      # UI inventori
│   ├── dialog_ui.tscn         # UI dialog NPC (2 dialog per NPC bernama)
│   ├── save_load_ui.tscn      # UI simpan/muat (main menu + pause)
│   └── tilemap/
│          └── main_tileset.tscn # Tileset utama Eropa abad pertengahan
├── scripts/
│   ├── autoload/
│   │   └── GameState.gd       # Autoload: nama pemain, state global
│   ├── player/
│   │   └── Player.gd          # Gerakan, energi, interaksi tile
│   ├── npc/
│   │   ├── NPC.gd             # Dasar perilaku NPC (jalan acak, dialog)
│   │   └── ShopNPC.gd         # Perilaku pedagang (jam buka, toko)
│   ├── systems/
│   │   ├── TimeSystem.gd      # Jam bergerak, hari berganti saat tidur
│   │   ├── CookingSystem.gd   # Resep, porsi, kualitas, energi
│   │   ├── AffectionSystem.gd # Hati NPC, hadiah per tingkat
│   │   ├── WarungSystem.gd    # Progresi tier warung (gubuk → kecil → penuh)
│   │   └── SaveSystem.gd      # Simpan/muat JSON via FileAccess
│   └── ui/
│       ├── CookingUI.gd
│       ├── InventoryUI.gd
│       ├── DialogUI.gd
│       └── SaveLoadUI.gd
├── data/
│   ├── npcs/
│   │   ├── giral.json         # Data NPC: sifat, selera, jam buka, dialog
│   │   ├── talia.json
│   │   └── ...                # 9 NPC bernama + 32 ambient
│   ├── recipes/
│   │   ├── sup_sayur_bening.json
│   │   └── ...                # 8 resep versi awal
│   ├── items/
│   │   └── ...                # Data item, bahan, perkakas
│   └── warung/
│          └── tiers.json      # Data tier progresi warung
├── assets/
│   ├── sprites/
│   │   ├── player/            # Sprite berlapis: rambut, baju, celana
│   │   ├── npc/               # Sprite manusia berlapis dengan variasi warna
│   │   └── tiles/             # Tileset utama
│   └── audio/
│          ├── music/         # Musik cozy, adem ayem
│          └── sfx/           # Sound memasak, interaksi, langkah
└── project.godot
```

---

## 3. Autoload & State Management

### GameState.gd (Autoload)

Tanggung jawab:
- Menyimpan nama pemain (dapat dikustom, placeholder `{nama}`)
- State global yang diakses semua scene
- Titik masuk pemuatan dan penyimpanan save file
- Referensi ke sistem waktu, energi, reputasi

Contoh variabel global:
```gdscript
var player_name: String = "[nama player]"
var current_day: int = 1
var current_hour: int = 6
var energy: int = 100
var reputation: int = 0
var warung_tier: int = 0  # 0=Gubuk, 1=Warung Kecil, 2=Warteg Penuh
```

---

## 4. Sistem Waktu

Dari PRD:
- Jam aktif: 06.00–22.00
- 1 menit game = 1,5 detik nyata → 16 jam aktif ≈ 24 menit nyata
- Bangun default: 06.00
- Tidur setelah 22.00 = bergadang, energi awal berkurang (80%/60%/40%)
- Tidur paksa di 06.00 hari berikutnya
- Hari berganti saat tidur, bukan tengah malam

Implementasi:
- `TimeSystem.gd` mengelola jam dan hari
- Signal `hour_changed`, `day_changed`, `sleep_started`
- NPC schedules diamankan oleh waktu (Giral 07:00–12:00, Talia 13:00–18:00, dll.)

---

## 5. Sistem Memasak

Dari PRD (bagian 9 + 9.3):
- Pemain memilih resep, jumlah porsi, alat
- Maksimal porsi: api unggun (2), tungku (3), dapur warteg (5)
- Durasi tahan: 3 hari, basi hari ke-4
- Kualitas: 1–3 bintang (dasar 2, faktor +1/−1)
- Faktor kualitas: bahan segar, pengganti cocok, alat sesuai, timing baik
- Mini-game timing opsional: bar horizontal, zona hijau/kuning/merah

Implementasi:
- `CookingSystem.gd` mengelola logika memasak
- Data resep disimpan di `data/recipes/*.json`
- UI: `cooking_ui.tscn` menampilkan resep, pilihan porsi, alat, mini-game

---

## 6. Sistem Afeksi (Kedekatan NPC)

Dari PRD (bagian 9.1):
- 3 hati per NPC: ambang 10, 30, 50 poin (total 90)
- Reaksi: Netral +1, Suka +3, Favorit +5, Spesial +8, Tidak suka +0, Benci −3
- Pemberian spesial +8 saat situasi tepat (cuaca dingin, Rast baru pulang)
- Potongan kualitas: −20% poin per turun 1 tingkat, dibulatkan ke bawah
- Hadiah kumulatif per hati dan per peran NPC (sudah ditentukan konkret di PRD)

Implementasi:
- `AffectionSystem.gd` mengelola poin dan hati
- Data selera NPC di `data/npcs/*.json`
- Hadiah diterapkan saat naik hati (diskon, resep, info, buka quest)

---

## 7. Sistem NPC

Dari PRD (bagian 7 + 7.1):
- 9 NPC bernama + Rast dan Veral (karakter utama)
- Masing-masing NPC bernama: 2 dialog (pertemuan awal + setelah progres)
- 32 variasi NPC ambient (hanya jalan-jalan, tidak bisa diinteraksi)
- Satu scene NPC dipakai ulang, dialog diisi lewat data JSON

Implementasi:
- `NPC.gd`: perilaku dasar (jalan acak di zona, tampilkan dialog)
- `ShopNPC.gd`: warisan NPC, tambahkan jam buka dan UI toko
- Dialog dimuat dari `data/npcs/*.json` (dialog_1, dialog_2, ciri_khas)

---

## 8. Sistem Toko Pedagang

Dari PRD (bagian 7, 9.2):
- Giral: Pedagang bahan, buka 07.00–12.00
- Talia: Pedagang perkakas, buka 13.00–18.00
- Diskon hanya berlaku untuk pedagang (hati 2: 5%, hati 3: 15%)

Implementasi:
- `ShopNPC.gd` mewarisi perilaku `NPC.gd`, membaca `jam_buka` dari JSON NPC, dan menolak interaksi di luar jam tersebut.
- `ShopUI.gd` memuat katalog data-driven dari `data/shops.json`; pembelian memeriksa saldo lalu memperbarui koin dan jumlah item di `GameState`.
- Diskon pedagang membaca tingkat hati Giral/Talia dari `GameState`; `AffectionSystem` akan mengisi state tersebut pada Fase 6.

---

## 9. Progresi Warung

Dari PRD (bagian 9.4):
- Tier: Gubuk (0) → Warung Kecil (1) → Warteg Penuh (2)
- Ambang reputasi: 0, 10, 25
- Biaya: —, 500 koin + kayu, 1500 koin + kayu + batu
- Alat: api unggun → tungku → dapur warteg
- Maks porsi: 2 → 3 → 5
- Veral memberikan izin usaha saat naik tier

Implementasi:
- `WarungSystem.gd`: cek reputasi dan biaya, naikkan tier
- Verifikasi izin usaha dari Veral (hati 3 atau event khusus)

---

## 10. Sistem Simpan/Muat

Dari PRD (bagian 10.1):
- Pendekatan A: satu save slot
- Auto-save: tidur, naik tier warung, selesai quest
- Manual save: menu pause + main menu
- File: `user://savegame.json` via `FileAccess`
- Autoload `GameState` menangani load/save

Struktur JSON (lihat PRD bagian 10.1 untuk detail field).

---

## 11. Kontrol & UI (Android-first)

- Joystick virtual (gerakan)
- Tombol interaksi besar (interaksi NPC, tile, toko)
- UI skala dirancang sejak awal untuk layar sentuh
- Texture filter Nearest + pixel snap untuk estetika piksel

---

## 12. Performa (Android)

- NPC di luar layar dimatikan (`set_process(false)` / `set_physics_process(false)`)
- Tidak semua NPC muncul di satu area sekaligus
- NPC ambient: perilaku sederhana (jalan acak di zona atau antar titik jalur)
- Satu tileset utama divariasikan lewar warna (hemat memori)

---

## 13. Contoh Implementasi Data NPC (JSON)

```json
{
  "nama": "Giral",
  "peran": "Pedagang bahan",
  "sifat": "Rajin, pemalu, senang jalan hutan",
  "suka": ["Sayur bening", "Hidangan ringan"],
  "tidak_suka": ["Terlalu manis"],
  "jam_buka": { "mulai": 7, "selesai": 12 },
  "ciri_khas": "Membawa keranjang bambu sayuran, bicara perlahan",
  "dialog": {
    "dialog_1": "Halo... selamat pagi. Saya Giral. Jualan sayuran dan bumbu dari hutan di sini. Ada yang... mau dibeli?",
    "dialog_2": "Oh, kamu sudah punya tempat makan? Kalau butuh bahan segar, tinggal bilang saja. Saya selalu siap..."
  },
  "hadiah": {
    "hati_1": { "tipe": "info", "isi": "Sayur liar tumbuh banyak di area timur hutan, terutama setelah hujan." },
    "hati_2": { "tipe": "diskon", "nilai": 5, "kategori": "bahan" },
    "hati_3": { "tipe": "diskon_resep", "nilai": 15, "resep": "Ikan Bakar Rempah" }
  }
}
```

---

## 14. Konvensi Penamaan (Godot)

- Scene: `PascalCase.tscn` (contoh: `Player.tscn`, `NPC.tscn`)
- Skrip: `PascalCase.gd`
- Simpul (node): `camelCase` (contoh: `sprite2d`, `collision_shape`)
- Sinyal: `snake_case` (contoh: `hour_changed`, `affection_changed`)
- Variabel: `snake_case` (contoh: `current_hour`, `player_energy`)
- Konstanta: `UPPER_SNAKE_CASE` (contoh: `MAX_ENERGY = 100`)
- Data JSON: `snake_case.json` (contoh: `giral.json`, `sup_sayur_bening.json`)

---

*Catatan: Dokumentasi ini adalah panduan arsitektur. Detail implementasi spesifik tiap skrip dapat ditambahkan saat coding dimulai.*