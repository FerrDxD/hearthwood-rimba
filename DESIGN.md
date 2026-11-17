# DESIGN.md — Hearthwood: Warung Rimba

Dokumen desain visual, UI/UX, dan game design untuk versi awal. Semua keputusan didasarkan pada PRD (`PRD Hearthwood Warung Rimba (Versi Awal).md`).

---

## 1. Arah Gaya Visual

| Aspek | Keputusan |
|-------|-----------|
| Genre visual | 2D piksel, kamera top-down |
| Arah utama | Cozy, ala Citampi Stories |
| Budaya dunia | Fantasi Eropa abad pertengahan |
| Suasana | Adem ayem, hangat, humor halus |
| Texture filter | Nearest |
| Pixel snap | Aktif |
| Ukuran tile | 16x16 atau 32x32 (ditentukan saat implementasi) |

---

## 2. Palet Warna

Palet dirancang untuk suasana cozy dan hangat, dengan variasi lewar warna pada satu tileset utama.

### Warna Dasar (Primitif)

| Nama | HEX | Digunakan untuk |
|------|-----|-----------------|
| Langit Pagi | #87CEEB | Langit pagi dan siang |
| Langit Malam | #2C3E50 | Langit malam (18:00–22:00) |
| Tanah Hutan | #8B4513 | Tanah, jalan hutan |
| Rumah Desa | #D2B48C | Dinding bangunan desa |
| Hiasan Warung | #8FBC8F | Aksen warung pemain |
| UI Latar | #F5F5DC | Latar kotak dialog, menu |
| UI Teks | #333333 | Teks utama |
| Aksen Utama | #CD853F | Tombol, highlight, aksen UI |

### Palet NPC (Variasi Warna)
Setiap NPC manusia berlapis menggunakan palet yang sama dengan variasi warna rambut, baju, dan celana:

| Warna Rambut | HEX | Warna Baju | HEX | Warna Celana | HEX |
|--------------|-----|------------|-----|--------------|-----|
| Coklat | #8B4513 | Coklat kehijauan | #556B2F | Coklat tua | #654321 |
| Hitam | #2F2F2F | Abu-abu | #808080 | Abu-abu tua | #555555 |
| Blonde | #DAA520 | Biru tua | #4682B4 | Abu-abu muda | #A9A9A9 |
| Merah tua | #A52A2A | Merah muda | #DB7093 | Hijau tua | #2F4F4F |

---

## 3. Desain Karakter Utama (MC)

Dari PRD bagian 6.1:
- **Gender:** Laki-laki
- **Penampilan:** Pria muda, rambut coklat pendek, baju warteg berwarna coklat kehijauan dengan celana coklat tua dan sepatu sederhana
- **Tampilan tetap** (tidak bisa dikustomisasi pemain di v1.0)
- **Nama:** Dikustomisasi pemain (`[nama player]`)

### Sprite Berlapis MC
- Lapisan 1: Rambut coklat pendek
- Lapisan 2: Wajah (ekspresi ceria, sarkastik)
- Lapisan 3: Baju warteg coklat kehijauan
- Lapisan 4: Celana coklat tua
- Lapisan 5: Sepatu sederhana (coklat muda)

---

## 4. Desain NPC

### 9 NPC Bernama + Rast dan Veral

Setiap NPC memiliki:
- Sprite manusia berlapis dengan variasi warna
- Ciri khas visual (barang yang dipakai)
- 2 dialog (dialog 1: pertemuan awal, dialog 2: setelah progres)

#### Tabel Visual NPC

| Nama | Ciri Khusus Visual | Warna Dominan | Lokasi Biasa |
|------|-------------------|---------------|--------------|
| Giral | Keranjang bambu sayuran | Hijau tua, coklat | Toko bahan (07:00–12:00) |
| Talia | Palu besi kecil di pinggang | Abu-abu, besi | Toko perkakas (13:00–18:00) |
| Casha | Adonan kue di tangan | Merah muda, putih | Toko kue desa |
| Vea | Jarum jahit dan kain | Ungu muda, krem | Penenun desa |
| Nue | Tawa cepat, santai | Biru muda, abu-abu | Penginapan |
| Jev | Tombak di bahu, tegang | Abu-abu tua, besi | Gerbang desa |
| Gil | Tongkat kayu, tradisional | Coklat, hijau tua | Petani |
| Rave | Palu besar, keras | Merah tua, hitam | Pandai besi |
| Kila | Lincah, kecil | Kuning muda, hijau | Anak-anak desa |
| Rast | Remi atau tali di pinggang | Coklat, hijau | Hutan, jalan pulang |
| Veral | Tongkat tua, jubah | Abu-abu, biru tua | Rumah kepala desa |

### NPC Ambient (32 variasi)
- Tidak bisa diinteraksi
- Hanya jalan-jalan di peta
- Menggunakan satu set sprite manusia berlapis dengan variasi warna acak
- Tidak perlu sprite terpisah per orang

---

## 5. Desain UI/UX

### 5.1 Layar Utama (World)
- Kamera top-down, mengikuti pemain
- Tampilan jam dan hari di pojok layar (non-intrusif)
- Indikator energi di pojok lain
- Tombol interaksi besar saat berada di dekat objek interaktif

### 5.2 UI Memasak
```
┌─────────────────────────────┐
│  Resep: Sup Sayur Bening    │
│  ★★☆ (2 bintang dasar)      │
├─────────────────────────────┤
│  Alat: [Api unggun ▼]       │
│  Porsi: [1 ▼] (maks: 2)     │
│  Energi: −5 per porsi       │
├─────────────────────────────┤
│  Bahan: Sayur liar ✓        │
│  Garam ✓                    │
├─────────────────────────────┤
│  [ Mini-game timing opsional ]│
│  [ Masak ]                  │
└─────────────────────────────┘
```

