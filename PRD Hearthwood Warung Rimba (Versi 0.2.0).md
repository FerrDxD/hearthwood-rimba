# PRD: Hearthwood: Warung Rimba (Versi 0.2.0)

**Status:** Draf awal untuk update versi 0.2.0  
**Tanggal:** Wed Nov 18 2026  
**Berdasarkan:** PRD Versi Awal, ARCHITECT.md, MILESTONES.md  
**Dependen:** Semua sistem v1.0 sudah lengkap (Fase 0-11)

---

## 1. Ringkasan

Update 0.2.0 adalah ekspansi dan penyempurnaan setelah v1.0 selesai. Fokus utama meliputi: **(1)** Implementasi main quest utama untuk Rast dan Veral yang telah ditunda, **(2)** Penambahan konten dan sistem baru, **(3)** Penyelesaian build target untuk rilis. Update ini membangun seluruh sistem yang sudah ada di v1.0 (waktu, NPC, memasak, afeksi, warung, save/load) dan memperluahnya dengan konten baru.

---

## 2. Tujuan Versi 0.2.0

### 2.1 Tujuan Utama (Keputusan)
- **Main quest Rast:** Mengimplementasikan kerangka quest hati 0-3 untuk penebang kayu, mulai dari bantuan di hutan hingga ekspedisi kayu untuk desa
- **Main quest Veral:** Mengimplementasikan kerangka quest hati 0-3 untuk kepala desa, mulai dari izin usaha hingga hubungan dengan kerajaan
- **Progresi cerita:** Menyambung alur dari hutan ke desa dan pembangunan warung ke tahap lanjutan
- **Misteri asap:** Memberikan tracks/penunjuk awal soal asap yang menyebabkan kematian tokoh utama (tidak sampai jawaban lengkap, hanya clue/pertanyaan)

### 2.2 Tujuan Sekunder (Usulan)
- **Resep baru:** Menambah 4-6 resep makanan baru dengan bahan yang dapat didapat dari hutan atau toko
- **NPC baru/tambahan:** 3-4 NPC baru dengan dialog dan sistem afeksi
- **Sistem cuaca (opsional):** Sistem cuaca sederhana yang memengaruhi kualitas masakan dan respons NPC
- **Build target:** Menhasilkan build Windows Desktop, Web/itch.io, dan Android AAB signing non-debug

### 2.3 Non-Tujuan (Bisa dilanjutkan di 0.3.0)
- Makhluk gaib atau ras fantasi lain
- Konflik besar atau perang
- Penjelasan dimensi/asal isekai secara eksplikasi
- Sistem ekonomi kompleks di luar warung

---

## 3. Referensi dan Arah Gaya

- **Arah utama:** Expansi dari cozy Citampi Stories ke alur cerita yang lebih kaya
- **Visual:** 2D piksel tetap, animasi minor untuk event quest
- **Referensi:** Melanjutkan dari referensi v1.0, dengan penekanan pada pengembangan karakter Rast dan Veral

---

## 4. Premis dan Cerita

### 4.1 Lanjutan Dari V1.0
Setelah pemain mendapat izin tinggal dan menetap di gubuk di pinggir desa (akhir v1.0), versi 0.2.0 memulai dari titik ini dengan:
- Pemain sudah memiliki gubuk kosong
- Sistem warung berjalan (gubuk → kecil → penuh)
- Sistem afeksi already active dengan NPC bernama
- Pemain bebas memasak dan berdagang di toko

### 4.2 Plot Utama 0.2.0

**Rast — Penebang Kayu (Quest Utama)**
- Hati 0: Rast butuh bantuan untuk membawa kayu ke keluarga → Pemain membantu kumpulkan dan membawa kayu
- Hati 1: Rast semakin berani → Ajak Rast ke depan warga desa, dialog tambahan, peningkatan kepercayaan diri
- Hati 2: Eksplorasi hutan dalam → Membantu Rast menembus area berbahaya di hutan, tempel markah, pulang selamat, dapat alat/item pertahanan
- Hati 3: Pengemisar kayu (Main Quest) → Rast memimpin ekspedisi kayu untuk desa → Kumpulkan banyak kayu → Bawa ke gubuk desa → Rakyat puas → Unlock fitur lanjutan (misalnya: gudang bahan, resep khusus)

