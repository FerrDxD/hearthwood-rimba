# QA, Build, dan Rilis

## Status 0.8.0 (20 November 2026)

Versi project telah diperbarui ke **0.8.0**. Pemeriksaan otomatis Godot 4.7.2 lulus: project parse tanpa error dan seluruh **35 unit test Godot** hijau (exit code 0).

### Isi Rilis 0.8.0 (Sekuens Prolog & Pelayanan Meja Warung Makan)

- **Sekuens Prolog Pembuka Sinematik (`PrologueSequence.gd`)**:
  - Narasi monolog pembuka saat menekan "Mulai Permainan Baru" di Main Menu: kisah pemilik warteg lokal yang terjebak asap kebakaran gudang tertutup di Indonesia, transisi desau angin rimba, dan efek mengerjap mata (*eye-blink animation*) dua tahap menyingkap kanopi rimbun Suaka Pohon Raksasa (Zona 6).
  - Naskah disimpan secara data-driven pada `data/quests/opening_prologue.json`.
  - Tombol sentuh "Lewati >>" (*Skip* ≥ 44×44 dp) di pojok kanan atas untuk navigasi instan bagi pemain veteran atau testing.
- **Pengalaman Pelayanan Meja Warung Makan (*Dine-In Table Service*)**:
  - Meja makan kayu rustic dengan taplak linen dan bangku santai (`WarungTable.gd`) terpasang di Distrik Warung Pemain.
  - Lonceng/Papan Operasional Warung di beranda warung (`Vector2(1100.0, 470.0)`) untuk membuka sesi makan malam (16:00–21:00) jika pemain memiliki minimal 1 porsi hidangan matang.
  - Balon Pesanan Mengambang (`OrderBubble.gd`): Tamu yang duduk menampilkan pesanan hidangan favorit mereka dengan animasi bobbing lembut.
  - Penyajian Makanan Langsung: Pemain menyajikan hidangan dari inventori tas langsung ke meja tamu, atau memasak on-the-spot di stasiun masak samping meja.
  - Pembayaran & Pembersihan Meja: Tamu menikmati hidangan selama beberapa detik, lalu meninggalkan koin dan bonus tip di atas meja untuk dikumpulkan pemain.
- **Modal Laporan Penjualan Harian (`WarungReportUI.gd`)**:
  - Menampilkan rekapitulasi penjualan saat warung tutup: jumlah tamu terlayani, total koin diperoleh, kenaikan reputasi desa, dan komentar lucu pelanggan.
- **Integritas Alur Permainan & Simpan-Muat**:
  - Seluruh alur utama dari pembukaan prolog, awakening rimba, hingga operasional warung malam dan tidur lulus tanpa galat.
  - Meja makan kotor/terisi otomatis direset bersih saat pergantian hari/tidur.
- **Cakupan Pengujian**: 35 dari 35 test suite lulus (100% PASS).

## Status 0.7.0 (20 November 2026)

Versi project telah diperbarui ke **0.7.0**. Pemeriksaan otomatis Godot 4.7.2 lulus: project parse tanpa error dan seluruh **30 unit test Godot** hijau (exit code 0).

### Isi Rilis 0.7.0 (Ekspansi Wilayah Desa Hearthwood)

- **4 Distrik Terpadu Desa**: Peta desa tunggal terpadu `Rect2(560.0, 0.0, 1040.0, 880.0)` yang dirancang estetik dan ergonomis:
  1. **Distrik Pasar**: Kios pasar sayur-rempah Giral dan kios kerajinan-alat Talia yang berjejer rapi dengan karpet terpal, peti hasil bumi, dan lumbung padi desa.
  2. **Distrik Pusat Pemerintahan (Balai Desa)**: Gedung megah Balai Desa dengan pilar batu berukir, kanopi megah di atas pintu masuk, dan lentera teras di mana Kepala Desa Veral berkantor (`Vector2(1390.0, 342.0)`).
  3. **Distrik Warung Pemain**: Area warung makan yang nyaman dengan stasiun memasak, perapian hangat, dan tempat tidur peristirahatan pemain.
  4. **Distrik Pemukiman Warga**: 6 pondok hunian beratap genteng terakota, pagar kayu rustic, dan pekarangan asri tempat warga beristirahat.
