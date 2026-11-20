# PRD: Hearthwood: Warung Rimba (Versi 0.7.0)

**Status:** Draf Lengkap untuk Persetujuan  
**Tanggal:** 2026-11-20  
**Versi Target:** 0.7.0 — Ekspansi Desa Hearthwood (Tata Kota, Fasilitas, & Dinamika Warga)  
**Berdasarkan:** PRD v0.4.0, PRD v0.6.0, ARCHITECT.md, DESIGN.md, AGENTS.md, MILESTONES.md  
**Dependen:** Seluruh sistem v0.6.0 (`World.gd`, `InteractiveProp.gd`, `GameState.gd`, `SaveSystem.gd`)

---

## 1. Ringkasan Eksekutif

Setelah pembaruan Versi 0.6.0 berhasil membangun 6 wilayah rimba menjadi ekosistem tematik yang hidup, fokus permainan kini beralih ke pusat peradaban: **Desa Hearthwood**.

Saat ini, wilayah desa (`Rect2(560.0, 0.0, 1040.0, 880.0)`) masih berupa satu bidang tanah lapang datar dengan tiga kotak bangunan sederhana (Toko Giral, Toko Talia, dan Warung Pemain). Tokoh Kepala Desa Veral belum memiliki kantor Balai Desa yang layak, belum ada pusat perkumpulan warga, dan 32 NPC ambient masih berkeliaran acak tanpa pola sosial yang meyakinkan.

