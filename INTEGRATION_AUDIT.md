# Wedding+ — Laporan Audit Integrasi dan Perbaikan

Tanggal audit: 22 November 2026  
Sumber: `weddingplus.zip` (Flutter) dan `BE.zip` (NestJS) yang diunggah pada percakapan ini.

## Ringkasan status

**Audit dan perbaikan awal berhasil dilakukan, tetapi integrasi Wedding+ belum dapat dinyatakan selesai seluruhnya.** Banyak kontrak API yang sebelumnya tidak cocok sudah diselaraskan. Beberapa alur bisnis penting tetap belum dapat dituntaskan karena source code backend belum memiliki OCR/ML, alur booking frontend belum membuat `Deal`, dan aplikasi Flutter tidak dapat dijalankan di lingkungan audit ini.

Desain visual Flutter tidak sengaja diubah: tidak ada perubahan warna, ukuran, spacing, layout, ikon, atau susunan halaman. Perubahan Flutter berfokus pada state, API, payload, dan penanganan data.

## 1. Perubahan yang dilakukan

### Flutter

1. `services/api_client.dart`
   - Base URL dapat dikonfigurasi melalui `API_BASE_URL`.
   - Default Android Emulator: `http://10.0.2.2:3000/api/v1`.
   - Default Flutter Web: `http://localhost:3000/api/v1`.
   - Response envelope NestJS dibuka secara konsisten melalui `data`.
   - Penanganan error HTTP dan koneksi disatukan.
   - Refresh token memakai satu Future bersama dan memeriksa apakah request lain sudah mengganti access token sebelum mencoba refresh lagi.
   - Menambahkan upload multipart berbasis `XFile`, sehingga tidak bergantung pada `dart:io` di API client.

2. `services/session.dart`
   - Logout hanya menghapus key sesi Wedding+, tidak menghapus seluruh SharedPreferences.
   - Pergantian akun membersihkan plan dan sesi chatbot lama.
   - Menambahkan penyimpanan `chatbotSessionId`.

3. Authentication
   - Login Google disatukan ke `AuthService`.
   - `GOOGLE_SERVER_CLIENT_ID` dibaca dari `--dart-define`.
   - Login tidak lagi dianggap gagal hanya karena sinkronisasi active plan gagal.
   - Logout tidak menjalankan Google Sign-Out dua kali.

4. Profil
   - Menggunakan `GET/PATCH /users/me`, bukan fallback `/auth/me`.
   - Payload profil disesuaikan dengan DTO backend: `name`, `nickname`, `phone`, `gender`, `city`, dan `province`.
   - Membaca `avatarUrl`.
   - Nilai gender dinormalisasi ke `male`/`female`.
   - Field usia belum dapat disimpan karena API backend menerima `birthDate`, bukan angka `age`; UI memberi peringatan agar tidak mengklaim usia sudah tersimpan.

5. Tasks dan scheduler
   - Task menggunakan `isDone`, bukan `status`.
   - Priority menggunakan `normal`, `important`, dan `very_important`.
   - Scheduler memakai `/schedules`, bukan `/scheduler`.
   - Payload jadwal memakai `startAt`, `description`, dan `type`.
   - Data contoh kalender diganti dengan data backend dan tanggal awal dibuat dinamis.

6. Savings
   - Tabungan memakai `/savings/goals` dan `/savings/goals/:id/contributions`.
   - Target default dibuat untuk plan aktif dengan `useTotalBudget: true`.
   - Riwayat kontribusi membaca `contributedAt`, `amount`, dan nama kontributor.
   - Payload kontribusi menggunakan `description`, bukan `note`.

7. Chatbot
   - Frontend memakai `/chatbot/messages`, `/chatbot/sessions`, dan `/chatbot/sessions/:id/messages`.
   - Session ID disimpan agar percakapan berlanjut.
   - Backend mendukung provider Gemini atau Anthropic berdasarkan konfigurasi environment.

8. Chat
   - Menghapus endpoint localhost dan token placeholder di halaman chat.
   - Daftar percakapan memakai `GET /chat/conversations`.
   - Detail chat memakai endpoint conversation/messages backend.
   - Pengiriman teks memakai `POST /chat/messages` dengan `conversationId`, `type`, dan `content`.
   - Backend menambahkan endpoint detail percakapan dan metadata pesan terakhir/unread count.
   - Daftar chat dimuat ulang ketika kembali dari halaman detail.