- **Cobblestone Plaza**: Lapangan batu bulat di persimpangan utama desa yang menghubungkan seluruh distrik secara organik dengan pencahayaan lentera jalan.
- **Fasilitas Interaktif Baru**:
  1. **Sumur Desa (`VillageWell.gd`)**: Sumur batu beratap sirap kayu di Plaza Tengah (`Vector2(1050.0, 460.0)`). Interaksi harian memulihkan +5 energi dan memberikan 1 `air_bersih` (1x/hari).
  2. **Papan Pengumuman (`NoticeBoard.gd`)**: Papan buletin kayu di Plaza Tengah (`Vector2(1130.0, 460.0)`). Menyajikan warta harian dinamis (prakiraan cuaca, selera/ngidam masakan warga desa, dan memo resmi Kepala Desa Veral).
- **Dinamika Kerumunan Sosial (Ambient Crowd Clustering)**:
  - 32 NPC ambient berpenampilan bervariasi terorganisasi dinamis: 24 warga berkerumun mengikuti jadwal harian (08-12 Pasar, 12-16 Plaza/Sumur, 16-20 Warung, 20-08 Pemukiman) dan 8 warga berkelana bebas mengitari desa.
  - Isolasi absolut batas desa: seluruh 32 NPC ambient strictly berada di `x >= 560.0` dan tidak pernah merembes ke wilayah rimba.
- **Integritas Alur Permainan & Simpan-Muat**:
  - Alur prolog (hutan, Rast, foraging, Veral, memasak, warung, tidur) berjalan lancar tanpa rintangan collider.
  - Dukungan serialisasi `air_bersih` dan state interaksi harian sumur desa dengan backward-compatibility penuh.
- **Cakupan Pengujian**: 30 dari 30 test suite lulus (100% PASS).

## Status 0.3.0 (19 November 2026)

Versi project telah diperbarui ke **0.3.0**. Pemeriksaan otomatis Godot 4.7.2 lulus: project parse tanpa error dan seluruh unit test Godot hijau (exit code 0).

### Isi Rilis 0.3.0

- **Ekspansi Peta Multi-Zona Hutan**: 6 wilayah terhubung secara organik:
  1. Wilayah 1: Suaka Pohon Raksasa (`zone_forest_sanctuary`)
  2. Wilayah 2: Pos Penebang Kayu (`zone_forest_logging`)
  3. Wilayah 3: Semak Belukar Lembab (`zone_forest_thicket`)
  4. Wilayah 4: Lembah Akar Purba (`zone_forest_valley`)
  5. Wilayah 5: Aliran Sungai Bebatuan (`zone_forest_river`)
  6. Wilayah 6: Pintu Rimba (`zone_forest_gate`) dengan akses dua arah ke Desa (`village`).
- **Komponen Transisi `ZoneGate2D`**: Mekanisme perpindahan antar-zona mulus dengan transisi fade out/in instan (0,2s), memposisikan pemain pada target spawn gate yang sesuai, dan waktu game tetap berjalan secara real-time alami tanpa jeda kaku.
- **Isolasi NPC Ambient & Sinkronisasi Rast**: Pembatasan NPC ambient strictly di desa (0 ambient NPC di hutan) untuk mempertahankan suasana rimba alami yang tenang, serta jadwal kerja Rast di Wilayah 3 (06:00–16:00) dan di desa pada sisa hari.
- **Redistribusi Foraging Tematik**: 12 titik foraging terdistribusi merata di seluruh zona hutan (buah liar, kayu ranting, herba hutan, batu kali, jamur lembab) dengan bonus panen jamur saat cuaca hujan di Wilayah 4.
- **Gating Rintangan Pohon Tumbang Pasca-Prolog**: Batasan fisik pohon tumbang antara Wilayah 2 dan Wilayah 3 yang aktif pasca-prolog dan dapat dibuka otomatis melalui Quest Rast Hati 2 (*Menembus Hutan Dalam*).
- **Banner Notifikasi `LocationToastUI`**: Banner transparan non-blocking yang mengambang elegan di bagian atas layar untuk menampilkan nama wilayah baru selama 2,5 detik saat pemain berpindah zona.
- **Kompatibilitas Save/Load Penuh**: Backward compatibility dari save game v1.0 dan v0.2.0, serta persistensi dynamic state multi-zona (rintangan pohon tumbang, zona aktif terakhir, posisi pemain).
- **Regresi Test Suite**: Seluruh unit test otomatis Godot hijau tanpa regresi.

