# PRD Hearthwood: Warung Rimba (Versi 0.8.0)
## Sekuens Prolog Pembuka & Pengalaman Pelayanan Meja Warung Makan (*Dine-In Table Service*)

**Versi Dokumen:** 0.8.0  
**Tanggal:** 20 November 2026  
**Status:** Draf Usulan untuk Persetujuan  
**Landasan Dokumen:** `PRD Hearthwood Warung Rimba (Versi Awal).md`, `PRD Hearthwood Warung Rimba (Versi 0.7.0).md`, `PRODUCT.md`, `DESIGN.md`, `ARCHITECT.md`

---

## 1. Latar Belakang & Ringkasan Fitur

Pada versi sebelumnya (v0.6.0 & v0.7.0), dunia fisik Hearthwood telah diperluas menjadi ekosistem yang utuh: 6 zona hutan rimba yang kaya akan foraging dan landmark tematik, serta desa yang tertata rapi dalam 4 distrik (Pasar, Balai Desa, Warung Pemain, dan Pemukiman Warga).

Namun, ada dua aspek krusial yang perlu dihadirkan untuk meningkatkan kenikmatan bermain (*player immersion* & *gameplay loop*):
1. **Sekuens Prolog Pembuka (*Opening Cinematic Prologue*)**: Saat memulai permainan baru, pemain saat ini langsung berdiri di tengah hutan tanpa konteks pembuka. Sesuai premis asli di PRD Awal, pemain adalah pemilik warteg lokal di Indonesia yang tewas sesak napas akibat kebakaran gudang tertutup, lalu terbangun secara tak terduga di bawah pohon purba dunia fantasi. Momen naratif ini harus divisualisasikan secara dramatis dan hangat.
2. **Pengalaman Pelayanan Meja Warung (*Dine-In Table Service Loop*)**: Inti identitas game ini adalah "Warung Rimba". Saat ini, interaksi warung hanya berupa jendela upgrade tier dan dialog interaksi individu. Versi 0.8.0 menghadirkan sesi nyata di mana pemain dapat membuka warung makan mereka di jam sore/malam, pelanggan berdatangan dan duduk di meja warung, memesan hidangan dengan balon pesanan (*order bubble*), pemain menyajikan makanan dari stok inventori, menerima koin serta reputasi, dan melihat rekapitulasi harian.

---

## 2. Fitur 1: Sekuens Prolog Pembuka (*Opening Prologue*)

### 2.1 Alur Naratif & Pementasan Adegan
Ketika pemain menekan tombol **"Mulai Permainan Baru"** di `MainMenu.gd` dan mengisi nama pengelana:

```
[Main Menu: Mulai Permainan Baru]
               ↓
[Fase 1: Layar Gelap & Monolog Warteg Asal]
  - Latar hitam gulita (#0A0908)
  - Teks muncul bertahap (typewriter effect) dengan tombol sentuh lanjut
  - Mengisahkan pemilik warteg yang terjebak asap di gudang tertutup
               ↓
[Fase 2: Transisi Ambience Antara Dua Dunia]
  - Suara hening kota berganti desau angin sejuk & gemerisik dedaunan
  - Aroma tanah basah dan rasa hangat menembus kesadaran
               ↓
[Fase 3: Mengerjap Bangun di Bawah Pohon Raksasa (Blinking Eyes)]
  - Efek kelopak mata mengerjap 2 kali perlahan
  - Membuka pandangan ke kanopi hijau rimbun Suaka Pohon Raksasa (Zona 6)
  - Monolog heran: "Di mana ini...? Ini bukan gudang wartegku..."
               ↓
[Gameplay Dimulai di Vector2(100.0, 1180.0)]
  - Pemain berdiri dari bawah pohon, alur prolog tutorial bersama Rast dimulai
```

