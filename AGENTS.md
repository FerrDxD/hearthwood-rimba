# AGENTS.md — Panduan Agent & Pengembang

Dokumen ini adalah panduan untuk siapa saja (termasuk AI agent) yang bekerja pada kodebase **Hearthwood: Warung Rimba**. Semua keputusan diambil dari PRD dan ARCHITECT.md.

---

## 1. Filosofi Pengembangan

- **Cozy first**: permainan harus terasa hangat, adem ayem, tidak ada tekanan berlebihan.
- **Versi awal (v1.0) adalah MVP**: fokus pada alur hutan → desa → warung. Fitur lanjutan (quest utama, misteri asap) ditunda.
- **Data-driven**: dialog, NPC, resep, dan selera disimpan sebagai JSON/Resource, bukan hardcode di skrip.
- **Android-first**: kontrol sentuh, UI besar, performa di perangkat rendah.

---

## 2. Convensi Kode (GDScript / Godot 4.x)

### Penamaan
| Elemen | Gaya | Contoh |
|--------|------|--------|
| Scene | `PascalCase.tscn` | `Player.tscn`, `ShopNPC.tscn` |
| Skrip | `PascalCase.gd` | `TimeSystem.gd`, `AffectionSystem.gd` |
| Simpul | `camelCase` | `sprite2d`, `collision_shape2d` |
| Sinyal | `snake_case` | `hour_changed`, `affection_changed` |
| Variabel | `snake_case` | `current_hour`, `player_energy` |
| Konstanta | `UPPER_SNAKE_CASE` | `MAX_ENERGY = 100`, `DAY_START_HOUR = 6` |
| File data | `snake_case.json` | `giral.json`, `sup_sayur_bening.json` |

### Struktur Skrip
```gdscript
extends Node2D

# Konstanta
const MAX_ENERGY: int = 100

# Sinyal
signal energy_changed(new_value: int)

# Variabel ekspor (bisa diedit di inspector)
@export var walk_speed: float = 150.0

# Referensi node (onnready)
@onready var sprite2d: Sprite2D = $Sprite2D

# Autoload
@onready var game_state: GameState = get_node("/root/GameState")

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass
```

### Sinyal & Autoload
- Gunakan autoload `GameState` untuk state global, jangan gunakan singleton lain kecuali diizinkan.
- Sistem waktu, afeksi, dan memasak harus memakai sinyal agar UI terupdate otomatis.
- Contoh: `time_system.hour_changed.connect(_on_hour_changed)`

---

## 3. Cara Menambahkan Elemen Baru

### Menambahkan NPC Baru
1. Buat file `data/npcs/<nama>.json` dengan skema:
   - `nama`, `peran`, `sifat`, `suka`, `tidak_suka`, `jam_buka` (opsional), `ciri_khas`, `dialog.dialog_1`, `dialog.dialog_2`, `hadiah.hati_1/2/3`
2. Buat instance dari scene `npc.tscn` (atau `shop_npc.tscn` jika pedagang)
3. Masukkan path JSON ke properti NPC di inspector
4. Jadwalkan NPC di `data/schedules.json` atau dalam `TimeSystem.gd` (jika belum ada file jadwal terpisah)
5. Jika NPC adalah pedagang, tambahkan ke tabel jam buka di bagian 9.2 PRD

### Menambahkan Resep Baru
1. Buat file `data/recipes/<nama_resep>.json`:
   - `nama`, `alat_minimum`, `bahan_utama`, `suka_npc`, `unlock_lewat`, `kualitas_dasar`
2. Daftarkan resep di `CookingSystem.gd` atau biarkan sistem memuat otomatis dari folder `data/recipes/`
3. Update PRD bagian 9.3 jika resep baru signifikan untuk gameplay

### Menambahkan Item Baru
1. Buat entri di `data/items/`
2. Pastikan item memiliki ID unik dan nama tampilan
3. Jika item bisa dimakan, tentukan nilai energi (lihat tabel energi di PRD bagian 9)

### Mengubah Jam Buka Toko
1. Edit `data/npcs/giral.json` dan `data/npcs/talia.json` (field `jam_buka`)
2. Update PRD bagian 9.2 Jadwal Harian
3. Update `ShopNPC.gd` jika logika jam buka berubah

---

## 4. Panduan Implementasi Sistem Utama