## Status 0.2.0 (18 November 2026)

Versi project sudah dinaikkan ke **0.2.0**. Pemeriksaan otomatis Godot 4.7.2 lulus: project parse tanpa error dan **14 tes Godot** hijau. Build belum dapat dihasilkan di lingkungan kerja ini; percobaan ekspor ketiga preset mencatat blocker berikut:

| Target | Status | Pesan ekspor / prasyarat yang belum tersedia |
|---|---|---|
| Windows Desktop | Gagal ekspor | `No export template found ... 4.7.2.stable/windows_release_x86_64.exe` (template standar 4.7.2 belum terpasang) |
| Web / itch.io | Gagal ekspor | `No export template found` untuk template web 4.7.2 standar |
| Android / Play Store | Gagal ekspor | Template Android belum ada, `A valid Java SDK path is required in Editor Settings`, `Invalid Android SDK path ... Missing 'platform-tools'`, `Missing 'build-tools'` |
| Uji perangkat Android rendah | Belum dilakukan | Tidak ada perangkat Android terhubung; `adb` belum tersedia karena Android SDK belum terpasang |

Yang terpasang hanya export template .NET, sedangkan project memakai Godot standar. Preset Windows/Web/Android sudah tersedia di `export_presets.cfg`; file kredensial tidak disimpan di repository. Folder `export/` diabaikan Git dan saat ini kosong (tidak ada artefak build).

## Isi rilis 0.2.0

- Quest utama Rast/Veral dengan 4 bab, hadiah hati, penanda objective di HUD, dan clue misteri asap.
- Empat NPC baru (Arin, Budi, Siti, Pak Udin) beserta jadwal harian dan aksesori sprite.
- Enam resep baru, pembuka resep lewat quest/pembelian, dan sistem cuaca harian Cerah/Hujan/Badai.
- Pengaruh cuaca: pertumbuhan ulang bahan, zona mini-game memasak, respons NPC, dan jam buka Giral.
- Tier 4 warung "Warung Besar" (reputasi 40, 3000 koin + 2 kayu + 1 batu, `dapur_besar`, 8 porsi, pelanggan quest).
- Quest log `QuestUI` (tombol HUD + `J`) berisi bab, hati, objective, hadiah berikutnya, dan clue asap.

Save v1.0 tetap dapat dimuat: field baru bersifat opsional dan cuaca lama (mis. `dingin`) tetap diterima.

## Persyaratan

- Godot **4.7.2 stable standar** dan export template standar dengan versi yang sama.
- Untuk Android: OpenJDK 17 direkomendasikan Godot, Android SDK, platform-tools, SDK Platform 35, Build Tools 35.0.1, Command-line Tools, CMake 3.10.2.4988404, serta NDK r28b.
- Konfigurasi Java SDK dan Android SDK pada Editor Settings Godot.
- Untuk Play Store: application ID yang dimiliki penerbit, ikon Android yang sesuai, dan keystore rilis non-debug. Simpan password dan kredensial secara lokal; jangan commit atau membagikannya.

