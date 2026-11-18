# QA, Build, dan Rilis

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

- [x] Versi project dan dokumentasi sesuai 0.2.0.
- [x] Project parse bersih dan seluruh 14 tes otomatis lulus.
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
