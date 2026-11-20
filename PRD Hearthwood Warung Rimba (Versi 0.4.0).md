# PRD: Hearthwood: Warung Rimba (Versi 0.4.0)

**Status:** Draf Lengkap untuk Persetujuan
**Tanggal:** 2026-11-20
**Berdasarkan:** PRD v0.1.0, v0.2.0, v0.3.0, DESIGN.md, ARCHITECT.md, AGENTS.md
**Dependen:** Seluruh sistem v1.0, v0.2.0, dan v0.3.0 (Fase 0–20)

---

## 1. Ringkasan Eksekutif

Update **0.4.0** adalah **Versi Desain Antarmuka Penuh**. Seluruh versi ini berfokus eksklusif pada perancangan UI/UX menggunakan **FigCraft MCP** — tanpa implementasi kode Godot. Hasilnya adalah satu file FigCraft yang berisi:

1. **Component Library**: Atom dan molekul UI bergaya *cozy medieval* yang siap diekspor dan diimplementasi di Godot pada v0.5.0.
2. **Full Screen Mockups**: Desain layar lengkap untuk seluruh menu utama game, dalam resolusi viewport Godot 960×540 (landscape Android).

Filosofi desain: *setiap layar terasa khas tempat, bukan formulir generik yang daur ulang.* Namun karena dunia warung terus berkembang tiap tier, komponen modal yang tidak terikat pada aset dunia (seperti Layar Memasak) dirancang *tier-agnostik* sejak awal.

---

## 2. Tujuan dan Non-Tujuan

### 2.1 Tujuan Utama

1. **Component Library di FigCraft** — seluruh komponen atom/molekul UI didokumentasikan secara sistematis dengan nama layer yang jelas dan siap diekspor.
2. **Full Screen Mockup** untuk 7 konteks layar utama:
   - HUD Gameplay (Dunia)
   - Buku Catatan (jurnal 4 tab, dual-page)
   - Layar Memasak (modal melayang)
   - Layar Toko (Giral & Talia, baris instan)
   - Layar Dialog & Beri Masakan (kotak dialog + drawer geser)
   - Layar Main Menu
   - Layar Pause Menu
3. **Panduan Spesifikasi Export** — ukuran aset, format yang dibutuhkan Godot (SVG/PNG/9-slice), dan nama file mengikuti konvensi AGENTS.md.

### 2.2 Non-Tujuan (Dilanjutkan di v0.5.0+)

- Implementasi kode GDScript di Godot (dilanjutkan v0.5.0).
- Sprite karakter atau portrait NPC (tidak ada di v0.4.0, bukan karena lupitan tapi keputusan desain yang sudah dipertimbangkan).
- Animasi dan transisi layar (konseptual saja di v0.4.0, implementasi di v0.5.0).
- Desain peta/tileset dunia (domain terpisah dari UI).

---

## 3. Spesifikasi Desain Visual

### 3.1 Kanvas & Resolusi

| Parameter | Nilai |
|-----------|-------|
| Resolusi frame FigCraft | 960 × 540 px (landscape) |
| Skala referensi | 1 px FigCraft = 1 px Godot viewport |
| Area sentuh minimum | 44 × 44 px (ramah jempol Android) |
| Font rendering | Pixel-readable, anti-alias off untuk elemen UI piksel |

### 3.2 Palet Warna (Dari DESIGN.md, Dikonfirmasi)

| Token | HEX | Penggunaan |
|-------|-----|------------|
| `ui-bg-parchment` | `#F5F5DC` | Latar pergamen Buku Catatan, kartu resep |
| `ui-bg-parchment-warm` | `#F5F0D9` | Latar panel lebih hangat (Toko, Main Menu) |
| `ui-accent-gold` | `#CD853F` | Tombol utama, highlight, aksen |
| `ui-accent-green` | `#8FBC8F` | Aksen warung, tombol sekunder |
| `ui-text-dark` | `#333333` | Teks utama |
| `ui-border-wood` | `#8B4513` | Bingkai kayu, tepi panel |
| `ui-overlay-dim` | `#000000AA` | Overlay gelap di balik modal |
| `ui-warning-stale` | `#E07050` | Indikator basi hari ke-3 |

### 3.3 Tipografi

