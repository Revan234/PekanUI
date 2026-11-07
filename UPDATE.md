<<<<<<< HEAD
# Update Lua PekanBaru UI dari GitHub

Updater memeriksa `Revan234/PekanUI` pada branch `main` saat server yang
sedang diikuti memiliki IP `43.173.14.35`, lalu memeriksa lagi setiap 5 menit
selama tetap terhubung. Port tidak diperiksa. Server lain tidak memicu unduhan.

Untuk merilis perubahan:

1. Unggah `uijtrp.lua`, folder `uijtrp` (file Lua yang ingin diperbarui), dan
   `update-manifest.txt` ke root repo GitHub.
2. Pastikan setiap file Lua yang ingin diunduh tercantum satu per baris di
   `update-manifest.txt`, menggunakan path relatif dari root repo.
3. Commit perubahan ke branch `main`.
4. Saat pengguna masuk/tersambung kembali ke server PekanBaru dan setiap
   pemeriksaan berkala, updater mengambil commit terbaru. Jika ada perubahan,
   file diunduh ke file sementara, divalidasi sintaks Lua, lalu dipasang. UI
   pojok kanan atas menampilkan proses, file yang sedang diunduh, jumlah file
   selesai, dan ukuran unduhan aktif. Script dimuat ulang otomatis setelah
   update berhasil.

Updater hanya mengizinkan `uijtrp.lua` dan file Lua langsung di dalam folder
`uijtrp`. Jika koneksi atau validasi gagal, file yang sedang dipakai tidak
diganti. Perubahan baru di luar file yang terdaftar pada manifest tidak akan
diunduh. Jika repo privat, unduhan publik tidak akan berhasil.
=======
# Update Lua PekanBaru UI dari GitHub

Updater memeriksa `Revan234/PekanUI` pada branch `main` saat server yang
sedang diikuti memiliki IP `43.173.14.35`, lalu memeriksa lagi setiap 5 menit
selama tetap terhubung. Port tidak diperiksa. Server lain tidak memicu unduhan.

Untuk merilis perubahan:

1. Unggah `uijtrp.lua`, folder `uijtrp` (file Lua yang ingin diperbarui), dan
   `update-manifest.txt` ke root repo GitHub.
2. Pastikan setiap file Lua yang ingin diunduh tercantum satu per baris di
   `update-manifest.txt`, menggunakan path relatif dari root repo.
3. Commit perubahan ke branch `main`.
4. Saat pengguna masuk/tersambung kembali ke server PekanBaru dan setiap
   pemeriksaan berkala, updater mengambil commit terbaru. Jika ada perubahan,
   file diunduh ke file sementara, divalidasi sintaks Lua, lalu dipasang. UI
   pojok kanan atas menampilkan proses, file yang sedang diunduh, jumlah file
   selesai, dan ukuran unduhan aktif. Script dimuat ulang otomatis setelah
   update berhasil.

Updater hanya mengizinkan `uijtrp.lua` dan file Lua langsung di dalam folder
`uijtrp`. Jika koneksi atau validasi gagal, file yang sedang dipakai tidak
diganti. Perubahan baru di luar file yang terdaftar pada manifest tidak akan
diunduh. Jika repo privat, unduhan publik tidak akan berhasil.

Modul `uijtrp/interaction_ui.lua` menyediakan prompt ALT untuk interaksi
pemain dan F untuk kendaraan. Perubahan Lua dapat dikirim melalui updater,
tetapi command server untuk bayar, bersalaman, dan hood/trunk berada di source
Pawn; compile dan deploy gamemode server diperlukan setelah perubahan Pawn.
>>>>>>> 80e5d3e (Update PekanBaru source)
