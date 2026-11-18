# QA, Build, dan Rilis

## Status saat ini

Belum siap dirilis ke toko. Pada 18 November 2026, pemeriksaan otomatis Godot 4.7.2 lulus, tetapi build belum dapat dibuat di lingkungan kerja ini:

| Target | Status | Prasyarat yang belum tersedia |
|---|---|---|
| Windows Desktop | Belum dibangun | Export template Godot standar 4.7.2 |
| Web / itch.io | Belum dibangun | Export template Godot standar 4.7.2 |
| Android / Play Store | Belum dibangun | Export template standar, Android SDK, dan Java SDK yang dikonfigurasi di Godot; signing key non-debug belum diverifikasi |
| Uji perangkat Android rendah | Belum dilakukan | Tidak ada perangkat Android yang terhubung melalui ADB |

Yang terpasang hanya export template .NET, sedangkan project memakai Godot standar. Project juga memerlukan pengaturan Android dan identitas aplikasi milik penerbit sebelum unggahan ke Play Store. Preset rilis sudah disediakan di `export_presets.cfg`; file kredensial tidak disimpan di repository.

Project parse tanpa error. Semua **12 tes Godot** lulus dan tes startup main menu dapat dijalankan. Percobaan ekspor ketiga preset mengonfirmasi Windows/Web terhalang template yang tidak ada; Android juga terhalang template Android, SDK, dan Java SDK path yang belum dikonfigurasi. Belum ada build output yang dihasilkan.

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

Tes save/load menggunakan file sementara, memeriksa round-trip state dan posisi, serta menolak data rusak/tidak lengkap tanpa menerapkan sebagian state. Save game hanya berisi nama pemain yang dipilih, progres, inventori, dan posisi permainan; tidak ada password atau signing key.

## Pemeriksaan checklist AGENTS.md

- Dialog NPC/prolog berada di JSON; jam buka toko diambil dari data NPC.
- Tes UI memastikan 26 tombol memenuhi batas minimum 44×44; ukuran fisik dan keterbacaan pada perangkat Android belum diverifikasi.
- Save/load lulus tes round-trip dan validasi.
- **Belum terpenuhi:** jika file JSON wajib hilang atau tidak valid, beberapa loader memberi error dan membatalkan setup, bukan menyediakan fallback default. Data project yang tersedia valid, tetapi fallback umum ini perlu diputuskan sebelum menganggap checklist AGENTS.md seluruhnya lulus.

## Ekspor

Preset Windows Desktop, Web, dan Android terdapat di `export_presets.cfg`. Setelah memasang template yang cocok dan mengatur Android SDK/signing lokal, jalankan:

```powershell
& $godot --headless --path $project --export-release "Windows Desktop" "$project\export\windows\HearthwoodWarungRimba.exe"
& $godot --headless --path $project --export-release "Web" "$project\export\web\HearthwoodWarungRimba.zip"
& $godot --headless --path $project --export-release "Android" "$project\export\android\HearthwoodWarungRimba.aab"
```

Folder `export/` diabaikan Git. Pastikan ekspor Web berjalan di browser melalui HTTP server, bukan membuka berkas HTML langsung. Sebelum rilis Android, ekspor AAB bertanda tangan non-debug, instal dan uji APK/AAB pada perangkat fisik, termasuk perangkat Android kelas rendah, rotasi/resume, kontrol sentuh, audio, performa, dan pemulihan save.

## Checklist sebelum rilis

- [ ] Pasang export template standar Godot 4.7.2 dan hasilkan ketiga target di atas.
- [ ] Tetapkan application ID, ikon launcher Android, keystore, dan metadata toko.
- [ ] Uji kontrol sentuh, ukuran UI, performa, audio, tidur, memasak, dan interaksi pada perangkat Android kelas rendah.
- [ ] Uji build Web di browser dan build desktop pada komputer bersih.
- [ ] Uji save/load rilis: lanjutkan game, muat save, dan tolak save rusak.
- [ ] Lengkapi daftar pertanyaan terbuka dan tentukan jadwal rilis sebelum publikasi.

## Pertanyaan terbuka untuk versi berikutnya

- Kapan jadwal rilis v1.0 dan siapa penerbit yang memiliki application ID serta keystore?
- Misteri asap dan quest utama Rast/Veral tetap ditunda dari v1.0; kapan dan bagaimana fitur itu akan dirancang untuk versi berikutnya?