Karena ini game pixel 2D, tipografi harus tetap terbaca di resolusi rendah:
- **Judul/Nama NPC**: Bold, ukuran 14–16 px referensi (bisa pixel font seperti *Press Start 2P* atau *Monogram*)
- **Teks Dialog**: Regular, 13–15 px, `autowrap_mode = AUTOWRAP_WORD_SMART`
- **Label UI Kecil (harga, jumlah)**: 11–13 px, monospace untuk angka

---

## 4. Spesifikasi Layar per Layar

### 4.1 HUD Gameplay (Dunia)

Overlay di atas scene dunia Godot. Harus **tidak menutupi area gameplay lebih dari 15% layar**.

```
┌─────────────────────────────────────────────────────┐
│ [☀ Cerah · 09:30 · Hari 3]        [📖 Buku Catatan] │
│                                                      │
│          . . . . . . . dunia . . . . . . .           │
│                                                      │
│          ⚡ Energi: ████████░░ 80/100               │
│                                                      │
│ [🕹 Joystick]                      [⚡ Interaksi]   │
└─────────────────────────────────────────────────────┘
```

**Elemen HUD:**
| Elemen | Posisi | Ukuran | Catatan |
|--------|--------|--------|---------|
| Badge Jam & Cuaca | Pojok kiri atas | Lebar 240 px, tinggi 32 px | Ikon cuaca + jam + hari |
| Tombol `📖 Buku Catatan` | Pojok kanan atas | 44 × 44 px min | Ikon buku terbuka |
| Bar Energi | Tengah bawah | Lebar 200 px, tinggi 16 px | Progress bar kayu + ikon kilat |
| Joystick Virtual | Kiri bawah | Lingkaran Ø 100 px | Hanya tampil di mode sentuh |
| Tombol Interaksi | Kanan bawah | 56 × 56 px | Ikon berbeda tergantung konteks |
| Toast Lokasi | Tengah atas | Lebar 240 px, tinggi 36 px | Muncul 2.5 detik, fade out |

---

### 4.2 Buku Catatan (Dual-Page Open Journal)

Dibuka saat tombol `📖 Buku Catatan` di HUD ditekan. Gameplay dijeda. Overlay gelap `#000000AA` di belakang.

```
╔═══════════════════════════════════════════════════════╗
║ SAMPUL JILID KULIT COKLAT · bookmark pita warna tab  ║
╠══════════════════╦════════════════════════════════════╣
║   HALAMAN KIRI   ║          HALAMAN KANAN             ║
║                  ║                                    ║
║ [Tab Aktif]      ║   [Detail Item / Quest / Status]   ║
║ ─────────────── ║                                    ║
║ [Daftar/Grid]   ║   [Ilustrasi besar + deskripsi]    ║
║                  ║                                    ║
║                  ║   [Tombol Aksi 1] [Tombol Aksi 2] ║
╚══════════════════╩════════════════════════════════════╝
```

**Dimensi:** 900 × 500 px (margin 30 px dari tepi kanvas 960×540).
**Lipatan Jilid:** Tekstur gelap vertikal 20 px di tengah-tengah.
**Bookmark Tab (di sisi atas/kanan buku):**

| Tab | Ikon | Warna Pita |
|-----|------|------------|
| Inventori | 🎒 | Coklat kulit |
| Resep | 🍳 | Merah bata |
| Quest | 📜 | Biru tinta |
| Warung | 🏠 | Hijau lumut |

#### Sub-layout Tab Inventori (Halaman Kiri)
- Grid slot **5 kolom × 4 baris** = 20 slot item
- Setiap slot: 48 × 48 px, bingkai kayu, sudut rounded 4 px
- Overlay angka stack kanan bawah
- Item kosong: slot redup dengan ikon tanda tanya

#### Sub-layout Tab Inventori (Halaman Kanan — Kartu Inspeksi)
- Area ilustrasi item 80 × 80 px
- Nama item: bold 14 px
- Deskripsi singkat: 12 px, maks 3 baris
- **Indikator Kesegaran Masakan:**
  - Hari 1: `🌿 Segar Sempurna` → warna hijau
  - Hari 2: `🍃 Mulai Pudar` → warna kuning
  - Hari 3: `⚠ Hampir Basi` → warna merah bata
- Nilai Energi: `+X ⚡` badge emas
- Bintang Kualitas: `★★☆` (1–3 bintang)
- Tombol Aksi: `[ Makan ]` `[ Pegang ]` `[ Buang ]`