**Versi 0.7.0** menghadirkan **Ekspansi Penuh Desa Hearthwood**. Pembaruan ini mengubah desa menjadi pemukiman abad pertengahan (*cozy medieval settlement*) yang hangat, berstruktur, dan ramai, melalui:
1. **Penataan 4 Distrik Terbuka Tanpa Loading (Opsi A):**
   - *Distrik Alun-Alun & Pasar Desa (Town Square & Market)*
   - *Distrik Balai Desa & Administrasi (Town Hall & Civic Center)*
   - *Distrik Warung Rimba & Dapur Pemain (Player's Hearth & Tavern)*
   - *Distrik Pemukiman Warga & Lumbung Komunal (Residential & Granary)*
2. **Landmark & Arsitektur Bangunan Lengkap (Semuanya Masuk):** Balai Desa megah berpilar kayu, fasad toko Giral & Talia dengan atap kanopi kanvas pedagang, sumur desa tua, lumbung komunal, pondok hunian warga tetap, dan warung makan yang berevolusi.
3. **Interaktivitas Lingkungan Desa Baru:**
   - **Sumur Desa Tua (*Village Well*):** Menimba air bersih segar untuk kebutuhan memasak dan membasuh muka.
   - **Papan Pengumuman Desa (*Notice Board*):** Papan kayu berisi kabar harian desa, tips memasak, dan petunjuk selera makanan warga hari itu yang berganti setiap hari.
4. **Dinamika Sosial & Clustering Warga:** NPC ambient memiliki pola rutinitas harian yang realistis: berbelanja di pasar pada pagi hari, bersantai di alun-alun pada siang hari, dan berkumpul di warung makan pemain pada sore/malam hari.

---

## 2. Tujuan dan Non-Tujuan

### 2.1 Tujuan Utama
1. **Pembangunan 4 Distrik Tematik:** Menata ulang seluruh lanskap desa dalam kanvas `560.0 <= x <= 1600.0` dan `0.0 <= y <= 880.0` dengan jalan setapak batu bertaut, pagar kayu desa, dan lampu jalan lentera.
2. **Pembangunan Fisik Fasad Bangunan Desa:**
   - Balai Desa (kantor Kepala Desa Veral).
   - Pemugaran visual toko Giral (Kelontong) dan Talia (Perkakas).
   - Lumbung padi / gudang komunal desa.
   - Deretan fasad rumah hunian NPC warga tetap.
   - Penataan area Warung Rimba pemain (tungku masak, meja saji, dan ranjang tidur).
3. **Implementasi Dua Objek Interaktif Desa:**
   - `HearthwoodVillageWell` (Sumur Desa): Memberikan air bersih / pemulihan energi ringan.
   - `HearthwoodNoticeBoard` (Papan Pengumuman): Menampilkan warta harian dan petunjuk afeksi NPC harian.
4. **Sistem Klaster Dinamis NPC Ambient (Crowd Clustering):** Mengelompokkan 32 NPC ambient agar bergerak dan berkumpul sesuai jam aktivitas desa tanpa melanggar batas isolasi desa (`x >= 560.0`).
5. **Zero Broken Tests:** Menjaga 100% kelulusan seluruh 25 test suite eksisting di Godot (terutama alur prolog tutorial di `MainGameFlowTest.gd`, dialog Veral, dan jadwal toko pedagang).

### 2.2 Non-Tujuan (Ditunda ke Fase Selanjutnya)
- **Interior Bangunan yang Dimasuki (Interior Scenes):** Bangunan di v0.7.0 tetap menggunakan pendekatan fasad eksterior terbuka ala game RPG klasik cozy (interaksi dilakukan di teras/loket/pintu).
- **Sistem Kriminalitas / Penjaga Desa:** Tetap mempertahankan suasana damai tanpa hukum keras atau sistem denda.
- **Ekspansi Warung Tier 5:** Batas warung tetap mengacu pada Tier 1–4 yang sudah ada.

---

## 3. Peta & Spesifikasi 4 Distrik Desa Hearthwood

Seluruh desa berada dalam koordinat `Rect2(560.0, 0.0, 1040.0, 880.0)` dan terhubung langsung dengan gerbang Pintu Rimba (`forest_zone_1`) di sisi barat daya (`x = 565.0, y = 440.0`).

```
========================================================================================
[ Hutan Rimba ] |                           DESA HEARTHWOOD
                |
                |  [ Distrik 1: Pasar & Toko ]           [ Distrik 2: Balai Desa ]
                |  - Toko Giral (970, 246)               - Balai Desa Veral (1350, 260)
                |  - Toko Talia (1102, 246)              - Tiang Bendera Hearthwood
                |  - Kios Kanvas & Peti Dagang           - Taman Bunga & Bangku
                |
  ◄─ GERBANG    |-----------------------------------------------------------------------
     RIMBA      |
 (565, 440)     |  [ PUSAT ALUN-ALUN ]                   [ Distrik 3: Warung Rimba ]
                |  - Sumur Desa Tua (1050, 460)          - Warung Pemain (1268, 380)
                |  - Papan Pengumuman (1130, 460)        - Tungku Masak (1210, 478)
                |  - Lampu Lentera & Plaza Batu          - Pondok & Ranjang (1320, 476)
                |
                |-----------------------------------------------------------------------
                |
                |  [ Distrik 4: Pemukiman & Kebun ]
                |  - Rumah Warga (Casha, Jev & Gil, Pak Udin, Siti, Budi, Arin)
                |  - Lumbung Padi Komunal (700, 680)
                |  - Pagar Kayu & Kebun Sayur Warga (780, 720)
========================================================================================
```

---

### 3.1 Distrik 1: Alun-Alun & Pasar Desa (Market & Plaza)
- **Koordinat Wilayah:** Sekitar `Rect2(850.0, 180.0, 350.0, 360.0)`
- **Fungsi Utama:** Pusat ekonomi dan titik temu warga desa.
- **Elemen Bangunan & Dekorasi:**
  - **Toko Kelontong Giral (`Rect2(970, 246, 92, 72)`):** Fasad kayu dengan kanopi kain garis-garis krem-merah terakota (`#B8482D` & `#F5F5DC`), karung beras, dan keranjang gandum di beranda.
  - **Toko Perkakas Talia (`Rect2(1102, 246, 92, 72)`):** Fasad bengkel kayu-batu dengan gantungan perkakas besi, tong kayu, dan caping anyaman di dinding.
  - **Plaza Batu Bundar:** Lantai batu paving bulat yang menghubungkan toko dengan alun-alun tengah.

---

### 3.2 Distrik 2: Balai Desa & Administrasi (Civic Center)
- **Koordinat Wilayah:** Sekitar `Rect2(1260.0, 180.0, 320.0, 220.0)`
- **Fungsi Utama:** Pusat pemerintahan desa dan tempat Kepala Desa Veral bertugas.
- **Elemen Bangunan & Dekorasi:**
  - **Gedung Balai Desa (*Town Hall*):** Bangunan terbesar di desa dengan dinding papan kayu plitur rapi (`#76513A`), atap sirap pelana ganda (`#5C3A1E`), pilar kayu berukir, dan pintu ganda berengsel besi.
  - **Tiang Bendera Desa:** Mengibarkan panji Hearthwood berwarna hijau daun sage (`#8FBC8F`) dan lambang sendok kayu emas (`#CD853F`).
  - **Taman Bunga Balai Desa:** Petak bunga warna-warni tepi jalan setapak menuju balai desa.
  - **Posisi Veral:** Berdiri di teras depan Balai Desa (`Vector2(1390.0, 342.0)`), menjaga kompatibilitas penuh dengan tutorial prolog.

---

### 3.3 Distrik 3: Warung Rimba & Dapur Pemain (Player's Tavern)
- **Koordinat Wilayah:** Sekitar `Rect2(1150.0, 360.0, 380.0, 280.0)`
- **Fungsi Utama:** Tempat pemain menjalankan usaha kuliner, memasak resep, melayani tamu, dan beristirahat.
- **Elemen Bangunan & Dekorasi:**
  - **Bangunan Warung Pemain (`Rect2(1268, 380, 104, 76)`):** Bangunan yang berevolusi sesuai tier warung (Kaki lima kayu sederhana di Tier 0 hingga Warung Kayu Besar di Tier 3/4).
  - **Stasiun Tungku Masak (`Vector2(1210, 478)`):** Tungku batu dengan kuali tembaga dan bara api hangat.
  - **Area Makan Pelanggan:** Deretan meja panjang dan bangku kayu di beranda warung.
  - **Pondok Tidur & Ranjang (`Vector2(1320, 476)`):** Ranjang beratap tempat pemain tidur untuk berganti hari dan memulihkan energi.

---

### 3.4 Distrik 4: Pemukiman Warga & Lumbung Komunal (Residential District)
- **Koordinat Wilayah:** Sekitar `Rect2(600.0, 540.0, 850.0, 300.0)`
- **Fungsi Utama:** Kawasan tempat tinggal penduduk desa dan area pertanian agraris komunal.
- **Elemen Bangunan & Dekorasi:**
  - **Deretan Rumah Penduduk:**
    - Rumah Pondok Casha & Vea (nuansa herbal/bunga).
    - Rumah Pondok Jev & Gil (nuansa pemburu/petualang).
    - Pondok Pak Udin & Siti (nuansa pedesaan klasik).
  - **Lumbung Padi Komunal (*Village Granary*):** Bangunan panggung kayu bertiang tinggi penahan tikus dengan dinding bambu/kayu rapat.
  - **Petak Sayur Komunal:** Bedeng tanah gembur berpagar kayu renggang tempat warga desa merawat kebun bersama.

---

## 4. Mekanik Interaktivitas Lingkungan Desa Baru

Dua objek interaktif khas pemukiman dihadirkan untuk melengkapi atmosfer pedesaan:

### 4.1 Sumur Desa Tua (`HearthwoodVillageWell`)
- **Lokasi:** Terletak di tengah Plaza Alun-Alun (`Vector2(1050.0, 460.0)`).
- **Bentuk Visual:** Cincin batu bata bundar dengan tiang kayu penyangga, atap sirap pelindung, roda katrol timba, dan ember kayu menggantung.
- **Mekanik Interaksi:**
  - Dekati sumur dan tekan `E` / sentuh tombol aksi.
  - Memutar animasi timba berputar dan suara gemericik ember terangkat (`sfx_well_draw`).
  - **Efek:** Memberikan **1 ember Air Bersih (`air_bersih`)** ke dalam inventori pemain (1x per hari) DAN memulihkan **+5 energi**.
  - **Batas Harian:** 1 kali per hari (reset otomatis saat pergantian hari/tidur).
  - Jika diinteraksi kembali pada hari yang sama: menampilkan dialog *"Air sumur masih tenang beriak di kedalaman. Kamu sudah mengambil air untuk hari ini."*

### 4.2 Papan Pengumuman Desa (`HearthwoodNoticeBoard`)
- **Lokasi:** Di samping jalan utama dekat Sumur Desa (`Vector2(1130.0, 460.0)`).
- **Bentuk Visual:** Papan kayu berkaki dua beratap kecil dengan tempelan kertas-kertas perkamen pengumuman beraneka warna dan segel lilin merah.
- **Mekanik Interaksi:**
  - Tekan `E` / tombol aksi untuk membaca.
  - Menampilkan modal dialog perkamen berisi **Warta Desa Hari Ini**:
    1. **Prakiraan Cuaca & Suasana Hari Ini:** Informasi cuaca saat ini (Cerah, Berawan, Hujan).
    2. **Gosip Selera Makanan Hari Ini (*Daily Craving Hint*):** Satu petunjuk acak tentang makanan yang sedang sangat diinginkan oleh salah satu NPC (contoh: *"Pak Udin terlihat memandangi warung sambil bergumam ingin menyantap masakan ikan bakar..."*).
    3. **Pesan Kepala Desa / Tips Memasak:** Catatan kecil dari Veral atau tips kombinasi bahan masakan.
  - Tidak memiliki batas interaksi harian (dapat dibaca ulang kapan saja).

---

## 5. Dinamika Kehidupan & Jam Aktivitas Warga (Ambient Crowd Clustering)

Saat ini, 32 NPC ambient berkeliaran acak tanpa pola di seluruh desa. Di v0.7.0, pergerakan ambient NPC diatur berdasarkan **sistem waktu harian (`TimeSystem`)**:

| Rentang Jam | Suasana & Perilaku Warga | Area Titik Kumpul Utama |
|-------------|--------------------------|-------------------------|
| **06.00 – 08.00 (Fajar)** | Warga mulai keluar rumah, menyiram tanaman, dan membuka jendela. | Menyebar di kawasan pemukiman (Distrik 4). |
| **08.00 – 12.00 (Pagi)** | Pasar desa dibuka! Warga berbondong-bondong belanja bahan pokok dan perkakas. | **Klaster Pasar (Distrik 1):** Depan toko Giral & Talia. |
| **12.00 – 16.00 (Siang)** | Jam istirahat siang. Warga bersantai, mengobrol di dekat sumur, dan urusan administrasi. | **Klaster Alun-Alun (Distrik 1 & 2):** Sekitar sumur dan Balai Desa. |
| **16.00 – 20.00 (Sore/Malam)** | Waktu makan malam! Warga berkumpul mencium aroma masakan dari warung pemain. | **Klaster Warung Rimba (Distrik 3):** Depan beranda meja makan pemain. |
| **20.00 – 06.00 (Malam Hari)** | Desa tenang. Lentera jalanan menyala temaram, warga kembali ke pondok masing-masing. | Menyebar tenang di dekat pondok hunian (Distrik 4). |

*Catatan Teknis:* Sekitar 8 NPC ambient tetap diset sebagai pengelana bebas (*free wanderers*) yang menjelajahi jalan setapak desa sepanjang hari untuk menjaga variasi dinamis.

---

## 6. Desain Teknis & Arsitektur Implementasi

### 6.1 Struktur Data & File Baru
- `data/world/village_zones.json`: Menyimpan metadata distrik, posisi landmark fasad bangunan, sumur desa, papan pengumuman, dan titik kumpul klaster NPC harian.
- `scripts/world/VillageWell.gd`: Turunan dari `HearthwoodInteractiveProp` untuk mekanik sumur desa.
- `scripts/world/NoticeBoard.gd`: Turunan dari `HearthwoodInteractiveProp` untuk membuka dialog warta harian desa.
- `data/items/items.json`: Menambahkan item `air_bersih` (bahan pelarut sup/masakan).

### 6.2 Integrasi di `World.gd`
- Memperluas fungsi `_draw()` untuk menggambar fasad Balai Desa, toko Giral & Talia yang dipercantik, deretan rumah warga, dan lumbung padi dengan collider solid yang presisi.
- Menambahkan fungsi pembaruan klaster ambient NPC: `_update_ambient_npc_clustering(hour: int)` yang dipicu oleh sinyal `time_system.hour_changed`.
- Memastikan batas minimum koordinat `x >= 560.0` tetap berlaku ketat agar tidak ada satu pun warga desa yang melanggar batas isolasi rimba.

### 6.3 Kompatibilitas Penuh Kontrak Pengujian
- Koordinat Veral di `Vector2(1390.0, 342.0)` tetap menjadi titik temu di depan Balai Desa (`MainGameFlowTest.gd`).
- Posisi Cooking Station di `(1210.0, 478.0)` dan Bed di `(1320.0, 476.0)` tetap bebas halangan (`MainGameFlowTest.gd`).
- Seluruh 32 NPC ambient tetap berada di koordinat `x >= 560.0` (`ForestNPCIsolationTest.gd`).
- Status harian sumur desa terintegrasi dengan array `interacted_props_today` di `GameState` dan tersimpan di `SaveSystem` (`ZoneStateSaveTest.gd`, `SaveSystemTest.gd`).

---

## 7. Definition of Done (DoD) Versi 0.7.0

- [ ] Seluruh 4 distrik desa Hearthwood tertata rapi dengan jalan setapak batu, lampu lentera, dan pagar kayu desa.
- [ ] Balai Desa megah berdiri di Distrik 2 dan Veral berdiri di teras depan Balai Desa.
- [ ] Toko Giral dan Toko Talia memiliki fasad kanopi pedagang dan tanda pengenal yang jelas.
- [ ] Deretan rumah hunian warga dan lumbung padi komunal terwujud di Distrik 4.
- [ ] Sumur Desa dapat diinteraksikan untuk menimba air bersih (+5 energi, 1x per hari) dan ter-reset harian.
- [ ] Papan Pengumuman Desa dapat dibaca untuk melihat informasi cuaca dan gosip makanan favorit warga hari itu.
- [ ] Pola pergerakan 32 NPC ambient mengikuti jadwal klaster pasar pagi, alun-alun siang, dan warung malam.
- [ ] Seluruh 25 test suites eksisting di Godot lulus 100% tanpa galat.