9. Rekomendasi paket
   - Halaman pencarian memuat paket dari `/recommendations?mode=package`.
   - Filter anggaran dikirim sebagai `maxPrice`; konsep kategori dikirim sebagai `concept`.
   - Detail paket menerima nama vendor, lokasi, deskripsi, harga, gambar, dan ID paket/vendor dari response API.
   - Beranda memuat tugas dan rekomendasi paket dari backend, bukan nama vendor contoh.
   - Ini masih **filter berbasis query/database**, bukan prediksi model ML.

10. Dokumen administrasi
    - Halaman dokumen memuat checklist dari `/documents/tasks`.
    - Jika checklist belum ada, tiga tugas awal dibuat untuk KTP, KK, dan surat pengantar nikah.
    - Upload gambar memakai multipart `/documents/scans`.
    - UI secara eksplisit menyatakan OCR belum dikonfigurasi; upload tidak diklaim sebagai hasil OCR.

11. Booking dan pembayaran
    - ID paket/vendor diteruskan melalui tahapan form.
    - Data booking yang ditampilkan pada review tidak lagi diganti dengan string kosong.
    - Status booking tidak lagi otomatis menjadi `confirmed` dari sisi pengguna.
    - Panel simulasi hanya tampil pada debug build.
    - Tombol bukti pembayaran tidak lagi mengubah status menjadi pending atau mengklaim bukti sudah terkirim jika belum ada upload backend yang berhasil.
    - Pengiriman booking tetap dinonaktifkan dengan pesan yang jelas sampai kontrak `Deal` dan `PlanNeed` diselaraskan.

### NestJS

1. Memperbaiki batas `@MaxLength` yang salah, misalnya angka duplikat seperti `150150`/`20002000`.
2. Menambahkan `multer` sebagai dependency runtime langsung.
3. Membuat folder upload secara otomatis sebelum Multer menyimpan file.
4. Memindahkan penyimpanan bukti transaksi ke `uploads/private/receipts`.
5. Menambahkan entity `DocumentScan` ke `DocumentsModule`.
6. Menambahkan `POST /documents/scans` untuk menyimpan scan dokumen administrasi secara privat.
7. `GET /documents/tasks` mengembalikan metadata scan tanpa membocorkan path filesystem.
8. Menambahkan endpoint vendor untuk bukti transaksi:
   - `GET /documents/vendor/receipts`
   - `GET /documents/vendor/receipts/:id/file`
   - `PATCH /documents/vendor/receipts/:id/validate`
9. Validasi bukti hanya dapat dilakukan vendor pemilik Deal. Status `Deal` berubah menjadi `confirmed` hanya jika vendor memilih `valid`; OCR tidak pernah mengubah status booking.
10. Chat menambahkan `GET /chat/conversations/:id`, dan daftar percakapan mengembalikan pesan terakhir serta unread count.
11. Recommendation response menyertakan rating, jumlah ulasan, dan image URL vendor/paket.
12. Chatbot mendukung konfigurasi Gemini atau Anthropic; key kosong menghasilkan pesan service-unavailable, bukan membuat server gagal start.
13. Google OAuth dibuat opsional saat startup; endpoint Google login memberi 503 jika `GOOGLE_CLIENT_ID` belum diisi.
14. Masa berlaku JWT membaca key environment `JWT_ACCESS_EXPIRES_IN` dan `JWT_REFRESH_EXPIRES_IN`.
15. CORS development tetap mendukung Flutter Web lokal; production menggunakan allow-list `CORS_ORIGINS`.
16. Docker Compose dan TypeORM DataSource diselaraskan ke default host port `5434`.
17. Menambahkan `.env.example` aman dan memperbarui petunjuk konfigurasi README.

## 2. Pemetaan endpoint yang sudah diselaraskan

Prefix global backend: `/api/v1`. `ApiClient` sudah menambahkan prefix ini melalui base URL, jadi path di bawah ditulis tanpa prefix saat dipanggil dari Flutter.