#### Sub-layout Tab Resep (Halaman Kiri)
- Daftar scroll vertikal, setiap baris: ikon masakan + nama + status bahan
- Status bahan: `✓ Lengkap` (hijau) / `✗ Kurang: X` (merah)
- Resep terkunci: tampil redup dengan gembok

#### Sub-layout Tab Quest (Halaman Kiri)
- Kartu quest per NPC (Rast & Veral)
- Setiap kartu: nama NPC, meteran hati `♥♥♡` (1–3), judul bab quest
- Halaman kanan: detail objektif, syarat, dan hadiah berikutnya

#### Sub-layout Tab Warung (Halaman Kiri + Kanan)
- Kiri: Status tier warung (teks + nama tier), log 5 kepuasan pelanggan terakhir
- Kanan: Fasilitas aktif, syarat upgrade tier berikutnya, progress bar persyaratan

---

### 4.3 Layar Memasak (Floating Recipe Card Modal)

Muncul saat pemain berinteraksi dengan tungku/kompor warung. **Tidak dijeda — waktu terus berjalan.**

**Overlay:** `#000000` dengan opacity 60% di belakang kartu.
**Kartu Memasak:** 640 × 400 px, latar pergamen hangat `#F5F0D9`, bingkai kayu.

```
┌─────────────────────────────────────────────┐
│ ✕                       ⚡ -5/porsi · Hari 3│
│                                             │
│ PILIH RESEP:  [Sup Sayur Bening ▼]          │
│ ALAT:         [Api Unggun ▼]                │
│ PORSI:        [−] [1] [+]  (maks: 2)        │
│                                             │
│ BAHAN:                                      │
│  • Sayur liar   ✓ 1/1                       │
│  • Garam        ✓ 1/1                       │
│                                             │
│ HASIL: ★★☆  Estimasi  (cuaca Cerah: baik)  │
│                                             │
│ ══════════════════════ [Bar Timing Tungku]  │
│ [░░░░░MERAH░░░███HIJAU███░░░KUNING░░░░░░░] │
│              ↑ Jarum bergerak               │
│                                             │
│               [ 🍳 Mulai Masak ]            │
└─────────────────────────────────────────────┘
```

**Komponen dalam Kartu:**
| Komponen | Spesifikasi |
|----------|-------------|
| Dropdown Resep | Lebar 260 px, tinggi 40 px, bingkai kayu |
| Dropdown Alat | Lebar 200 px, tinggi 40 px |
| Stepper Porsi `[-][n][+]` | Setiap tombol 44 × 44 px min |
| Daftar Bahan | Scroll jika > 4 bahan, setiap baris 32 px |
| Bar Timing Tungku | Lebar penuh 580 px, tinggi 24 px |
| Zona Bar | Merah kiri 25%, Hijau tengah 30–50% (bergantung cuaca), Kuning sisanya |
| Tombol Mulai Masak | Lebar 200 px, tinggi 52 px, aksen emas |
| Tombol Tutup `✕` | 32 × 32 px, pojok kiri atas kartu |

---

### 4.4 Layar Toko (Giral & Talia — Quick Buy Rows)

Muncul saat pemain berinteraksi dengan pedagang saat jam buka.

**Modal:** 800 × 460 px, latar `#F5F0D9`, bingkai kayu tebal.

```
┌──────────────────────────────────────────────────────┐
│  🛒 Lapak Sayur Giral · Buka 07:00–12:00    💰 85 koin│
│  [Diskon Afeksi Hati 2: 5% ✓]                    [✕] │
│──────────────────────────────────────────────────────│
│ [🌿] Sayur liar        9 koin (~~10~~)  [-][1][+][Beli]│
│ [🐟] Ikan sungai      23 koin (~~25~~)  [-][1][+][Beli]│
│ [🍄] Jamur hutan       14 koin          [-][1][+][Beli]│
│ [🌿] Daun aromatik     7 koin           [-][1][+][Beli]│
│ ...                                                  │
│──────────────────────────────────────────────────────│
│                                    Total: 0 koin     │
└──────────────────────────────────────────────────────┘
```

**Spesifikasi Baris Item:**
| Kolom | Lebar | Keterangan |
|-------|-------|------------|
| Ikon barang | 32 × 32 px | Dalam kotak 40 × 40 px bingkai kayu |
| Nama + keterangan | ~240 px | Nama bold 13 px, stok kecil 11 px |
| Harga | ~80 px | Harga diskon bold aksen emas; harga asli dicoret redup |
| Stepper `[-][n][+]` | 3 × 44 px | Tombol bulat kayu |
| Tombol `Beli` | 72 × 36 px | Latar aksen hijau, teks putih bold |

