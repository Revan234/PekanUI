# Update Lua PekanBaru UI dari GitHub

Updater memeriksa `Revan234/PekanUI` pada branch `main` saat server yang
sedang diikuti memiliki IP `43.173.14.35`, lalu memeriksa lagi setiap 5 menit
selama tetap terhubung. Port tidak diperiksa. Server lain tidak memicu unduhan.

Untuk merilis perubahan:

1. Unggah `uijtrp.lua`, folder `uijtrp` (modul Lua yang ingin diperbarui),
   dan `update-manifest.txt` ke root repo GitHub.
2. Cantumkan setiap file Lua satu per baris di `update-manifest.txt`, menggunakan
   path relatif dari root repo. Updater hanya menerima `uijtrp.lua` dan file
   `.lua` di dalam folder `uijtrp`; gambar dan audio tidak ikut diperbarui.
3. Commit perubahan ke branch `main`.
4. Saat pengguna masuk/tersambung kembali ke server PekanBaru dan setiap
   pemeriksaan berkala, updater mengambil commit terbaru. Jika ada perubahan,
   file diunduh ke file sementara, divalidasi sintaks Lua, lalu dipasang. UI
   pojok kanan atas menampilkan proses, file yang sedang diunduh, jumlah file
   selesai, dan ukuran unduhan aktif. Script dimuat ulang otomatis setelah
   update berhasil.

Updater hanya mengizinkan `uijtrp.lua` dan file `.lua` di dalam folder `uijtrp`;
path absolut dan traversal folder ditolak. File Lua divalidasi sintaksnya.
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