| Fitur | Method dan path | Request utama |
|---|---|---|
| Register | `POST /auth/register` | `name`, `email`, `password`, `confirmPassword`, `acceptTerms` |
| Login | `POST /auth/login` | `email`, `password` |
| Google login | `POST /auth/google` | `idToken` |
| Refresh | `POST /auth/refresh` | `refreshToken` |
| Profil | `GET /users/me` | — |
| Update profil | `PATCH /users/me` | `name`, `nickname`, `phone`, `gender`, `city`, `province` |
| Plan | `GET /plans` | — |
| Create plan | `POST /plans` | `title`, `weddingDate`, `totalBudget`, optional `city`, `guestCount` |
| Update plan | `PATCH /plans/:id` | field plan yang diperbarui |
| Tasks | `GET /tasks?planId=...` | query `planId` |
| Create task | `POST /tasks` | `planId`, `title`, optional `category`, `dueDate`, `priority` |
| Update task | `PATCH /tasks/:id` | `isDone` |
| Scheduler | `GET /schedules?planId=...` | query `planId` |
| Create schedule | `POST /schedules` | `planId`, `title`, `startAt`, optional `description`, `type` |
| Update schedule | `PATCH /schedules/:id` | `startAt`/field jadwal yang diubah |
| Savings goals | `GET /savings/goals?planId=...` | query `planId` |
| Create savings goal | `POST /savings/goals` | `planId`, `title`, `useTotalBudget` |
| Add contribution | `POST /savings/goals/:id/contributions` | `amount`, `contributedAt`, `description` |
| Package recommendation | `GET /recommendations?mode=package&maxPrice=...` | query `mode`, optional `planId`, `maxPrice`, `concept` |
| Chatbot | `POST /chatbot/messages` | `message`, optional `planId`, `sessionId` |
| Chatbot sessions | `GET /chatbot/sessions` | — |
| Chatbot history | `GET /chatbot/sessions/:id/messages` | — |
| Chat list | `GET /chat/conversations` | — |
| Chat detail | `GET /chat/conversations/:id` | — |
| Chat messages | `GET /chat/conversations/:id/messages` | — |
| Send text chat | `POST /chat/messages` | `conversationId`, `type`, `content` |
| Mark chat read | `PATCH /chat/conversations/:id/read` | — |
| Document checklist | `GET /documents/tasks?planId=...` | query `planId` |
| Create document task | `POST /documents/tasks` | `planId`, `title` |
| Upload document scan | `POST /documents/scans` | multipart `file`, `taskId`, `pageNumber` |
| Upload receipt | `POST /documents/receipts` | multipart `file`, `planNeedId`, optional `dealId` |
| User receipt list | `GET /documents/receipts?planId=...` | query `planId` |
| Confirm receipt data | `PATCH /documents/receipts/:id/confirm` | `amount`, `transactionDate`, `recipientName` |
| Vendor receipt list | `GET /documents/vendor/receipts` | — |
| Vendor receipt file | `GET /documents/vendor/receipts/:id/file` | — |
| Vendor receipt validation | `PATCH /documents/vendor/receipts/:id/validate` | `status: valid/rejected`, optional `note` |

## 3. Status integrasi fitur

| Fitur | Status audit |
|---|---|
| Email/password authentication | Endpoint dan payload diselaraskan |
| Google Sign-In | Logic disatukan; membutuhkan client ID valid |
| Profil pengguna | Endpoint dan sebagian field diselaraskan; usia belum tersimpan |
| Wedding plan | Terhubung ke API |
| Wedding tasks | Endpoint, `isDone`, dan priority diselaraskan |
| Scheduler | Endpoint dan payload diselaraskan |
| Savings | Goal dan contribution terhubung ke API |
| Package recommendations | Terhubung sebagai filter database; belum ML |
| Per-item recommendations | Backend memiliki mode item, UI Flutter belum dihubungkan |
| Chatbot | Endpoint dan session diselaraskan; membutuhkan API key |
| Chat teks | REST API terhubung; belum real-time WebSocket |
| Chat attachment/bukti transfer | Belum terhubung |
| Document checklist dan upload scan | Upload tersimpan; OCR belum tersedia |
| OCR dokumen KUA | Belum diimplementasikan |
| OCR bukti transfer | Belum diimplementasikan |
| Vendor receipt validation | Endpoint backend ditambahkan; frontend vendor tidak ada pada ZIP yang diberikan |
| Booking create/status | Belum terhubung end-to-end |
| Notifications | Belum dihubungkan ke API pada Flutter |
| Undang pasangan | UI masih placeholder; mekanisme invitation belum terhubung |

## 4. Masalah struktural yang masih perlu diselesaikan

### Booking

