# Hearthwood UI Design v0.4.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun file FigCraft `Hearthwood UI Kit v0.4.0` yang berisi 13 halaman — Component Library lengkap (23 komponen) dan Full Screen Mockups untuk seluruh layar utama game.

**Architecture:** Semua kerja dilakukan eksklusif via FigCraft MCP tools (`create_node`, `set_properties`, `batch`, `screenshot`). Tidak ada GDScript/Godot. Komponen dibangun bottom-up: Design Tokens → Atom → Molekul → Full Screen Mockups. Setiap task menghasilkan halaman FigCraft yang bisa di-screenshot dan diverifikasi.

**Tech Stack:** FigCraft MCP (`127.0.0.1:8080`), Figma/FigCraft design primitives (Frame, Rectangle, Text, Group)

**Spec:** `C:\Users\Hype GLK\hearthwood-rimba\PRD Hearthwood Warung Rimba (Versi 0.4.0).md`

## Global Constraints

- Kanvas setiap full-screen mockup: **960 × 540 px** (landscape, 1 px FigCraft = 1 px Godot)
- Minimum touch target: **44 × 44 px** — wajib untuk semua tombol interaktif
- Palet warna: 8 token dari PRD §3.2 — tidak ada deviasi warna di luar token
- Font pixel-readable: ukuran 11–16 px (lihat PRD §3.3)
- Semua komponen diberi nama layer yang jelas mengikuti konvensi `Kategori/Nama` (contoh: `Btn/Primary`, `Card/Item`)
- Tidak ada kode GDScript yang ditulis pada versi ini
- FigCraft harus berjalan di `127.0.0.1:8080` sebelum eksekusi

## Review Focus

