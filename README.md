# Wedding+ Flutter

## Menjalankan aplikasi

Pastikan backend berjalan pada prefix `/api/v1`.

Android Emulator:
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
```

Perangkat Android fisik: ganti `10.0.2.2` dengan IP LAN komputer yang menjalankan backend, dan pastikan perangkat serta komputer berada di jaringan yang sama.

Flutter Web: gunakan `http://localhost:3000/api/v1` sebagai `API_BASE_URL`.

Google Sign-In membutuhkan `GOOGLE_SERVER_CLIENT_ID` dari Web OAuth Client yang sama dengan `GOOGLE_CLIENT_ID` di backend. Jika belum disetel, login email/password tetap dapat digunakan; login Google akan menampilkan pesan konfigurasi.

Jangan menyimpan credential asli di source code atau commit ke repository.
