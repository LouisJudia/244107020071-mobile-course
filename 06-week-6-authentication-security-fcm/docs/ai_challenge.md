# AI Challenge: Push Notification & Authentication Security

**Nama**: Louis Judia B Sinaga  
**NIM**: 244107020071  
**Kelas**: TI-3H  
**Mata Kuliah**: Pemrograman Mobile  

---

## 1. AI Prompt Challenge

Berikut adalah prompt komprehensif yang diajukan untuk merancang service push notification dan integrasi arsitektur keamanan:

```text
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

---

## 2. Output Awal AI & Evaluasi Kritis

### Output Draf Awal yang Dihasilkan AI:
1. AI menyarankan membuat kelas `PushService` dengan method background handler di dalam class:
   ```dart
   class PushService {
     Future<void> backgroundHandler(RemoteMessage message) async {
       print("Background message: ${message.messageId}");
     }
   }
   ```
2. AI mencetak seluruh nilai token FCM secara mentah ke console:
   ```dart
   print("FCM Token: $token");
   ```
3. AI mencoba memanggil `context.go(route)` langsung dari callback `onMessageOpenedApp` dan `onMessage` tanpa navigasi berbasis GoRouter global key atau stream event.
4. AI menggunakan SharedPreferences untuk menyimpan fallback token jika secure storage gagal.

---

## 3. Checklist Verifikasi & Analisis Teknis (AI Verification Checklist)

| No | Kriteria Evaluasi | Status Validasi | Temuan & Analisis Perbaikan |
|---|---|---|---|
| 1 | **Background Handler Top-Level** | ⚠️ Ditolak & Diperbaiki | AI menaruh background handler sebagai *member method* kelas. Flutter Engine memerlukan fungsi *top-level* atau *static method* dengan anotasi `@pragma('vm:entry-point')` agar entry-point dapat dieksekusi di isolate terpisah oleh Android OS ketika aplikasi dimatikan/background. |
| 2 | **Sinkronisasi `onTokenRefresh`** | ⚠️ Diperbaiki | AI hanya melakukan `print()` saat token di-refresh. Kami merefaktor agar token dikirim via HTTP `POST /devices` ke backend kampus dan disimpan di state aplikasi. |
| 3 | **Local Notification di Foreground** | ✅ Diterima & Diselaraskan | Sesuai spesifikasi, Android tidak menampilkan banner sistem saat aplikasi aktif (*foreground*). Harus dibuat manual menggunakan `flutter_local_notifications` via `onMessage`. |
| 4 | **Navigasi 3 App State (Klik)** | ⚠️ Diperbaiki | AI menggunakan `BuildContext` di dalam stream listener FCM. Padahal stream FCM berjalan di luar siklus widget tree dan tidak memiliki context yang stabil. Kami memperbaikinya dengan listener rute global (`GoRouter` instance) dan pure function `routeFromMessage()`. |
| 5 | **Privasi & Keamanan Token** | ⚠️ Ditolak & Diperbaiki | Menolak pencetakan raw FCM token dan raw JWT token ke terminal/log. Semua tampilan token di UI wajib dipotong (*masked*) maksimal 12 karakter pertama + `...` (misal: `mock-fcm-tok...`). |
| 6 | **Pemisahan Logika & Unit Testing** | ⚠️ Ditingkatkan | Memisahkan parsing rute ke `lib/routes.dart` (`routeFromMessage`) dan mapping error Dio ke `lib/data/api_errors.dart` agar dapat diuji 100% tanpa dependensi Firebase sungguhan. |

---

## 4. Perbaikan Manual yang Diterapkan

### A. Top-Level Background Handler
Memastikan isolasi Dart VM tidak mengalami crash:
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Isolate terpisah: Jangan akses UI atau BuildContext di sini!
  // Hanya lakukan logging terenkripsi atau sinkronisasi lokal ringan.
}
```

### B. Masking Token di UI ([`lib/pages/home_page.dart`](file:///c:/Users/louis/Semester%205a/244107020071-mobile-course/06-week-6-authentication-security-fcm/campus_notify/lib/pages/home_page.dart))
Mencegah kebocoran credential di tangkapan layar / laporan:
```dart
String _formatTruncatedToken(String? token) {
  if (token == null || token.isEmpty) return 'Belum tersedia (mock/offline)';
  if (token.length <= 12) return token;
  return '${token.substring(0, 12)}...';
}
```

### C. Pemisahan Perbedaan Platform Android 13+ vs iOS
- **Android 13+ (API level 33+)**: Memerlukan runtime permission `android.permission.POST_NOTIFICATIONS` melalui `flutter_local_notifications` plugin initialization dan konfigurasi channel notification `High Importance`.
- **iOS**: Memerlukan `requestPermission` dengan opsi `alert: true, badge: true, sound: true` serta registrasi APNs (Apple Push Notification service) sebelum token FCM dapat diterbitkan.

---

## 5. Matriks Hasil Pengujian 3 App State

| State Aplikasi | Kondisi Pesan Masuk | Handler FCM yang Menangani | Perilaku UI & Banner | Hasil Navigasi Saat Diklik |
|---|---|---|---|---|
| **Foreground** (Aplikasi Terbuka) | Pesan `notification + data` dikirim dari server/simulasi | `FirebaseMessaging.onMessage.listen` | Banner lokal dimunculkan manual oleh `flutter_local_notifications` di atas layar | Membuka rute tujuan `/pengumuman/3` via callback local notification |
| **Background** (Aplikasi Diminimize) | Pesan `notification + data` dikirim dari server/simulasi | Sistem OS + `onMessageOpenedApp` | Banner notifikasi bawaan Android/iOS otomatis muncul di system tray | Aplikasi dibawa ke foreground lalu otomatis berpindah ke `/pengumuman/3` |
| **Terminated** (Aplikasi Ditutup / Kill) | Pesan `notification + data` dikirim dari server/simulasi | Sistem OS + `getInitialMessage()` | Banner notifikasi bawaan Android/iOS menetap di tray status bar | Aplikasi booting dari awal, `getInitialMessage()` menangkap payload dan langsung membuka `/pengumuman/3` |

---

## 6. Kesimpulan & Pelajaran

Saran dari AI coding assistant sangat membantu dalam menyusun boilerplate awal konfigurasi notifikasi. Namun, verifikasi manusia terhadap batasan runtime arsitektur mobile sangat krusial:
1. **Lifecycle Isolate:** Latar belakang Android/iOS memisahkan memori, sehingga akses global state/BuildContext pada background notification handler akan menyebabkan *unhandled exception*.
2. **Kepatuhan Privasi (Security Hygiene):** Memastikan tidak ada token yang terekspos di log console production maupun tangkapan layar publik demi mematuhi OWASP Mobile Top 10 (M9 - Insecure Data Storage & M1 - Improper Platform Usage).