### Waktu (`TimeSystem.gd`)
- Jam berjalan dari 06.00 sampai 22.00 (16 jam)
- Konversi: 1 menit game = 1,5 detik nyata
- Panggil `game_state.sleep()` saat pemain tidur:
  - Jika tidur 22.00–24.00 → bangun 08.00, energi 80%
  - Jika tidur 24.00–03.00 → bangun 10.00, energi 60%
  - Jika tidur 03.00+ → bangun 12.00, energi 40%
- Tidur paksa di 06.00
- Hari berganti setelah tidur, bukan tengah malam

### Memasak (`CookingSystem.gd`)
- Pemain pilih resep → jumlah porsi → alat
- Cek alat memenuhi minimum resep
- Hitung kualitas: dasar 2 bintang + faktor terpenuhi − gagal (batas 1–3)
- Kurangi energi: −5 per porsi
- Simpan hasil masakan ke inventori dengan tanggal masak (untuk hitung basi)
- Mini-game timing opsional: zona hijau = bagus, kuning = sedang, merah = gagal

### Afeksi (`AffectionSystem.gd`)
- Pemberian maksimal 1 kali per NPC per hari
- Reset setelah tidur (hari berganti)
- Poin: Netral +1, Suka +3, Favorit +5, Spesial +8, Tidak suka +0, Benci −3
- Potongan kualitas: −20% poin positif per turun 1 tingkat, dibulatkan ke bawah
- Benci: 3 pemberian berturut-turut masakan tidak disukai
- Hati: 0→1 (10 poin), 1→2 (30 poin), 2→3 (50 poin)
- Saat naik hati, berikan hadiah sesuai tabel di PRD bagian 9.1

### Save/Load (`SaveSystem.gd`)
- File: `user://savegame.json`
- Auto-save: tidur, naik tier warung, selesai quest
- Manual: menu pause + main menu
- Gunakan `FileAccess` untuk baca/tulis JSON
- `GameState` sebagai titik masuk load/save

---

## 5. Panduan UI (Android)

- Tombol interaksi minimal 44×44 dp (rekomendasi sentuh)
- Joystick virtual di kiri bawah, tombol interaksi di kanan bawah
- Hindari teks kecil; gunakan font yang readable pada layar kecil
- UI memasak: tampilkan resep, porsi, alat, dan preview hasil
- UI dialog: kotak teks besar, opsi lanjutkan (next)
- UI toko: tampilkan hanya jika pedagang buka (cek jam buka)

---

## 6. Panduan Aset (Sprite & Tiles)

### Sprite Manusia Berlapis
- Lapisan: rambut, baju, celana (dan sepatu opsional)
- Variasi warna untuk 32 NPC ambient (tidak perlu sprite terpisah per orang)
- Ukuran tetap: tentukan sejak awal (16×16 atau 32×32 per tile)

### Tileset
- Satu tileset utama bergaya Eropa abad pertengahan
- Divariasikan lewar warna (jangan buat tileset baru untuk setiap area)
- Texture filter: Nearest
- Pixel snap: aktif

---

## 7. Checklist Sebelum Commit

- [ ] Tidak ada hardcode dialog di skrip (semua di JSON)
- [ ] Tidak ada magic number untuk jam buka (diambil dari data NPC)
- [ ] Semua sinyal sudah dihubungkan di `_ready` atau editor
- [ ] Skrip tidak crash jika data JSON kosong atau hilang (fallback default)
- [ ] UI masih layak disentuh pada layar kecil
- [ ] Save/load tidak menimpan data sensitif atau bug (coba load ulang)

---

## 8. Panduan Commit

Pesan commit mengikuti Conventional Commits (ringan):

```
feat: tambah sistem waktu dan jam buka toko
fix: perbaiki potongan energi saat bergadang
docs: update PRD bagian Giral dan Talia
refactor: gabungkan NPC.gd dan ShopNPC.gd
```

Jangan commit file `.godot/`, `*.import`, atau build output (sudah di `.gitignore`).

---

## 9. Referensi Cepat ke PRD

| Topik | Lokasi di PRD |
|-------|---------------|
| Giral & Talia | Bagian 7 (tabel NPC) |
| Jam buka toko | Bagian 9.2 |
| Hadiah per hati | Bagian 9.1 (tabel konkret) |
| Resep & bahan | Bagian 9.3 |
| Dialog NPC | Bagian 7.1 |
| Progresi warung | Bagian 9.4 |
| Quest Rast & Veral | Bagian 9.1 NPC utama |
| Save/load | Bagian 10.1 |
| Detail memasak & energi | Bagian 9 |

---

*Catatan: Dokumen ini bersifat panduan kerja. Jika ada konflik antara AGENTS.md dan PRD, PRD adalah sumber kebenaran utama.*