# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Stack

Godot 4.7 (GL Compatibility), FigCraft MCP UI Kit

## Users

Pemain kasual dan pecinta game simulasi kehidupan/cozy games (seperti Citampi Stories, Stardew Valley, Coffee Talk) yang menginginkan pengalaman santai, adem ayem, tanpa tekanan waktu berlebihan atau ancaman musuh mematikan.

## Product Purpose

Hearthwood: Warung Rimba menghadirkan pengalaman mengelola warung makan ala nusantara di tengah rimba fantasi Eropa abad pertengahan. Tujuannya adalah memberikan rasa hangat (cozy), membumi, dan relasional melalui interaksi warga desa, meramu bahan hutan liar, dan menyajikan hidangan yang tepat bagi setiap tamu.

## Positioning

Kombinasi unik antara atmosfer fantasi medieval yang tenang dengan etos warung makan hangat (warung/warteg nusantara). Berbeda dari game RPG konvensional, di sini tidak ada pertempuran atau elemen kekerasan; kemajuan digerakkan oleh resep masakan, selera makan NPC, dan kehangatan persahabatan.

## Operating Context

- Resolusi viewport: 960 × 540 px (Landscape Android)
- Kontrol sentuh: Virtual joystick kiri bawah, tombol aksi kanan bawah
- Perangkat: Handphone Android (termasuk kelas menengah ke bawah) & PC/Web
- Ritme bermain: Siklus harian 06:00–22:00 (1 menit game = 1.5 detik nyata), tidur untuk memulihkan energi dan mengganti hari

## Capabilities and Constraints

- **Buku Catatan (Dual-Page Journal):** Satu gerbang menu untuk Inventori (20 slot), Resep, Quest, dan Progresi Warung
- **Sistem Memasak (Tier-Agnostic):** Modal melayang dengan pemilihan resep, alat, stepper porsi, dan mini-game timing tungku (3 zona)
- **Toko Pedagang (Quick Buy Rows):** Giral (pagi, sayur/ikan, diskon afeksi) & Talia (siang, perkakas tempa/dapur)
- **Dialog & Pemberian Hadiah:** Kotak dialog sepertiga bawah dengan drawer masakan bergeser dari kanan tanpa tumpang tindih
- **Target Sentuh Minimum:** Wajib ≥ 44 × 44 px untuk semua elemen interaktif
- **Data-Driven:** Semua dialog, jadwal, resep, dan selera NPC disimpan dalam JSON

## Brand Commitments

- **Warna & Suasana:** Mengikuti token [DESIGN.md](file:///C:/Users/Hype%20GLK/hearthwood-rimba/DESIGN.md) (pergamen hangat `#F5F5DC`, kayu coklat `#8B4513`, emas `#CD853F`, hijau lumut `#8FBC8F`)
- **Tone of Voice:** Santai, akrab, sedikit jenaka/sarkastik ramah khas percakapan warga desa nusantara
- **Non-Goals:** Tidak ada unsur horor, pertempuran, atau grinding yang membuat stres

## Evidence on Hand

- `PRD Hearthwood Warung Rimba (Versi 0.4.0).md` (Spesifikasi layar dan komponen)
- `DESIGN.md` (Palet warna, konsep sprite MC/NPC, dan aturan UI piksel)
- `design/Hearthwood_UI_Kit_v0.4.0.figcraft` (Desain 13 halaman UI Kit dasar)

## Product Principles

1. **Cozy First:** Setiap sudut visual harus terasa ramah, hangat, dan mengundang untuk dihuni.
2. **Scanability & Ergonomics:** Teks mudah dibaca pada layar ponsel, informasi penting (energi, jam, stok) langsung terlihat dalam sekali pandang.
3. **Tactile Delight:** Komponen UI meniru tekstur dunia nyata (jurnal kulit, kertas pergamen kusam, baris papan kayu, tombol lilin emas).
4. **Zero Layout Thrashing:** Modal melayang dan drawer menjaga konteks dunia di belakangnya tetap terlihat tanpa membuat pemain disorientasi.

## Accessibility & Inclusion

- Rasio kontras teks minimal 4.5:1 terhadap latar pergamen/kayu
- Ukuran teks terbaca di layar Android (11–16 px resolusi acuan 960×540)
- Dukungan umpan balik visual yang jelas pada tombol (state normal, hover/press, disabled)