**Veral — Kepala Desa (Quest Utama)**
- Hati 0: Izin usaha warteg → Veral butuh bantu administrasi → Kumpulkan dokumen/barang → Diberikan izin usaha awal + diskon Veral
- Hati 1: Mediasi warga → Veral butuh bantu menyelesaikan pertengkaran warga → Bicaralah ke kedua belah pihak → Laporkan kembali → Info besar soal desa + reputasi naik
- Hati 2: Rapar desa → Veral butuh masakan untuk rapat warga → Masak masakan spesial → Bawa ke rapat desa → Warga puas → Unlock area baru di desa (misalnya: sawah area, area pertanian)
- Hati 3: Hubungan kerajaan (Main Quest) → Veral butuh perwakilan desa ke kerajaan → Siapkan perwakilan → Perjalanan ke royaume → Pulang dengan berita → Main quest selesai, unlock fitur kingdom (perdagangan dengan kerajaan, misi khusus)

### 4.3 Misteri Asap (Clue Trail)
- Setiap kali pemain mencapai hati 3 dengan Rast atau Veral, ada teks narasi singkat soal asap
- clue 1: "Tulang kayu yang tidak biasa ditemui di hutan dalam" (dari quest Rast hati 2)
- clue 2: "Bercak asap di belakang gudang yang terbakar" (ditemui saat eksplorasi)
- clue 3: "Buku rahasia Veral yang membahas tentang geleger dari luar dimensi" (dari event khusus)
- Jawaban akhir tetap ditunda ke versi 0.3.0+, tetapi ada jejak narasi yang terpercaya

---

## 5. Mekanik Inti (Ditingkatkan dari V1.0)

### 5.1 Sistem Quest Utama (Baru)
- **Tracking hati quest:** Setiap NPC utama (Rast, Veral) memiliki tracking hati khusus quest
- **Objective tracker:** UI menampilkan objective quest saat ini di pojok layar
- **Quest completion trigger:** Selesaian quest memicu event cutscene/singkat dan unlock fitur
- **Quest log:** Diakses dari menu utama, menampilkan status quest Rast dan Veral

### 5.2 Resep Masakan Baru (Expansi)
Menambah 6 resep baru yang membutuhkan bahan dari progres quest:

| Resep | Alat minimum | Bahan utama | Suka NPC | Unlock lewat |
|-------|-------------|-------------|----------|--------------|
| **Sup Kaldu Kayu** | Tungku | Kayu + sayur liar | Rast | Quest Rast hati 2 |
| **Nasi Kuning Rempah** | Dapur warteg | Nasi + minyak + telur + rempah | Casha | Quest Veral hati 2 + beli rempah eksklusif |
| **Kue Coklat** | Dapur warteg | Buah liar + tepung + rempah khas | Kila | Dapat rempah eksklusif dari Giral |
| **Ikan Goreng Tegal** | Api unggun | Ikan sungai + akar rempah | Jev | Dapat ikan sungai dari hutan |
| **Sayur Tumis Pedas** | Tungku | Daun hutan + akar rempah + buah liar | Rave | Dapat semua bahan dari hutan |
| **Bubur Ayam Hutan** | Api unggun | Beras + telur + sayur liar | Vea | Default + bahan tambahan dari quest |

### 5.3 Sistem Cuaca (Baru, Opsional)
- Cuaca berubah setiap hari: Cerah, Hujan, Badai
- Pengaruh pada:
  - Bahan tumbuh ulang lebih cepat saat hujan
  - Kualitas masakan: zona hijau mini-game lebih besar saat cuaca cerah
  - Respons NPC: Beberapa NPC memiliki respons terhadap masakan sesuai cuaca (sup hangat saat hujan, dll.)
  - Jam buka toko: Beberapa toko bisa tutup pada cuaca buruk

### 5.4 Progresi Warung (Lanjutan Dari V1.0)
- Tier 4 (Baru): "Warung Besar" dengan ambang reputasi 40, biaya 3000 koin + 2 kayu + 1 batu
- Alat: dapur warteg level lanjutan
- Maks porsi: 8
- Pelanggan baru: 3 pelanggan khusus quest + pelanggan tetap v1.0
- Unlock: Area luar warung, taman tanam bahan