### 5.3 UI Dialog NPC
- Kotak teks besar di bawah layar
- Nama NPC di pojok kiri kotak
- Tombol "Lanjutkan" (Next) besar
- Tampilkan hanya jika pemain berdiri di dekat NPC

### 5.4 UI Toko (Giral & Talia)
- Tampilkan hanya ketika toko buka (cek jam buka)
- Daftar barang dengan harga
- Diskon otomatis berdasarkan tingkat hati pedagang
- Tombol "Beli" dan "Batal"
- Katalog barang disimpan di `data/shops.json`; harga bahan dan saldo awal 100 koin adalah nilai awal yang bisa diseimbangkan karena PRD belum menetapkannya.
- Pembelian mengurangi koin dan mencatat jumlah barang agar hasil transaksi bisa dipakai sistem inventori Fase 4.

### 5.5 UI Inventori
- Grid item dengan ikon dan jumlah
- Tampilkan item yang bisa dimakan (dengan nilai energi)
- Tampilkan item masakan dengan tanggal (untuk hitung basi)
- Item hutan dapat dipungut saat dijelajahi dan tumbuh kembali setelah pemain tidur.
- Kartu item memakai warna dari katalog data; inventori dapat dibuka lewat tombol sentuh atau tombol `I`.

### 5.6 UI Menu Pause / Main Menu
- Tombol: Continue, New Game, Load Game, Settings, Exit
- Save otomatis saat tidur (tidak perlu save manual saat keluar)

---

## 6. Desain Layar (Wireframe Tekstual)

### Layar Hutan
```
┌─────────────────────────────────────┐
│  [Jam: 09:30]      [Hari: 3] [E: 85]│
│                                     │
│     🌳      🌳          🌳          │
│                                       │
│           👤 Pemain                  │
│                                       │
│     🌳      🌳      🌳      🌳        │
│                                     │
│  [Interaksi: Panoh pohon]          │
└─────────────────────────────────────┘
```

### Layar Toko Giral (Buka 07:00–12:00)
```
┌─────────────────────────────────────┐
│  TOKO Bahan — Giral              🕚  │
│                                     │
│  Sayur liar    10 koin  [Beli]      │
│  Ikan sungai   25 koin  [Beli]      │
│  ...                                │
│                                     │
│  Diskon: 5% (Hati 2)               │
└─────────────────────────────────────┘
```

### Layar Toko Talia (Buka 13:00–18:00)
```
┌─────────────────────────────────────┐
│  TOKO Perkakas — Talia           🕚  │
│                                     │
│  Pisau kecil   50 koin  [Beli]      │
│  Caping        30 koin  [Beli]      │
│  ...                                │
│                                     │
│  Diskon: 5% (Hati 2)               │
└─────────────────────────────────────┘
```

---

## 7. Desain Sound

| Jenis | Deskripsi | Kapan diputar |
|-------|-----------|---------------|
| Musik hutan | Cozy, akustik, tenang | Saat di hutan |
| Musik desa | Ringan, melodi sederhana | Saat di desa |
| Musik malam | Lebih tenang, slow | 18:00–22:00 |
| SFX memasak | Nyih, mendidih, irisan | Saat memasak |
| SFX interaksi | Klik halus | Saat berbicara NPC / interaksi tile |
| SFX tidur | Napas tenang | Saat pemain tidur |
| SFX naik hati | Suara lonceng kecil | Saat naik tingkat kedekatan |

---

## 8. Desain Progresi Visual Warung

| Tier | Visual Bangunan | Fitur Visual Baru |
|------|-----------------|-------------------|
| Gubuk (0) | Gubuk sederhana, atap rumput | Tanda warung sederhana |
| Warung Kecil (1) | Bangunan lebih besar, atap kayu | Meja di luar, tanda warung |
| Warteg Penuh (2) | Bangunan penuh, jendela, pintu | Kursi pelanggan, dapur terlihat |

---

## 9. Animasi (Ringan, Cozy)

| Aksi | Animasi |
|------|---------|
| Berjalan | 4 frame sprite (kaki bergerak) |
| Memasak | Gerakan tangan + efek uap |
| Tidur | Pemain terlihat tertidur di tempat tidur |
| Berbicara NPC | Munculnya kotak dialog, NPC bergerak sedikit |
| Naik hati | Efek hati kecil melayang |

---

## 10. Panduan Komposisi Layar (Android)

| Elemen | Posisi | Ukuran Minimal |
|--------|--------|----------------|
| Joystick virtual | Kiri bawah | 80×80 dp |
| Tombol interaksi | Kanan bawah | 60×60 dp |
| Kotak dialog | Bawah tengah | Lebar penuh, tinggi 1/6 layar |
| UI jam/hari | Kiri atas | Non-intrusif |
| UI energi | Kanan atas | Non-intrusif |

---

## 11. Catatan Desain

- Hindari elemen yang menakutkan atau horor (PRD non-tujuan: tidak ada unsur horor, mistis, atau makhluk gaib)
- Warna ceria dan hangat untuk mendukung suasana cozy
- UI harus sederhana, tidak memberatkan pemain
- Semua teks dalam bahasa Indonesia
- Placeholder nama pemain: `{nama}` di dialog

---

*Catatan: Dokumen ini adalah panduan desain. Detail implementasi visual dapat disesuaikan saat aset asli dibuat.*