Flutter hanya membawa `packageId` dan `vendorId`, sedangkan endpoint `POST /deals` membutuhkan `conversationId`, `planNeedId`, `amount`, dan `eventDate`. `PlanNeed` saat ini bersifat per-kategori dan tidak menyimpan `serviceItemId`; `Deal` juga belum memiliki `serviceItemId` untuk booking per-item. Karena itu, mengirim request booking dengan data yang ada sekarang berisiko membuat relasi kategori/paket keliru. Perlu keputusan domain: apakah booking paket membuat satu Deal per kategori, atau dibuat entitas Booking tersendiri yang dapat memuat paket maupun item.

### OCR

Source code belum memanggil Tesseract, Google Vision, Gemini Vision, atau OCR provider lain. `Receipt` memiliki kolom `ocr_*`, tetapi upload hanya menyimpan gambar dan kolom OCR tetap kosong. `DocumentScan` juga hanya menyimpan file dan nomor halaman. Tidak ada OCR pipeline, preprocessing, confidence score, atau hasil ekstraksi yang bisa diuji. Dokumen KTP/KK bersifat sensitif; pemilihan engine/provider dan kebijakan penyimpanan perlu dikonfirmasi sebelum gambar dikirim ke layanan eksternal.

### Machine Learning

Tidak ditemukan model artifact, dataset, file Python, atau inference endpoint dalam backend. `/recommendations` melakukan filter SQL berdasarkan harga, konsep, jumlah tamu, status vendor, dan kategori; ini bukan prediksi ML. Untuk mengklaim ML terimplementasi, model dan kontrak input/output harus disediakan serta dihubungkan ke service rekomendasi.

### Database migration

Tidak ditemukan folder migration awal. Build TypeScript tidak membuktikan schema PostgreSQL sudah sesuai. Konfigurasi development dapat menggunakan `synchronize`, tetapi production memakai `synchronize: false`; migration awal harus dibuat dan diuji sebelum deploy production.

### Vendor frontend

ZIP frontend yang diterima adalah aplikasi Flutter pengguna. Tidak ditemukan source code website mitra/vendor, sehingga integrasi UI vendor tidak dapat diaudit. Endpoint backend untuk daftar dan validasi bukti transaksi sudah tersedia, tetapi belum ada UI vendor yang memanggilnya.

## 5. Environment yang harus diisi

### Backend

Salin `.env.example` menjadi `.env`, lalu isi:
- `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DB_DATABASE`
- `JWT_ACCESS_SECRET` dan `JWT_REFRESH_SECRET` yang berbeda dan kuat
- `GOOGLE_CLIENT_ID` untuk mengaktifkan Google login
- `CHATBOT_PROVIDER=gemini` dan `GEMINI_API_KEY`, atau provider Anthropic dengan `ANTHROPIC_API_KEY`
- `CORS_ORIGINS` dengan origin dashboard pada production

`.env` asli dari ZIP tidak disertakan pada hasil perbaikan karena berisi credential.

### Flutter

Contoh Android Emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_GOOGLE_WEB_CLIENT_ID
```

Untuk perangkat fisik, ganti `10.0.2.2` dengan IP LAN komputer backend. Gunakan HTTPS untuk production.

## 6. Hasil pengujian

| Pengujian | Hasil |
|---|---|
| NestJS clean build (`npm run build`) | **Berhasil** |
| Vitest | Tidak dapat dijalankan: `node_modules` dari ZIP berisi binding native Windows, sedangkan runtime audit Linux membutuhkan binding Linux (`rolldown`/Vitest). Instalasi dependency ulang mengalami timeout. |
| Oxlint | Terhalang binding native OS yang sama |
| Flutter `flutter analyze` | Tidak dapat dijalankan karena Flutter SDK tidak tersedia di runtime audit |
| Flutter `flutter test` | Tidak dapat dijalankan karena Flutter SDK tidak tersedia |
| PostgreSQL/Docker integration test | Tidak dapat dijalankan karena Docker tidak tersedia |
| API end-to-end | Belum diuji terhadap database/server hidup |

**Build NestJS yang berhasil hanya memvalidasi kompilasi TypeScript.** Itu bukan bukti bahwa koneksi database, OCR, ML, upload, atau seluruh alur bisnis sudah berjalan di server.

## 7. Isi paket hasil perbaikan

- ZIP Flutter: source code, assets, platform folders, dan konfigurasi; tanpa cache `.dart_tool`/`build`.
- ZIP NestJS: source code, lockfile, Docker Compose, dan `.env.example`; tanpa `.env`, `.git`, `node_modules`, atau `dist`.
- Laporan ini disertakan terpisah sebagai dokumentasi perubahan dan daftar pekerjaan lanjutan.