### 5.5 Sistem Afeksi (Ditingkatkan)
- Tambahan aturan pemberian spesial: saat cuaca tertentu atau saat NPC baru pulang dari quest
- Diskon akumulatif: hati 2 pedagang = 5%, hati 3 = 15% (tetap), hati 4 (baru) = 10% untuk semua pedagang
- Hadiah hati 4 (baru): Informasi dunia + resep rahasia

---

## 6. Karakter dan Konten Baru

### 6.1 NPC Utama (Quest)
- **Rast** dan **Veral** memiliki kerangka quest hati 0-3 dengan objective tracking
- Setiap hati mengembalikan dialog tambahan, hadiah, dan progres cerita

### 6.2 NPC Baru (4 orang)
1. **Arin — Pemangku benteng hutan**
   - Jadwal: 06.00–08.00 pagi
   - Sifat: Kegelawar, menjaga area hutan dalam
   - Suka: Masakan yang menggunakan bahan hutan langka
   - Tidak suka: Masakan terlalu modern/kota
   - Ciri khas: Memakai baju pemangku, membawa tangkong

2. **Budi — Seorang pedagang kaki**
   - Jadwal: Berjalan-jalan di desa, tidak punya jadwal tetap
   - Sifat: Ramah, sedikit aspek, selalu membawa berita
   - Suka: Masakan baru dan eksotis
   - Tidak suka: Masakan yang basi
   - Ciri khas: Memakai rok warna-warni, membawa tas raksasa

3. **Siti — Penyelam sungai**
   - Jadwal: 08.00–11.00, di area sekitar sungai
   - Sifat: Tenang, pemahaman dalam, suka sunyi
   - Suka: Ikan segar, masakan air
   - Tidak suka: Masakan terlalu pedas
   - Ciri khas: Memakai masker perairan, membawa mesh

4. **Pak Udin — Perokok (tidak disukai anak-anak)**
   - Jadwal: 15.00–17.00 sore
   - Sifat: Santai, cerita panjang, sedikit pendiam
   - Suka: Masakan dengan bumbu kuat (bukan pedas)
   - Tidak suka: Masakan tanpa rasa
   - Ciri khas: Memakai rok kuno, membawa pipa

### 6.3 Resep dan Bahan Baru
Lihat tabel di bagian 5.2. Bahan baru mencakup:
- **Rempah khas:** Dapat dari Giral (harga mahal) atau dari quest Rast/Veral
- **Bahan hutan langka:** Dari hutan dalam (diwarnai sistem cuaca)
- **Bahan khusus quest:** Dapat hanya melalui completing quest Rast/Veral

---

## 7. Sistem Baru (0.2.0)

### 7.1 Quest Tracker UI
- Menampilkan objective quest saat ini untuk Rast dan Veral
- Menampilkan progress hati (0→1→2→3)
- Menampilkan hadiah yang akan didapat saat naik hati
- Diakses dari menu utama atau tombol shortcut

### 7.2 Menu Quest Log
- Mendorong progres quest utama
- Menampilkan clue misteri asap yang telah dikumpulkan
- Menampilkan status prosedur quest (belum mulai, berlangsung, selesai)

### 7.3 Sistem Cuaca (Baru)
- 3 kondisi cuaca: Cerah, Hujan, Badai
- Memengaruhi: tumbuh ulang bahan, kualitas masakan, respons NPC, jam buka toko
- Tampilkan ikon cuaca di pojok layar

### 7.4 Tingkat Kepercayaan (Reputation Sub-system)
- Reputation sekarang terbagi: reputasi warung + kepercayaan masyarakat
- Kepercayaan naik saat quest selesai, turun saat masalah tidak diselesaikan
- Memengaruhi: harga jual, diskon NPC, akses area baru

---

## 8. Kebutuhan Teknis (Update Dari ARCHITECT.md)

### 8.1 Scripts yang Diperbarui
- **QuestSystem.gd:** Sistem tracking quest, objective, dan completion trigger
- **AffectionSystem.gd:** Diperbarui untuk mencakup hati 4 (baru) dan aturan pemberian spesial baru
- **WarungSystem.gd:** Diperbarui untuk tier 4 ("Warung Besar") dan pelanggan khusus quest
- **CookingSystem.gd:** Ditambah 6 resep baru, validasi bahan quest, efek cuaca