---

### 4.5 Layar Dialog & Beri Masakan

#### Kotak Dialog Utama
Tampil di sepertiga bawah layar saat pemain berbicara dengan NPC.

```
┌─────────────────────────────────────────────────────┐
│ [ Rast · Penebang Kayu ]                            │
│                                                     │
│ "Hei, sudah waktunya makan siang. Kalau ada lebih   │
│  dari satu porsi, bolehlah aku cicipin..."          │
│                                                     │
│                    [ Beri Masakan ]  [ Lanjut ▶ ]   │
└─────────────────────────────────────────────────────┘
```

**Spesifikasi:**
| Elemen | Nilai |
|--------|-------|
| Posisi | Bottom 0, lebar penuh 960 px |
| Tinggi kotak | 180 px |
| Latar | Pergamen `#F5F5DC`, transparansi 95% |
| Badge nama NPC | Pojok kiri atas kotak, latar aksen coklat, teks putih |
| Teks dialog | 13–14 px, padding 20 px |
| Tombol `Lanjut ▶` | Pojok kanan bawah, 120 × 44 px |
| Tombol `Beri Masakan` | Di kiri tombol Lanjut, 160 × 44 px, aksen emas |

#### Drawer Pilihan Masakan (Geser dari Kanan)
Muncul di atas kotak dialog saat `[ Beri Masakan ]` ditekan. Kotak dialog tetap terlihat di bawah.

```
                    ┌─────────────────────────┐
                    │  Pilih untuk: Rast       │
                    │                     [✕] │
                    │ [🍲] Sup Sayur ★★★ 🌿  │
                    │ [🍲] Bubur Ikan ★★☆ 🍃  │
                    │ [🥘] Tumis Liar ★☆☆ ⚠  │
                    │                         │
                    └─────────────────────────┘
┌─────────────────────────────────────────────────────┐
│ [ Rast · Penebang Kayu ]                            │
│ "Hei, sudah waktunya makan siang..."                │
│                    [ Beri Masakan ]  [ Lanjut ▶ ]   │
└─────────────────────────────────────────────────────┘
```

**Spesifikasi Drawer:**
| Elemen | Nilai |
|--------|-------|
| Posisi | Kanan layar, bottom tepat di atas kotak dialog |
| Lebar | 320 px |
| Tinggi | Hingga 240 px (maks 4 item, scroll jika lebih) |
| Setiap baris item | Ikon 32 px + Nama + Badge bintang + Indikator kesegaran |
| Tombol tutup `✕` | 32 × 32 px pojok kanan atas drawer |

---

### 4.6 Layar Main Menu

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│           🌿 HEARTHWOOD: WARUNG RIMBA 🌿            │
│                                                     │
│           Slot tunggal: Varian · Hari 7 · Tier 2   │
│                                                     │
│              [ Lanjutkan      ]                     │
│              [ Permainan Baru ]                     │
│              [ Muat Game      ]                     │
│              [ Pengaturan     ]                     │
│              [ Keluar         ]                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Visual:** Latar ilustratif statis (pohon rimba dengan cahaya tembus daun), panel menu tengah berlatar papan kayu tua.

---

### 4.7 Layar Pause Menu

Modal kompak muncul saat game dijeda. Latar dunia masih terlihat, digelapkan overlay.

**Ukuran Panel:** 380 × 320 px, tengah layar.

Tombol: `[ Lanjutkan ]` · `[ Simpan Game ]` · `[ Muat Game ]` · `[ Menu Utama ]`

---

## 5. Component Library — Daftar Atom & Molekul

Semua komponen berikut harus dibuat di halaman `🧩 Component Library` di FigCraft sebagai komponen yang bisa di-instance.

### 5.1 Atom (Komponen Paling Kecil)