Dokumentasi resmi:
- [Exporting projects](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html)
- [Exporting for Android](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
- [Exporting for the Web](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html)

## QA otomatis

Gunakan Godot 4.7.2 yang sama dengan versi project. Dari PowerShell:

```powershell
$godot = "C:\Path\To\Godot_v4.7.2-stable_win64_console.exe"
$project = "C:\Path\To\hearthwood-rimba"
& $godot --headless --editor --path $project --quit
if ($LASTEXITCODE -ne 0) { throw "Project parse failed." }

Get-ChildItem (Join-Path $project "tests") -Filter "*Test.gd" |
    Sort-Object Name |
    ForEach-Object {
        & $godot --headless --path $project --script $_.FullName
        if ($LASTEXITCODE -ne 0) { throw ("Test failed: " + $_.Name) }
    }
```

Cakupan tes 0.2.0: waktu, dunia, NPC/dialog, toko, inventori, memasak, afeksi, warung, save/load, UI sentuh, alur utama, quest, cuaca, dan startup main menu. Tes save/load memakai file sementara, memeriksa round-trip state dan posisi, serta menolak data rusak/tidak lengkap tanpa menerapkan sebagian state. Save game hanya berisi nama pemain yang dipilih, progres, inventori, dan posisi permainan; tidak ada password atau signing key.

## Pemeriksaan checklist AGENTS.md

- Dialog NPC/prolog berada di JSON; jam buka toko diambil dari data NPC.
- Tes UI memastikan 27 tombol memenuhi batas minimum 44×44; ukuran fisik dan keterbacaan pada perangkat Android belum diverifikasi.
- Save/load lulus tes round-trip dan validasi, termasuk save v1.0 tanpa data quest/cuaca.
- **Belum terpenuhi:** jika file JSON wajib hilang atau tidak valid, beberapa loader memberi error dan membatalkan setup, bukan menyediakan fallback default. Data project yang tersedia valid, tetapi fallback umum ini perlu diputuskan sebelum menganggap checklist AGENTS.md seluruhnya lulus.

## Ekspor

Preset Windows Desktop, Web, dan Android terdapat di `export_presets.cfg`. Hasil percobaan 18 November 2026 tercatat di tabel status: ketiganya gagal karena template/SDK belum tersedia. Setelah memasang template yang cocok dan mengatur Android SDK/signing lokal, jalankan:

```powershell
& $godot --headless --path $project --export-release "Windows Desktop" "$project\export\windows\HearthwoodWarungRimba.exe"
& $godot --headless --path $project --export-release "Web" "$project\export\web\HearthwoodWarungRimba.zip"
& $godot --headless --path $project --export-release "Android" "$project\export\android\HearthwoodWarungRimba.aab"
```

Pastikan ekspor Web berjalan di browser melalui HTTP server, bukan membuka berkas HTML langsung. Sebelum rilis Android, ekspor AAB bertanda tangan non-debug, instal dan uji APK/AAB pada perangkat fisik, termasuk perangkat Android kelas rendah, rotasi/resume, kontrol sentuh, audio, performa, dan pemulihan save.

## Checklist sebelum rilis

- [x] Versi project dan dokumentasi sesuai 0.8.0.
- [x] Project parse bersih dan seluruh unit test otomatis lulus.
- [x] Blocker ekspor Windows/Web/Android dicatat eksplisit di dokumen ini.
- [ ] Pasang export template standar Godot 4.7.2 dan hasilkan ketiga target di atas.
- [ ] Tetapkan application ID, ikon launcher Android, keystore, dan metadata toko.
- [ ] Uji kontrol sentuh, ukuran UI, performa, audio, tidur, memasak, dan interaksi pada perangkat Android kelas rendah.
- [ ] Uji build Web di browser dan build desktop pada komputer bersih.
- [ ] Uji save/load rilis: lanjutkan game, muat save, dan tolak save rusak.
- [ ] Lengkapi daftar pertanyaan terbuka dan tentukan jadwal rilis sebelum publikasi.

## Pertanyaan terbuka untuk versi berikutnya

- Kapan jadwal rilis v1.0 dan siapa penerbit yang memiliki application ID serta keystore?
- Misteri asap dan quest utama Rast/Veral diperluas di 0.2.0, tetapi jawaban finalnya tetap ditunda; kapan penjelasan itu akan dirancang?
