# Update Lua PekanBaru UI dari GitHub

Updater memeriksa `Revan234/PekanUI` pada branch `main` saat server yang
sedang diikuti memiliki IP `43.173.14.35`, lalu memeriksa lagi setiap 5 menit
selama tetap terhubung. Port tidak diperiksa. Server lain tidak memicu unduhan.

Untuk merilis perubahan:

1. Unggah `uijtrp.lua`, folder `uijtrp` (modul dan aset yang ingin diperbarui),
   dan `update-manifest.txt` ke root repo GitHub.
2. Cantumkan setiap file satu per baris di `update-manifest.txt`, menggunakan
   path relatif dari root repo. Updater menerima file Lua, gambar PNG/JPG/JPEG/
   WEBP/BMP, dan audio WAV/MP3/OGG di dalam folder `uijtrp`.
3. Commit perubahan ke branch `main`.
4. Saat pengguna masuk/tersambung kembali ke server PekanBaru dan setiap
   pemeriksaan berkala, updater mengambil commit terbaru. Jika ada perubahan,
   file diunduh ke file sementara, divalidasi sintaks Lua, lalu dipasang. UI
   pojok kanan atas menampilkan proses, file yang sedang diunduh, jumlah file
   selesai, dan ukuran unduhan aktif. Script dimuat ulang otomatis setelah
   update berhasil.

Updater hanya mengizinkan `uijtrp.lua` dan file dengan ekstensi yang didukung
di dalam folder `uijtrp`; path absolut dan traversal folder ditolak. File Lua
divalidasi sintaksnya, sedangkan aset divalidasi agar unduhannya tidak kosong.
Semua file yang terdaftar pada manifest diunduh saat ada commit baru, jadi
manifest aset lengkap dapat mengunduh ulang sekitar 24 MB per rilis. Cantumkan
hanya aset yang memang ingin dirilis lewat updater. Jika koneksi atau validasi
gagal, file yang sedang dipakai tidak diganti. Jika repo privat, unduhan publik
tidak akan berhasil.

Menu F2 pada halaman Beranda menampilkan status updater dan hingga delapan
hasil pemeriksaan atau update terakhir. Riwayat disimpan secara lokal di file
`.pbrp-update-log` di folder script MoonLoader dan tetap tersedia setelah
script dimuat ulang.

Modul `uijtrp/interaction_ui.lua` menyediakan prompt ALT untuk interaksi
pemain dan F untuk kendaraan. Perubahan Lua dapat dikirim melalui updater,
tetapi command server untuk bayar, bersalaman, dan hood/trunk berada di source
Pawn; compile dan deploy gamemode server diperlukan setelah perubahan Pawn.