### 8.2 Data yang Diperbarui
- **data/npcs/:** 4 file JSON baru untuk NPC baru (arin, budi, siti, pak_udin)
- **data/recipes/:** 6 file JSON baru untuk resep baru
- **data/warung/tiers.json:** Diperbarui tier 4 dan pelanggan baru
- **data/shops.json:** Diperbarui katalog barang untuk Giral dan Talia (menambah rempah eksklusif)
- **data/schedules.json:** Diperbarui jadwal untuk NPC baru

### 8.3 UI/UX Updates
- **Quest tracker:** UI baru di pojok kiri atas menampilkan objective quest
- **Quest log menu:** Menu baru dari main menu untuk melacak progres quest
- **Weather UI:** Ikon cuaca di pojok kanan atas
- **Reputation breakdown:** Tampilan repute warung dipecah di menu pengaturan/statistik

### 8.4 Build Target (Fase 11 Lanjutan)
- **Windows Desktop:** Build dan test
- **Web / itch.io:** Build dan test
- **Android / Play Store:** Build AAB signing non-debug, uji pada perangkat kelas rendah

---

## 9. Scope Termasuk

- Main quest Rast hati 0-3 dengan objective tracking dan hadiah
- Main quest Veral hati 0-3 dengan objective tracking dan hadiah
- 4 NPC baru dengan data JSON, dialog 2 per NPC, dan sistem afeksi
- 6 resep makanan baru dengan bahan dan mekanik baru
- Sistem cuaca sederhana (3 kondisi) yang memengaruhi gameplay
- Tier 4 warung ("Warung Besar") dengan alat baru dan pelanggan baru
- Quest tracker UI dan quest log menu
- 3 clue misteri asap yang terintegrasi dengan quest Rast/Veral
- Build target: Windows, Web, Android (AAB signing non-debug)
- Pengupdate data NPC, resep, warung tiers, schedules

---

## 10. Scope Tidak Termasuk (Bisa 0.3.0)

- Penjelasan final soal dimensi/isekai tokoh utama
- Sistem ekonomi komplit di luar warung
- Makhluk gaib atau ras fantasi lain
- Sistem cuaca yang kompleks (multi-faktor, prediksi)
- Main quest Rast/Veral hati 4 (lanjut ke versi berikutnya)
- Fitur multiplayer atau komunitas
- Sistem cuaca yang memprediksi hujan hari depan

---

## 11. Checklist Sebelim Commit

- [ ] Semua tugas quest diimplementasikan dengan objective tracking
- [ ] Semua data NPC/resep/warung updated ke versi 0.2.0
- [ ] UI quest tracker dan quest log bekerja tanpa crash
- [ ] Sistem cuaca terintegrasi dengan cooking dan NPC behavior
- [ ] Build target Windows, Web, Android sukses dan diuji
- [ ] Save/load kompatibel dengan state quest baru
- [ ] Semua sinyal sudah dihubungkan di `_ready` atau editor
- [ ] Skrip tidak crash jika data JSON kosong atau hilang (fallback default)
- [ ] UI masih layak disentuh pada layar kecil
- [ ] Commit mengikuti Conventional Commits

---

## 12. Pesan Commit

Setiap fitur utama selesai, commit dengan pesan Conventional Commits:

```
feat(0.2.0): tambah main quest Rast hati 0-3 dan tracking objective
feat(0.2.0): tambah main quest Veral hati 0-3 dan tracking objective
feat(0.2.0): tambah 4 NPC baru dengan data JSON dan afeksi
feat(0.2.0): tambah 6 resep makanan baru dan sistem cuaca
feat(0.2.0): upgrade WarungSystem ke tier 4 "Warung Besar"
fix(0.2.0): perbaiki kompatibilitas save/load dengan quest baru
docs: update PRD ke versi 0.2.0 dan dokumentasi sistem baru
```

---

*Catatan: Dokumen ini adalah ekspansi dari PRD Versi Awal. Semua sistem v1.0 tetap berlaku dan diperluas. Detail implementasi quest (dialog, trigger, item hadiah) perlu dikembangkan lebih lanjut sebelum coding dimulai.*