| Nama Komponen | Ukuran | Deskripsi |
|---------------|--------|-----------|
| `Slot/Item` | 48 × 48 px | Kotak slot inventori (normal, kosong, hover) |
| `Btn/Primary` | min 160 × 44 px | Tombol aksi utama, latar emas |
| `Btn/Secondary` | min 120 × 44 px | Tombol sekunder, latar kayu |
| `Btn/Danger` | min 100 × 44 px | Tombol buang/hapus, latar merah bata |
| `Btn/Close` | 32 × 32 px | Tombol ✕ tutup modal |
| `Stepper` | 132 × 44 px | Komponen `[-][n][+]` untuk porsi/jumlah beli |
| `Badge/Coin` | Variabel | Ikon 🪙 + angka, latar emas muda |
| `Badge/Energy` | Variabel | Ikon ⚡ + angka, latar biru langit |
| `Badge/Star` | 72 × 20 px | Rating ★★☆ (1–3 bintang) |
| `Badge/Affection` | 60 × 20 px | Meteran hati ♥♥♡ (1–3 hati) |
| `Badge/Freshness` | Variabel | 🌿/🍃/⚠ indikator basi masakan |
| `Badge/Discount` | Variabel | Label diskon afeksi, latar aksen hijau |
| `Bar/Energy` | 200 × 16 px | Progress bar energi dengan segmentasi |
| `Bar/Timing` | 580 × 24 px | Bar timing memasak dengan zona warna |

### 5.2 Molekul (Gabungan Atom)

| Nama Komponen | Deskripsi |
|---------------|-----------|
| `Card/Item` | Slot + Nama + Badge Star + Badge Freshness + Badge Energy |
| `Card/Recipe` | Ikon masakan + Nama resep + Status bahan (✓/✗) |
| `Card/Quest` | Badge NPC + Meteran hati + Judul bab + Deskripsi singkat |
| `Row/ShopItem` | Ikon + Nama + Harga (dengan coret diskon) + Stepper + Btn/Primary |
| `Header/Shop` | Nama pedagang + Jam buka + Badge/Coin + Badge/Discount |
| `Header/HUD` | Badge jam & cuaca + Btn Buku Catatan |
| `Footer/Dialog` | Badge nama NPC + Teks dialog + Btn Beri Masakan + Btn Lanjut |
| `Panel/JournalPage` | Latar pergamen + Shadow + Bingkai kayu (kiri atau kanan) |
| `Tab/Bookmark` | Pita bookmark dengan ikon tab (4 varian warna) |

---

## 6. Struktur Halaman FigCraft

File FigCraft harus diorganisir dengan halaman-halaman berikut:

| Halaman | Konten |
|---------|--------|
| `📐 Design Tokens` | Palet warna, tipografi, ukuran spacing, dan aturan layout |
| `🧩 Component Library` | Semua atom dan molekul dari bagian 5 |
| `🎮 HUD Gameplay` | Mockup full 960×540 HUD dunia |
| `📖 Buku Catatan — Inventori` | Mockup full buku terbuka, tab Inventori aktif |
| `📖 Buku Catatan — Resep` | Mockup full, tab Resep aktif |
| `📖 Buku Catatan — Quest` | Mockup full, tab Quest aktif |
| `📖 Buku Catatan — Warung` | Mockup full, tab Warung aktif |
| `🍳 Layar Memasak` | Mockup modal melayang di atas dunia |
| `🛒 Layar Toko Giral` | Mockup toko bahan pagi |
| `🛒 Layar Toko Talia` | Mockup toko perkakas siang |
| `💬 Dialog & Gift Drawer` | Mockup kotak dialog + drawer masakan aktif |
| `🏠 Main Menu` | Mockup layar utama |
| `⏸ Pause Menu` | Mockup menu jeda |

---

## 7. Rencana Fase Pengerjaan (Milestones 0.4.0)

### Fase 21 — Design Tokens & Component Library

**Tujuan:** Membangun fondasi desain — semua token dan atom/molekul yang akan dipakai seluruh mockup.

**Tugas:**
- [ ] Setup FigCraft file baru: `Hearthwood UI Kit v0.4.0`
- [ ] Halaman `📐 Design Tokens`: Palet warna (8 token), tipografi (3 ukuran), spacing (4px grid)
- [ ] Buat seluruh **Atom** (14 komponen) dari bagian 5.1
- [ ] Buat seluruh **Molekul** (9 komponen) dari bagian 5.2
- [ ] Pastikan setiap komponen memiliki minimal 2 state: *normal* dan *disabled/empty*

**Definition of Done:**
- [ ] Semua 23 komponen tersimpan di halaman `🧩 Component Library`
- [ ] Setiap komponen dapat di-instance ulang tanpa perlu menggambar ulang
- [ ] Tombol sentuh seluruhnya ≥ 44 × 44 px