### 2.2 Naskah Dialog & Monolog Prolog (`data/quests/opening_prologue.json`)
Monolog disimpan dalam format data-driven JSON terpisah:
```json
{
  "monologues": [
    {
      "id": "intro_1",
      "text": "Namaku {player_name}. Di duniaku dulu, aku mengelola warteg kecil yang ramai di sudut kota...",
      "audio_hint": "city_fade"
    },
    {
      "id": "intro_2",
      "text": "Hari itu, saat sedang mengecek karung beras dan stok bumbu di gudang belakang... bau asap pekat tiba-tiba menyengat hidung.",
      "audio_hint": "smoke_choke"
    },
    {
      "id": "intro_3",
      "text": "Pintu depan terkunci rapat. Tak ada jendela, tak ada celah ventilasi. Nafasku sesak, pandanganku perlahan menggelap ditelan kepulan asap...",
      "audio_hint": "silence"
    },
    {
      "id": "intro_4",
      "text": "Apakah ini akhir dari segalanya...?",
      "audio_hint": "forest_wind"
    },
    {
      "id": "intro_5",
      "text": "Namun... perlahan kurasakan belaian angin sejuk. Aroma tanah basah, harum lumut, dan dedaunan liar...",
      "audio_hint": "forest_birds"
    }
  ],
  "awakening": {
    "text": "Aku mengerjapkan mata... Di atas kepalaku, kanopi pohon purba raksasa menjulang megah menembus langit.",
    "question": "Di mana ini...?! Ini jelas bukan gudang wartegku..."
  }
}
```

### 2.3 Kontrol & Aksesibilitas
- **Sentuh / Klik Layar**: Memajukan teks baris monolog secara alami.
- **Tombol "Lewati" (*Skip*)**: Terletak di pojok kanan atas, ukuran minimal 48×48 px dengan label jelas, memungkinkan pemain langsung melompati sekuens pengantar menuju gameplay awal (sangat berguna untuk pemain veteran atau automated testing).

---

## 3. Fitur 2: Pengalaman Pelayanan Meja Warung Makan (*Dine-In Table Service*)

### 3.1 Tata Ruang Fisik Warung Makan
Di Distrik Warung Pemain (`World.gd`), area teras warung dilengkapi dengan fasilitas perabot makan:
- **Meja Makan & Kursi Warung (`WarungTable`)**:
  - Disediakan 2 meja pada Tier 1, 3 meja pada Tier 2, 4 meja pada Tier 3 & 4.
  - Setiap meja terdiri dari meja kayu rustic, 2 bangku kayu, dan taplak meja kanvas.
- **Lonceng / Papan Operasional Warung (`WarungSign`)**:
  - Terletak di beranda depan warung (`Vector2(1170.0, 470.0)`).
  - Digunakan pemain untuk membuka dan menutup sesi pelayanan tamu.

### 3.2 Siklus Sesi Pelayanan (*The Service Rush*)
- **Jam Operasional**: Warung dapat dibuka antara pukul **16:00 hingga 21:00** (waktu warga mencari santap sore & makan malam).
- **Prasyarat Buka Warung**: Pemain memiliki setidaknya **1 porsi masakan matang** di inventori.
- **Alur Pelayanan Meja**:
  1. **Kedatangan Tamu**: Pelanggan yang tersedia (sesuai tier warung dan jadwal NPC) masuk ke warung, memilih meja kosong, dan duduk.
  2. **Balon Pesanan (*Order Bubble*)**: Di atas kepala tamu muncul balon pesanan animasi mengambang yang menampilkan:
     - Ikon makanan yang diinginkan (berdasarkan selera NPC: makanan suka/favorit yang sudah di-unlock pemain).
     - Indikator kesabaran visual (lingkaran progress bar bernuansa kayu/hijau santai, berkurang sangat perlahan, tidak menimbulkan stres).
  3. **Penyajian Masakan**:
     - Pemain menghampiri meja tamu dan menekan tombol interaksi sentuh **"Sajikan [Nama Masakan]"**.
     - Jika pemain memiliki masakan tersebut di inventori:
       - Masakan diserahkan ke meja.
       - Pelanggan merespons gembira (*emote uap harum* atau *bintang*).
       - Pelanggan menikmati makanan selama 4–6 detik game time.
     - Jika pemain kehabisan stok masakan:
       - Pemain dapat langsung melangkah ke stasiun memasak (`CookingStation`) yang berada tepat di samping meja untuk memasak hidangan secara instan/mini-game, lalu kembali menyajikannya.
  4. **Pembayaran & Tip**:
     - Setelah selesai makan, tamu beranjak pergi meninggalkan kantong koin di atas meja:
       $$\text{Total Koin} = \text{Harga Dasar Masakan} + \text{Bonus Kualitas Bintang} + \text{Tip Kedekatan Hati}$$
     - Pemain mengambil koin dan membersihkan piring meja. Meja kembali berstatus kosong untuk tamu berikutnya.

