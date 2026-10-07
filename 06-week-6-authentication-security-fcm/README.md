# 🔐 Flutter Authentication, Security & Firebase Cloud Messaging (FCM)

> Codelab Minggu 6 — Authentication, Security, dan Firebase Cloud Messaging pada Flutter

**Terakhir diperbarui:** 27 September 2026

---

## 📌 Deskripsi

Project ini membahas implementasi konsep autentikasi, keamanan token, serta integrasi Firebase Cloud Messaging (FCM) pada aplikasi Flutter.

Materi utama yang dipelajari:

- Authentication flow menggunakan Firebase Auth, JWT, OAuth, dan Google Login.
- Perbedaan ID token, access token, dan refresh token.
- Penyimpanan token secara aman menggunakan secure storage.
- Implementasi token refresh otomatis.
- Arsitektur Firebase Cloud Messaging.
- Notification permission dan lifecycle FCM token.
- Perbedaan notification payload dan data payload.
- Handling deep link dari notifikasi menggunakan GoRouter.
- Prinsip keamanan dasar aplikasi mobile.

---

# 🎯 Tujuan Pembelajaran

Setelah menyelesaikan codelab ini, mahasiswa mampu:

- Menjelaskan alur autentikasi:
  - Firebase Authentication
  - JWT
  - OAuth
  - Google Login

- Memahami perbedaan:

| Token | Fungsi |
|---|---|
| ID Token | Identitas pengguna yang diverifikasi backend |
| Access Token | Izin akses API dengan masa berlaku pendek |
| Refresh Token | Mendapatkan access token baru tanpa login ulang |

- Menyimpan token secara aman menggunakan secure storage.
- Menerapkan mekanisme refresh token otomatis.
- Memahami arsitektur Firebase Cloud Messaging.
- Mengelola lifecycle FCM token.
- Menangani notifikasi pada berbagai kondisi aplikasi.
- Menerapkan prinsip keamanan mobile application.

---

# 🛠️ Persiapan

Sebelum menjalankan project, pastikan sudah tersedia:

## Software

- Flutter SDK
- VS Code + Flutter Extension
- Android Emulator / Device Android
- Firebase Account (Spark Plan)

## Pengetahuan Dasar

Project ini membutuhkan pemahaman:

- Flutter Riverpod
- AsyncValue
- GoRouter
- Dio
- Repository Pattern

---

# 🔑 Authentication Concept

## Model Authentication

Terdapat beberapa pola autentikasi yang umum digunakan pada aplikasi modern.

| Metode | Cara Kerja | Penggunaan |
|---|---|---|
| Firebase Auth | SDK Firebase menghasilkan ID Token JWT | Aplikasi yang membutuhkan login cepat |
| JWT + Refresh Token | Backend membuat access token dan refresh token | REST API milik sendiri |
| OAuth | Provider memberikan authorization token | Social login dan SSO |

---

# 🔐 Token Management

Dalam aplikasi modern terdapat tiga jenis token:

## 1. ID Token

Digunakan sebagai bukti identitas pengguna.

Contoh:

```
User login → Firebase menghasilkan ID Token
Backend melakukan verifikasi token
```

---

## 2. Access Token

Token dengan masa berlaku pendek yang digunakan untuk request API.

Contoh:

```
Authorization: Bearer access_token
```

Biasanya memiliki masa aktif:

```
±15 menit
```

---

## 3. Refresh Token

Token dengan masa berlaku panjang yang digunakan untuk mendapatkan access token baru.

Contoh flow:

```text
Login
 |
 |-- access token (15 menit)
 |
 |-- refresh token (7 hari)
        |
        |
Request API
 |
 |-- access token expired?
        |
        YES
        |
        Tukar refresh token
        |
        Access token baru
        |
        Ulang request
```

Ketentuan keamanan:

✅ Refresh token disimpan menggunakan:

```
flutter_secure_storage
```

❌ Jangan menyimpan token di:

```
SharedPreferences
```

---

# 📱 Firebase Cloud Messaging (FCM)

## Arsitektur FCM

```
             Kirim pesan
App Server -----------------> Firebase Cloud Messaging

Firebase Cloud Messaging
              |
              |
              v

      Android / iOS Device

              |
              |
       Flutter Application
```

---

# 🔔 FCM Token Lifecycle

Alur pengiriman notifikasi:

1. User membuka aplikasi.
2. Aplikasi meminta permission notifikasi.
3. Flutter mendapatkan registration token.

Contoh:

```dart
FirebaseMessaging.instance.getToken();
```