- **Keterbacaan teks 11–13 px di 960×540:** Teks label kecil (harga, jumlah) bisa susah dibaca di layar kecil — verifikasi dengan screenshot setelah setiap mockup selesai
- **Touch target ≥ 44×44 pada Stepper:** Tombol `[-]` dan `[+]` yang kecil berpotensi di bawah minimum — ukur setelah Task 2 selesai
- **Drawer Masakan tidak menutupi tombol Dialog:** Drawer (320 px kanan) dan Footer Dialog (960 px lebar) harus co-exist tanpa overlap — verifikasi di Task 7
- **Buku Catatan 900×500 dalam kanvas 960×540:** Margin 30 px harus cukup untuk bookmark tab yang menonjol keluar — verifikasi di Task 4
- **Overlay gelap memasak (#000000 60%) tidak menghilangkan konteks dunia:** Screenshot Task 5 harus menampilkan "world hint" di balik modal

---

## Task 1: Setup File & Halaman Design Tokens

**Files:**
- Create: FigCraft page `📐 Design Tokens` di file baru `Hearthwood UI Kit v0.4.0`

**Interfaces:**
- Produces: Frame `DesignTokens/Colors` (8 color swatches berlabel), Frame `DesignTokens/Typography` (3 ukuran font), Frame `DesignTokens/Grid` (4px spacing grid visual), Frame `DesignTokens/ExportGuide` (aturan nama file & format)

- [ ] **Step 1: Buka file baru di FigCraft**

  Jalankan `open_file` atau `run_command` untuk membuat file baru bernama `Hearthwood UI Kit v0.4.0`. Jika FigCraft tidak support "new file" langsung, buat Frame kosong 960×540 sebagai starting point.

- [ ] **Step 2: Buat Frame `DesignTokens/Colors` (8 color swatches)**

  Buat 8 Rectangle 80×80 px masing-masing dengan fill:
  - `#F5F5DC` label `ui-bg-parchment`
  - `#F5F0D9` label `ui-bg-parchment-warm`
  - `#CD853F` label `ui-accent-gold`
  - `#8FBC8F` label `ui-accent-green`
  - `#333333` label `ui-text-dark`
  - `#8B4513` label `ui-border-wood`
  - `#000000AA` label `ui-overlay-dim`
  - `#E07050` label `ui-warning-stale`

  Di bawah setiap rectangle, tambahkan Text dengan hex value dan nama token.

- [ ] **Step 3: Buat Frame `DesignTokens/Typography`**

  Buat 3 Text node:
  - Bold 16 px: `Judul/Nama NPC — Bold 16px`
  - Regular 14 px: `Teks Dialog — Regular 14px`
  - Monospace 12 px: `Label UI Kecil (harga, angka) — 12px`

- [ ] **Step 4: Buat Frame `DesignTokens/ExportGuide`**

  Text block berisi aturan export:
  - Format: PNG untuk aset raster, 9-slice margin dicatat per komponen
  - Penamaan file: `snake_case` (contoh: `btn_primary.png`, `panel_journal.png`)
  - 9-slice margin: `12 px` untuk bingkai kayu (catat sebagai referensi v0.5.0)

- [ ] **Step 5: Screenshot halaman dan verifikasi semua token terbaca**

  Jalankan `screenshot` pada halaman ini. Pastikan semua label warna dan font size terbaca jelas.

- [ ] **Step 6: Commit progress via save FigCraft**

  Jalankan `save_file` untuk memastikan progress tidak hilang.

---

## Task 2: Komponen Atom (14 Komponen)

**Files:**
- Create: FigCraft page `🧩 Component Library` — section **Atoms**

**Interfaces:**
- Consumes: Tokens dari Task 1 (warna `#CD853F`, `#8FBC8F`, `#8B4513`, dll.)
- Produces: 14 komponen atom dengan nama layer `Atom/[Nama]`, siap di-instance

- [ ] **Step 1: Buat `Atom/Slot-Item` (48×48 px)**

  Rectangle 48×48 px, fill `#F5F5DC`, stroke `#8B4513` 2 px, corner radius 4 px.
  Tambahkan 3 state sebagai child group: `state=normal`, `state=empty` (opacity 50%, ikon tanda tanya), `state=hover` (stroke lebih tebal 3 px).

- [ ] **Step 2: Buat `Atom/Btn-Primary` (min 160×44 px)**

  Rectangle 160×44 px, fill `#CD853F`, corner radius 6 px.
  Text di tengah: `Tombol Utama`, warna `#F5F5DC`, bold 13 px.
  Tambahkan state `disabled`: opacity 40%.

- [ ] **Step 3: Buat `Atom/Btn-Secondary` (min 120×44 px)**

  Rectangle 120×44 px, fill `#8B4513`, corner radius 6 px.
  Text: `Sekunder`, warna `#F5F5DC`, bold 13 px.

- [ ] **Step 4: Buat `Atom/Btn-Danger` (min 100×44 px)**

  Rectangle 100×44 px, fill `#E07050`, corner radius 6 px.
  Text: `Buang`, warna putih `#FFFFFF`, bold 13 px.

- [ ] **Step 5: Buat `Atom/Btn-Close` (32×32 px)**

  Lingkaran (Ellipse) 32×32 px, fill `#8B4513`.
  Text `✕` di tengah, warna putih, bold 14 px.

- [ ] **Step 6: Buat `Atom/Stepper` (132×44 px)**

  Grup horizontal 3 elemen: `[-]` Rectangle 44×44 px fill `#8B4513` + Text, `[n]` Text center 44×44 px latar `#F5F5DC`, `[+]` Rectangle 44×44 px fill `#8B4513` + Text.
  **Verifikasi:** Setiap tombol ≥ 44×44 px.

- [ ] **Step 7: Buat 6 Badge Atom**

  - `Atom/Badge-Coin`: latar `#F0D080`, ikon 🪙 + angka `99`, corner radius 10 px, tinggi 24 px
  - `Atom/Badge-Energy`: latar `#A0C4F0`, ikon ⚡ + angka `80`, tinggi 24 px
  - `Atom/Badge-Star`: 3 ikon bintang ★★☆, 72×20 px, warna emas `#CD853F`
  - `Atom/Badge-Affection`: 3 ikon hati ♥♥♡, 60×20 px, warna merah muda
  - `Atom/Badge-Freshness`: 3 varian — 🌿 hijau / 🍃 kuning / ⚠ merah bata, tinggi 24 px
  - `Atom/Badge-Discount`: latar `#8FBC8F`, teks `Diskon 5%`, putih, tinggi 24 px

- [ ] **Step 8: Buat `Atom/Bar-Energy` (200×16 px)**

  Rectangle background 200×16 px, fill `#333333`.
  Rectangle fill 160×12 px (80% fill) di atas, fill `#8FBC8F`.
  Ikon ⚡ di kiri.

- [ ] **Step 9: Buat `Atom/Bar-Timing` (580×24 px)**

  Rectangle background 580×24 px.
  3 zona: Merah (kiri 25% = 145 px, fill `#E07050`), Hijau (tengah 30% = 174 px, fill `#8FBC8F`), Kuning (sisa = 261 px, fill `#F0D080`).
  Jarum/needle: Rectangle 4×32 px, fill putih, posisi di zona hijau tengah.

- [ ] **Step 10: Screenshot semua atom dan verifikasi ukuran minimum**

  Jalankan `screenshot`. Semua tombol harus ≥ 44×44 px. Jika ada yang kurang, perbaiki sebelum lanjut.

- [ ] **Step 11: Save**

---

## Task 3: Komponen Molekul (9 Komponen)

**Files:**
- Create: FigCraft page `🧩 Component Library` — section **Molecules** (di bawah Atoms)

**Interfaces:**
- Consumes: Semua 14 Atom dari Task 2
- Produces: 9 komponen molekul dengan nama `Molecule/[Nama]`

- [ ] **Step 1: Buat `Molecule/Card-Item`**

  Susun: `Atom/Slot-Item` (48×48) + Text nama item (bold 13 px) + `Atom/Badge-Star` + `Atom/Badge-Freshness` + `Atom/Badge-Energy`.
  Ukuran kartu keseluruhan: 160×80 px.

- [ ] **Step 2: Buat `Molecule/Card-Recipe`**

  Ikon masakan 32×32 px + Text nama resep (bold 13 px) + status bahan `✓ Lengkap` / `✗ Kurang: X`.
  Ukuran: lebar 300 px, tinggi 44 px per baris.

- [ ] **Step 3: Buat `Molecule/Card-Quest`**

  Badge nama NPC (latar coklat) + `Atom/Badge-Affection` ♥♥♡ + Text judul bab + Text deskripsi singkat.
  Ukuran: 400×80 px.

- [ ] **Step 4: Buat `Molecule/Row-ShopItem`**

  Susun horizontal: Ikon 32×32 dalam kotak 40×40 + Text nama+stok + `Atom/Badge-Coin` + `Atom/Stepper` + `Atom/Btn-Primary` ("Beli").
  Tinggi baris: 52 px. Lebar total: 740 px (margin dalam modal 800 px).

- [ ] **Step 5: Buat `Molecule/Header-Shop`**

  Text nama pedagang bold 14 px + Text jam buka 12 px + `Atom/Badge-Coin` + `Atom/Badge-Discount` + `Atom/Btn-Close` di kanan.
  Tinggi: 48 px, lebar: 760 px.

- [ ] **Step 6: Buat `Molecule/Header-HUD`**

  Kiri: ikon cuaca ☀ + Text jam `09:30` + Text hari `Hari 3` dalam frame 240×32 px latar `#00000066`.
  Kanan: `Atom/Btn-Secondary` dengan ikon 📖 dan label `Buku Catatan`, 44×44 px min.

- [ ] **Step 7: Buat `Molecule/Footer-Dialog`**

  Rectangle 960×180 px, fill `#F5F5DC` opacity 95%.
  Kiri atas: Badge nama NPC latar `#8B4513`, teks putih.
  Area teks dialog: padding 20 px, 13 px.
  Kanan bawah: `Atom/Btn-Primary` ("Beri Masakan") 160×44 px + `Atom/Btn-Secondary` ("Lanjut ▶") 120×44 px.

- [ ] **Step 8: Buat `Molecule/Panel-JournalPage`**

  Rectangle 420×460 px (setengah dari 900×500 buku), fill `#F5F5DC`, stroke `#8B4513` 3 px, corner radius 4 px.
  Shadow ringan. Buat 2 varian: `side=left` dan `side=right`.

- [ ] **Step 9: Buat `Molecule/Tab-Bookmark`**

  Rectangle 32×80 px, corner radius 4 px kanan (tab menonjol).
  Ikon di tengah, text label kecil di bawah ikon.
  4 varian warna: coklat kulit (Inventori), merah bata (Resep), biru tinta (Quest), hijau lumut (Warung).

- [ ] **Step 10: Screenshot dan verifikasi semua molekul konsisten visual**

- [ ] **Step 11: Save**

---

## Task 4: Mockup HUD Gameplay & Buku Catatan (5 Halaman)

**Files:**
- Create: FigCraft pages `🎮 HUD Gameplay`, `📖 Buku Catatan — Inventori`, `📖 Buku Catatan — Resep`, `📖 Buku Catatan — Quest`, `📖 Buku Catatan — Warung`

**Interfaces:**
- Consumes: `Molecule/Header-HUD`, `Atom/Bar-Energy`, `Atom/Btn-Secondary` (joystick placeholder), `Molecule/Panel-JournalPage`, `Molecule/Tab-Bookmark`, `Atom/Slot-Item`, `Molecule/Card-Recipe`, `Molecule/Card-Quest`
- Produces: 5 halaman FigCraft full 960×540 px

- [ ] **Step 1: Buat halaman `🎮 HUD Gameplay` (960×540)**

  Frame utama 960×540, fill `#4A7C4E` (placeholder warna dunia/hutan).
  Susun:
  - Pojok kiri atas: `Molecule/Header-HUD` (clock+cuaca+tombol buku)
  - Tengah bawah: `Atom/Bar-Energy` (200×16, center-X)
  - Kiri bawah: Lingkaran joystick Ø 100 px, fill `#FFFFFF44`, stroke putih
  - Kanan bawah: Lingkaran tombol interaksi 56×56 px, fill `#CD853F`
  - Tengah atas: Frame Toast 240×36 px, latar `#00000088`, text `Hutan Utara` — tampil redup sebagai contoh

- [ ] **Step 2: Screenshot HUD dan verifikasi HUD tidak menutupi >15% layar**

  Area HUD (atas 32 px + bawah 80 px) = ±112 px dari 540 px ≈ 20%. Jika berlebih, kurangi tinggi area bawah atau naikkan bar energi lebih ke tengah.

- [ ] **Step 3: Buat halaman `📖 Buku Catatan — Inventori` (960×540)**

  Frame 960×540, overlay gelap `#000000AA` sebagai background.
  Frame buku 900×500 (posisi: x=30, y=20), latar `#8B4513` (cover kulit).
  2 Panel: `Molecule/Panel-JournalPage` side=left (x=30, w=420) dan side=right (x=460, w=420).
  Lipatan jilid: Rectangle 20×480 px, fill `#5C2E00`, posisi x=440.
  4 `Molecule/Tab-Bookmark` di sisi kanan buku, vertikal, Inventori aktif (lebih besar/terang).

  Halaman kiri: Grid 5×4 `Atom/Slot-Item` (48×48, gap 8 px). Mulai x=50, y=50.
  Halaman kanan: Kartu Inspeksi — ilustrasi 80×80 px + nama bold 14 px + deskripsi 12 px + `Atom/Badge-Freshness` + `Atom/Badge-Energy` + `Atom/Badge-Star` + 3 tombol Makan/Pegang/Buang.

- [ ] **Step 4: Buat halaman `📖 Buku Catatan — Resep`**

  Sama dengan Inventori (buku + overlay). Tab Resep aktif.
  Halaman kiri: Daftar vertikal `Molecule/Card-Recipe` (scroll 6 baris).
  Halaman kanan: Detail resep terpilih — bahan-bahan, estimasi kualitas, NPC yang suka.

- [ ] **Step 5: Buat halaman `📖 Buku Catatan — Quest`**

  Tab Quest aktif.
  Halaman kiri: 2 `Molecule/Card-Quest` (Rast + Veral), dengan meteran hati.
  Halaman kanan: Detail quest Rast — judul bab, objektif list, hadiah berikutnya.

- [ ] **Step 6: Buat halaman `📖 Buku Catatan — Warung`**

  Tab Warung aktif.
  Halaman kiri: Text tier `Warung Sederhana · Tier 1` + Log 5 kepuasan (5 baris text 12 px).
  Halaman kanan: Fasilitas aktif (list), Syarat upgrade Tier 2, progress bar tiap syarat.

- [ ] **Step 7: Screenshot semua 4 tab buku dan verifikasi keterbacaan teks**

- [ ] **Step 8: Save**

---

## Task 5: Mockup Layar Memasak & Toko (3 Halaman)

**Files:**
- Create: FigCraft pages `🍳 Layar Memasak`, `🛒 Layar Toko Giral`, `🛒 Layar Toko Talia`

**Interfaces:**
- Consumes: `Atom/Btn-Primary`, `Atom/Btn-Close`, `Atom/Stepper`, `Atom/Bar-Timing`, `Molecule/Row-ShopItem`, `Molecule/Header-Shop`, `Atom/Badge-Discount`
- Produces: 3 halaman FigCraft full 960×540

- [ ] **Step 1: Buat halaman `🍳 Layar Memasak` (960×540)**

  Frame 960×540, background `#4A7C4E` (dunia terlihat, hint: pohon placeholder).
  Overlay Rectangle 960×540, fill `#000000`, opacity 60%.
  Modal kartu 640×400 px, posisi center (x=160, y=70), fill `#F5F0D9`, stroke `#8B4513` 3 px, corner radius 8 px.

  Dalam modal (koordinat relatif dari x=160, y=70):
  - `Atom/Btn-Close` di x=10, y=10
  - Text atas kanan: `⚡ -5/porsi · Hari 3`, 11 px
  - Row PILIH RESEP: Text label + Rectangle dropdown 260×40 px (`Sup Sayur Bening ▼`), y=50
  - Row ALAT: Text label + dropdown 200×40 px, y=100
  - Row PORSI: Text label + `Atom/Stepper` 132×44 px, y=150
  - Section BAHAN: 2 baris teks (√/✗ + nama + stok), y=210
  - Section HASIL: Text `★★☆ Estimasi (cuaca Cerah: baik)`, y=290
  - `Atom/Bar-Timing` 580×24 px, y=320
  - `Atom/Btn-Primary` ("🍳 Mulai Masak") 200×52 px, center-X, y=355

- [ ] **Step 2: Screenshot dan verifikasi "world hint" terlihat di balik overlay**

  Dunia (Rectangle hijau) harus masih sedikit terlihat di sudut-sudut layar di luar modal.

- [ ] **Step 3: Buat halaman `🛒 Layar Toko Giral` (960×540)**

  Frame 960×540, background dunia `#4A7C4E`.
  Overlay `#000000AA`.
  Modal 800×460 px, posisi center (x=80, y=40), fill `#F5F0D9`, stroke `#8B4513` 4 px.

  Dalam modal:
  - `Molecule/Header-Shop`: nama `Lapak Sayur Giral · Buka 07:00–12:00`, `Atom/Badge-Coin` (saldo 85 koin), `Atom/Badge-Discount` (`Diskon Hati 2: 5% ✓`), `Atom/Btn-Close`
  - Separator line 760×2 px, fill `#8B4513`
  - 4 baris `Molecule/Row-ShopItem`: Sayur liar / Ikan sungai / Jamur hutan / Daun aromatik
  - Footer: Text `Total: 0 koin` rata kanan

  **Visual diferensiasi Giral:** Header latar merah bata / hangat, ikon 🌿 dominan

- [ ] **Step 4: Buat halaman `🛒 Layar Toko Talia` (960×540)**

  Identik struktur dengan Giral, tapi:
  - Nama: `Toko Perkakas Talia · Buka 10:00–17:00`
  - Barang: Api Unggun / Kompor Tanah / Periuk Tua / Wajan Besi
  - **Visual diferensiasi Talia:** Header latar biru-abu (berbeda dari Giral), ikon 🔨 dominan

- [ ] **Step 5: Screenshot kedua toko dan verifikasi visual dapat dibedakan tanpa membaca nama**

- [ ] **Step 6: Save**

---

## Task 6: Mockup Main Menu & Pause Menu (2 Halaman)

**Files:**
- Create: FigCraft pages `🏠 Main Menu`, `⏸ Pause Menu`

**Interfaces:**
- Consumes: `Atom/Btn-Primary`, `Atom/Btn-Secondary`
- Produces: 2 halaman FigCraft full 960×540

- [ ] **Step 1: Buat halaman `🏠 Main Menu` (960×540)**

  Frame 960×540, background `#2D5A27` (hutan gelap statis, bisa placeholder rectangle dengan gradien).
  Panel papan kayu tengah: Rectangle 360×360 px (posisi center, x=300, y=90), fill `#5C3A1E`, corner radius 8 px, stroke `#8B4513` 4 px.

  Dalam panel:
  - Text `🌿 HEARTHWOOD: WARUNG RIMBA 🌿`, bold 16 px, center, warna `#F5F5DC`, y=20
  - Text slot save `Varian · Hari 7 · Tier 2`, 12 px, y=60
  - Separator 300×2 px, y=90
  - 5 Tombol vertikal (gap 12 px), masing-masing 280×44 px, fill `#CD853F`, corner radius 6 px:
    - `Lanjutkan` (y=110)
    - `Permainan Baru` (y=166)
    - `Muat Game` (y=222)
    - `Pengaturan` (y=278)
    - `Keluar` (y=334, fill `#E07050` sebagai tombol bahaya)

- [ ] **Step 2: Buat halaman `⏸ Pause Menu` (960×540)**

  Frame 960×540, background `#4A7C4E` (game world terlihat), overlay `#000000` opacity 60%.
  Modal 380×320 px, posisi center (x=290, y=110), fill `#F5F0D9`, stroke `#8B4513` 3 px, corner radius 8 px.

  Dalam modal:
  - Text `⏸ Dijeda`, bold 14 px, center, y=20
  - Separator, y=50
  - 4 tombol vertikal 300×44 px (gap 12 px):
    - `Lanjutkan` (fill `#CD853F`, y=70)
    - `Simpan Game` (fill `#8B4513`, y=126)
    - `Muat Game` (fill `#8B4513`, y=182)
    - `Menu Utama` (fill `#E07050`, y=238)

- [ ] **Step 3: Screenshot kedua halaman**

- [ ] **Step 4: Save**

---

## Task 7: Mockup Dialog & Gift Drawer (1 Halaman)

**Files:**
- Create: FigCraft page `💬 Dialog & Gift Drawer`

**Interfaces:**
- Consumes: `Molecule/Footer-Dialog`, `Atom/Btn-Close`, `Atom/Badge-Star`, `Atom/Badge-Freshness`
- Produces: 1 halaman FigCraft full 960×540 — state aktif (drawer terbuka)

- [ ] **Step 1: Buat halaman `💬 Dialog & Gift Drawer` (960×540)**

  Frame 960×540, background `#4A7C4E` (dunia, placeholder pohon-pohon).

  **Kotak Dialog (dari `Molecule/Footer-Dialog`):**
  Rectangle 960×180 px, posisi y=360, fill `#F5F5DC` opacity 95%, stroke `#8B4513` atas 2 px.
  - Badge nama NPC kiri atas: Rectangle latar `#8B4513`, teks putih `Rast · Penebang Kayu`, 12 px
  - Teks dialog: `"Hei, sudah waktunya makan siang. Kalau ada lebih dari satu porsi, bolehlah aku cicipin..."`, 13 px, padding 20 px, y=40
  - Tombol kanan bawah: `Atom/Btn-Primary` `Beri Masakan` (160×44 px) + `Atom/Btn-Secondary` `Lanjut ▶` (120×44 px), gap 12 px, bottom 16 px

  **Drawer Pilihan Masakan (di atas kotak dialog, kanan layar):**
  Rectangle 320×240 px, posisi x=640, y=120 (tepat di atas kotak dialog, bottom=360), fill `#F5F5DC`, stroke `#8B4513` 2 px, corner radius 8 px kiri atas+kiri bawah.
  - Header: Text `Pilih untuk: Rast`, 13 px bold + `Atom/Btn-Close` di kanan
  - 3 baris masakan, masing-masing 40 px tinggi:
    - Baris 1: Ikon 🍲 + `Sup Sayur` + `Atom/Badge-Star` ★★★ + `Atom/Badge-Freshness` 🌿
    - Baris 2: Ikon 🍲 + `Bubur Ikan` + `Atom/Badge-Star` ★★☆ + `Atom/Badge-Freshness` 🍃
    - Baris 3: Ikon 🥘 + `Tumis Liar` + `Atom/Badge-Star` ★☆☆ + `Atom/Badge-Freshness` ⚠

- [ ] **Step 2: Verifikasi Drawer tidak overlap dengan tombol `Lanjut ▶` di kotak dialog**

  Drawer bottom (y=360) = kotak dialog top (y=360). Tidak ada overlap — pastikan visual. Jika tombol di dalam drawer dan tombol di footer saling menutupi, geser drawer naik.

- [ ] **Step 3: Screenshot dan verifikasi kedua elemen (dialog + drawer) terbaca bersamaan**

- [ ] **Step 4: Save**

---

## Task 8: Verifikasi Final & Export Checklist

**Files:**
- Read: Semua 13 halaman FigCraft

**Interfaces:**
- Consumes: Semua 13 halaman dari Task 1–7
- Produces: Screenshot set lengkap, daftar komponen terverifikasi, checklist PRD §8 terpenuhi

- [ ] **Step 1: Screenshot semua 13 halaman secara berurutan**

  Jalankan `screenshot` pada setiap halaman. Simpan referensi nama halaman vs hasil screenshot.

- [ ] **Step 2: Verifikasi checklist PRD §8**

  - [ ] File FigCraft berisi 13 halaman
  - [ ] 23 komponen (14 atom + 9 molekul) tersimpan di Component Library
  - [ ] Semua tombol sentuh ≥ 44×44 px
  - [ ] Palet warna sesuai 8 token dari PRD §3.2
  - [ ] Screenshot terbaca di resolusi 960×540
  - [ ] Nol kode GDScript ditulis
  - [ ] Panduan export tersedia di halaman Design Tokens

- [ ] **Step 3: Catat temuan di MILESTONES.md**

  Tambahkan entri Fase 21–24 sebagai COMPLETED di `C:\Users\Hype GLK\hearthwood-rimba\MILESTONES.md`.

- [ ] **Step 4: Save final FigCraft file**

---

*Plan ini mengimplementasikan PRD 0.4.0 secara eksklusif via FigCraft MCP. Tidak ada GDScript. Eksekusi dimulai dari Task 1 dan dilanjutkan berurutan karena setiap task menghasilkan komponen yang dipakai task berikutnya.*