### 3.3 Laporan Harian Warung (*Daily Warung Summary Modal*)
Ketika jam mencapai 21:00 (atau pemain menutup warung lebih awal, atau seluruh kapasitas harian habis):
- Muncul modal bergaya kartu kayu pergamen: **"Warta Penjualan Warung Hari Ini"**.
- Menampilkan metrik:
  - Total tamu terlayani / kapasitas maksimal.
  - Total koin yang diperoleh hari ini.
  - Poin reputasi warung yang bertambah.
  - Catatan komentar hangat dari salah satu pelanggan (misal: *"Sup sayur beningnya sungguh menghangatkan tubuh setelah seharian di ladang!"*).

---

## 4. Skema Data & Komponen Teknis

### 4.1 Komponen Baru
1. `scenes/ui/PrologueSequence.tscn` & `scripts/ui/PrologueSequence.gd`:
   - CanvasLayer untuk memutar sekuens pembuka dengan typewriter text, tombol lewati, dan efek eye-blink fade.
2. `scripts/world/WarungTable.gd`:
   - Node2D / Area2D penanda meja makan dengan status meja, sprite kursi/meja, posisi duduk NPC, dan balon pesanan.
3. `scripts/ui/OrderBubble.gd`:
   - Komponen UI mengambang di atas meja/NPC menampilkan ikon masakan pesanan.
4. `scripts/ui/WarungReportUI.gd`:
   - Modal rekapitulasi harian sesi warung makan.

### 4.2 Penyesuaian Komponen Eksisting
- `scripts/ui/MainMenu.gd`: Mengarahkan tombol "Mulai Permainan Baru" memutar `PrologueSequence` sebelum berpindah ke `Main.tscn`.
- `scripts/systems/WarungSystem.gd`: Memperluas logika dari sekadar pengecekan pasif menjadi pengendali sesi aktif (*is_service_open*, *active_tables*, *daily_earnings*).
- `scripts/world/World.gd`: Menempatkan instance `WarungTable` di Distrik Warung Pemain.

---

## 5. Rencana Pengujian Otomatis (Unit & Integration Tests)

Untuk menjaga rekor 100% lulus tanpa regresi, ditambahkan 3 suite tes baru:
1. `tests/PrologueSequenceTest.gd`:
   - Menguji pemuatan naskah `opening_prologue.json`.
   - Menguji transisi typewriter text antar baris monolog.
   - Menguji fungsi tombol "Lewati" yang langsung memposisikan pemain di bawah pohon suaka (`Vector2(100.0, 1180.0)`).
2. `tests/WarungDineInTest.gd`:
   - Menguji siklus pembukaan warung pada jam 16:00–21:00.
   - Menguji pelanggan yang menempati meja dan memunculkan pesanan yang valid.
   - Menguji transaksi penyajian makanan dari inventori ke meja pelanggan.
   - Menguji perhitungan koin, tip afeksi, dan reputasi.
3. `tests/SaveSystemTest.gd` & Regresi Keseluruhan:
   - Memastikan seluruh 30 unit test eksisting tetap lulus hijau (exit code 0).
   - Memastikan save/load tetap stabil dan backward-compatible.

---

## 6. Checklist Definition of Done Versi 0.8.0

- [ ] Data naskah prolog tersimpan di `data/quests/opening_prologue.json` (data-driven, bebas hardcode).
- [ ] Sekuens pembuka berjalan estetik saat klik "Mulai Permainan Baru", lengkap dengan tombol Lewati (*Skip*).
- [ ] Transisi kelopak mata mengerjap memunculkan kanopi Suaka Pohon Raksasa secara mulus.
- [ ] Meja makan warung terpasang di Distrik Warung Pemain dengan collider dan area interaksi sentuh ergonomis.
- [ ] Pelanggan warung dapat duduk, memesan makanan dengan balon pesanan, dan menikmati hidangan.
- [ ] Pemain dapat menyajikan hidangan dari stok inventori atau memasak langsung di samping meja.
- [ ] Modal laporan penjualan harian muncul saat warung tutup dengan rincian koin dan reputasi.
- [ ] Seluruh unit test (33 suite total) lulus 100% hijau di Godot 4.7.2 headless.
