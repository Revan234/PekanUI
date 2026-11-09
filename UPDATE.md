# Update Lua PekanBaru UI dari GitHub

Updater memeriksa `Revan234/PekanUI` pada branch `main` saat server yang
sedang diikuti memiliki IP `43.173.14.35`, lalu memeriksa lagi setiap 5 menit
selama tetap terhubung. Port tidak diperiksa. Server lain tidak memicu unduhan.

Manifest dibuat dari seluruh file UI yang boleh diunduh updater, bukan hanya
file yang berubah pada commit terakhir. Ini penting agar pemain yang melewatkan
beberapa update tetap menerima semua file versi terbaru.

Untuk merilis perubahan:

1. Sebelum membuat pull request, jalankan
   `powershell -ExecutionPolicy Bypass -File .\New-UpdateManifest.ps1` dari root
   repo. Script menyusun manifest lengkap secara otomatis, termasuk modul Lua
   dan aset yang diizinkan updater.
2. Commit perubahan UI bersama `update-manifest.txt`. GitHub Actions memeriksa
   manifest di pull request dan menyinkronkannya otomatis setelah push ke
   branch `main`.
3. Saat pengguna masuk/tersambung kembali ke server Pekanbaru dan setiap
   pemeriksaan berkala, updater mengambil commit terbaru. Jika ada perubahan,
   file diunduh ke file sementara, divalidasi sintaks Lua, lalu dipasang. UI
   pojok kanan atas menampilkan proses, file yang sedang diunduh, jumlah file
   selesai, dan ukuran unduhan aktif. Script dimuat ulang otomatis setelah
   update berhasil.

`powershell -ExecutionPolicy Bypass -File .\New-UpdateManifest.ps1 -Check`
memeriksa sinkronisasi tanpa mengubah file. Updater hanya mengizinkan
`uijtrp.lua`, file Lua, gambar, dan audio di folder `uijtrp`, serta daftar file
browser tertentu. Path absolut, traversal folder, logo frames, serta aset
notify/notif dan ringtone ditolak. File Lua divalidasi sintaksnya; file gambar
dan audio dipasang sebagai data biner.
Awalan manifest salah ketik `ufjtrp/` dikoreksi ke `uijtrp/` sebelum validasi.
Unduhan dicoba ulang dan memakai GitHub CDN sebagai jalur cadangan. Jika semua
jalur gagal, file yang sedang dipakai tidak diganti dan pemeriksaan dicoba lagi
setelah 30 detik selama tetap berada di server PekanBaru. Jika repo privat,
unduhan publik tidak akan berhasil.

Menu F2 pada halaman Beranda menampilkan status updater dan hingga delapan
hasil pemeriksaan atau update terakhir. Riwayat disimpan secara lokal di file
`.pbrp-update-log` di folder script MoonLoader dan tetap tersedia setelah
script dimuat ulang.

Modul `uijtrp/interaction_ui.lua` menyediakan prompt ALT untuk interaksi
pemain dan kendaraan. Perubahan Lua dapat dikirim melalui updater,
tetapi command server untuk bayar, bersalaman, dan hood/trunk berada di source
Pawn; compile dan deploy gamemode server diperlukan setelah perubahan Pawn.

Modul `uijtrp/business_ui.lua` menampilkan dialog pilihan belanja dan menu
bisnis dengan UI Lua. Dialog server tetap menjadi fallback, sehingga pemain
Android atau pemain tanpa MoonLoader tetap dapat menggunakan fitur bisnis.

Modul `uijtrp/character_select_ui.lua` menampilkan pilihan karakter dalam
bentuk card dengan animasi. Dialog server tetap menjadi fallback untuk pemain
tanpa MoonLoader.

Modul `uijtrp/login_ui.lua` memakai tema merah-hitam dan efek audio pendek
`uijtrp/assets/sound/login_feedback.wav` dari file WAV yang disediakan untuk
ketikan password serta tombol masuk. File modul dan efek audio disertakan di
manifest updater.
Logo `uijtrp/assets/pbrp-logo.png` ditampilkan pada kartu login. Lagu
`uijtrp/assets/sound/f2383602-54e8-4e0b-b171-eec9722a328f.wav` diputar saat
pemain memilih karakter; keduanya juga tersedia lewat manifest updater.