4. Token dikirim ke backend.
5. Backend menyimpan token berdasarkan user.
6. Backend mengirim pesan melalui FCM.

---

# 📩 Notification Payload vs Data Payload

FCM memiliki dua jenis payload:

| Payload | Isi | Perilaku |
|---|---|---|
| Notification Payload | title dan body | Ditampilkan otomatis oleh sistem |
| Data Payload | key-value custom | Diproses oleh aplikasi |

---

## Notification Payload

Contoh:

```json
{
  "notification": {
    "title": "Pengumuman",
    "body": "Jadwal kuliah berubah"
  }
}
```

Digunakan untuk:

- Judul notifikasi
- Isi pesan
- Tampilan kepada user

---

## Data Payload

Contoh:

```json
{
  "data": {
    "route": "/pengumuman/3"
  }
}
```

Digunakan untuk:

- Deep link
- Navigasi halaman tertentu
- Data tambahan aplikasi

---

# 📌 Best Practice Notification

Gunakan kombinasi:

```
notification + data payload
```

Contoh:

```json
{
  "notification": {
    "title": "Pengumuman Akademik",
    "body": "Nilai sudah tersedia"
  },
  "data": {
    "route": "/nilai"
  }
}
```

Keterangan:

- `notification`
  → informasi yang dibaca user

- `data.route`
  → tujuan halaman saat notifikasi ditekan

---

# 📲 Handling Application State

FCM memiliki tiga kondisi utama:

| State | Kondisi | Handler |
|---|---|---|
| Foreground | Aplikasi sedang terbuka | `FirebaseMessaging.onMessage` |
| Background | Aplikasi diminimize | `onMessageOpenedApp` |
| Terminated | Aplikasi ditutup | `getInitialMessage()` |

---

# 🚀 Flow Notification Handling

## Foreground

Ketika aplikasi aktif:

```dart
FirebaseMessaging.onMessage.listen((message) {
  // tampilkan local notification
});
```

Notifikasi perlu ditampilkan manual.

---

## Background

Ketika aplikasi berada di background:

```
Push Notification
        |
        |
User klik notifikasi
        |
        |
onMessageOpenedApp
        |
        |
GoRouter menuju halaman tujuan
```

---

## Terminated

Ketika aplikasi benar-benar ditutup:

```dart
FirebaseMessaging.instance
    .getInitialMessage();
```

Digunakan untuk mengetahui notifikasi yang membuka aplikasi.

---

# 🔒 Mobile Security Checklist

## Jangan menyimpan secret di source code

❌ Contoh salah:

```dart
const apiKey = "SECRET_KEY";
```

Gunakan:

- Environment variable
- Backend configuration
- Secure storage

---

## Jangan melakukan logging token

❌ Hindari:

```dart
print(accessToken);
```

Karena token dapat disalahgunakan.

---

## Gunakan Secure Storage

Contoh:

```dart
final storage = FlutterSecureStorage();

await storage.write(
  key: "refresh_token",
  value: token,
);
```

---

# 📂 Struktur Project (Rekomendasi)

```
lib/
│
├── auth/
│   ├── repository/
│   ├── provider/
│   └── models/
│
├── notification/
│   ├── firebase_service.dart
│   └── notification_handler.dart
│
├── router/
│   └── app_router.dart
│
├── security/
│   └── secure_storage.dart
│
└── main.dart
```

---

# 🧪 Testing Checklist

Pastikan melakukan pengujian:

## Authentication

- [ ] Login berhasil
- [ ] Access token tersimpan
- [ ] Refresh token tersimpan aman
- [ ] Token expired melakukan refresh
- [ ] Logout menghapus token

---

## FCM

- [ ] Permission notification muncul
- [ ] Token berhasil dibuat
- [ ] Token refresh berjalan
- [ ] Notification foreground berhasil
- [ ] Notification background berhasil
- [ ] Notification terminated berhasil
- [ ] Deep link menuju halaman benar

---

# 📚 Kesimpulan

Pada codelab ini dipelajari bagaimana membangun sistem autentikasi dan notifikasi yang lebih aman pada aplikasi Flutter.

Konsep utama:

✅ Authentication flow  
✅ JWT token management  
✅ Secure token storage  
✅ Refresh token mechanism  
✅ Firebase Cloud Messaging  
✅ Notification lifecycle  
✅ Deep link navigation  
✅ Mobile application security  

Dengan konsep ini, aplikasi Flutter dapat memiliki sistem login dan notifikasi yang mendekati standar aplikasi industri.