### Fase 22 — HUD Gameplay & Buku Catatan

**Tujuan:** Membangun layar yang paling sering dilihat pemain — HUD dunia dan jurnal Buku Catatan 4 tab.

**Tugas:**
- [ ] Mockup HUD Gameplay 960×540 (pakai komponen dari Fase 21)
- [ ] Mockup Buku Catatan terbuka: Tab Inventori (kiri = grid 5×4, kanan = kartu inspeksi)
- [ ] Mockup Tab Resep (daftar scroll + status bahan)
- [ ] Mockup Tab Quest (kartu Rast & Veral dengan meteran hati)
- [ ] Mockup Tab Warung (status tier + log kepuasan + syarat upgrade)
- [ ] Tekstur jilid kulit dan lipatan halaman di tengah

**Definition of Done:**
- [ ] 5 halaman FigCraft selesai (HUD + 4 tab buku)
- [ ] Screenshot FigCraft diverifikasi untuk keterbacaan teks di 960×540

### Fase 23 — Layar Memasak & Toko

**Tujuan:** Membangun dua layar modal utilitas yang paling sering dipakai selama bermain.

**Tugas:**
- [ ] Mockup Layar Memasak (modal 640×400 di atas dunia dengan overlay gelap)
- [ ] Bar timing tungku dengan zona merah/hijau/kuning
- [ ] Mockup Layar Toko Giral (baris instan, header badge diskon, saldo koin)
- [ ] Mockup Layar Toko Talia (varian perkakas dengan visual berbeda pada badge header)

**Definition of Done:**
- [ ] 3 halaman FigCraft selesai (Memasak, Toko Giral, Toko Talia)
- [ ] Mockup Toko Giral dan Talia dapat dibedakan secara visual tanpa membaca nama

### Fase 24 — Dialog, Main Menu & Pause Menu

**Tujuan:** Melengkapi seluruh layar kontekstual naratif dan navigasi sistem.

**Tugas:**
- [ ] Mockup Kotak Dialog sepertiga bawah layar (badge nama NPC, teks, tombol)
- [ ] Mockup Drawer Pilihan Masakan aktif (di atas kotak dialog, dengan indikator basi)
- [ ] Mockup Main Menu (panel kayu tengah, slot save, 5 tombol)
- [ ] Mockup Pause Menu (modal kompak 380×320 px)

**Definition of Done:**
- [ ] 4 halaman FigCraft selesai
- [ ] Seluruh 13 halaman FigCraft lengkap dan konsisten secara visual

---

## 8. Kriteria Selesai v0.4.0

- [ ] File FigCraft `Hearthwood UI Kit v0.4.0` berisi 13 halaman yang lengkap
- [ ] Seluruh 23 komponen (14 atom + 9 molekul) tersimpan di Component Library
- [ ] Semua tombol sentuh ≥ 44 × 44 px
- [ ] Mockup menggunakan palet warna dari `DESIGN.md` tanpa deviasi
- [ ] Screenshot setiap halaman dapat diekspor dan terbaca di resolusi 960×540
- [ ] Tidak ada kode GDScript yang ditulis pada versi ini
- [ ] Panduan export (format, nama file) tersedia di halaman `📐 Design Tokens`

---

## 9. Panduan Implementasi (Untuk v0.5.0)

Bagian ini ditulis sekarang agar developer Godot di v0.5.0 tidak perlu kembali ke FigCraft untuk menanyakan hal-hal berikut:

- Semua panel UI menggunakan `PanelContainer` dengan `StyleBoxFlat` (warna dari palet).
- Komponen 9-slice (bingkai kayu) diekspor sebagai PNG dengan margin 9-slice yang dicatat di halaman `📐 Design Tokens`.
- Tombol menggunakan `Button` dengan `custom_minimum_size` ≥ Vector2(44, 44).
- Bar timing memasak diimplementasi sebagai `TextureProgressBar` atau `NinePatchRect`.
- Drawer geser diimplementasi dengan `Control.position.x` yang di-tween (-320 ke 0).
- Buku Catatan diimplementasi sebagai `TabContainer` di dalam `Control` berlatar pergamen.

---

*Dokumen ini adalah satu-satunya sumber kebenaran desain untuk v0.4.0. Jika ada konflik antara dokumen ini dan DESIGN.md versi lama, dokumen ini yang berlaku.*
