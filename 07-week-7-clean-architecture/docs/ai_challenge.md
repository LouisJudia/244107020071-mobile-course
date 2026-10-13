# AI Challenge: Clean Architecture & Refactoring Decisions

## 1. AI Prompt Challenge

Berikut adalah prompt pengujian arsitektur yang diajukan ke AI Coding Assistant:

```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

---

## 2. Output Draf Awal yang Dihasilkan AI & Analisis Kritis

### Usulan Awal AI:
1. **Reorganisasi Folder**: AI mengusulkan memecah seluruh file ke folder `lib/features/auth/{data,domain,presentation}` dan `lib/features/announcements/{data,domain,presentation}`.
2. **Use Case untuk Setiap Operasi**: AI membuat use case untuk seluruh fungsi, termasuk operasi baca daftar sederhana satu baris:
   - `LoginUseCase`
   - `LogoutUseCase`
   - `CheckAuthStatusUseCase`
   - `GetAnnouncementsUseCase`
   - `GetAnnouncementDetailUseCase`
   - `RefreshTokenUseCase` (hanya meneruskan pemanggilan 1 baris ke repository tanpa aturan bisnis tambahan).
3. **Penyimpanan Token & Interceptor**: AI sempat menyarankan menaruh interface `TokenStore` di dalam domain auth dan menginstansiasi Dio di dalam presentation provider.
4. **Pola Kembalian Record vs Either**: AI awalnya mengusulkan penggunaan library pihak ketiga `fpdart` (`Either<Failure, T>`), namun Dart 3 sudah memiliki fitur bawaan *Records* `({T? data, Failure? failure})` yang tidak memerlukan dependensi tambahan.

---

## 3. Tabel Pemetaan File Lama ke Struktur Baru (Migrasi)

| File Lama | Layer Lama | Status | Tujuan Baru di Clean Architecture | Alasan Teknis / Masalah yang Diselesaikan |
|---|---|---|---|---|
| `lib/data/auth_repository.dart` | data (+kontrak tercampur) | Dipecah & Dipindah | `lib/features/auth/domain/repositories/auth_repository.dart` & `lib/features/auth/data/repositories/auth_repository_impl.dart` | Memisahkan kontrak abstraksi (domain) dari implementasi konkret (data) sesuai *Dependency Inversion Principle*. |
| `lib/data/token_store.dart` | data | Dipindah | `lib/features/auth/data/datasources/token_store.dart` | Merupakan data source lokal Keystore/Keychain untuk fitur autentikasi. |
| `lib/data/api_client.dart` | data | Dipindah & Direfactor | `lib/core/network/api_client.dart` | Klien HTTP lintas fitur dipusatkan di `core/network/` dan menggunakan kontrak interface `AuthRepository` dari domain. |
| `lib/data/api_errors.dart` | data | Dipindah | `lib/core/network/api_errors.dart` | Mengonversi exception teknis Dio ke `Failure` domain dan string ramah pengguna. |
| `lib/providers/auth_provider.dart` | presentation (state & DI) | Direfactor & Dipindah | `lib/features/auth/presentation/providers/auth_providers.dart` | Wiring DI Riverpod (Repository -> Use Case -> Notifier) dipusatkan di provider fitur presentation. |
| `lib/pages/login_page.dart` | presentation | Dipindah | `lib/features/auth/presentation/pages/login_page.dart` | UI murni hanya memanggil `ref.read(authStateProvider.notifier).login()`. |
| `lib/pages/home_page.dart` | presentation | Direfactor & Dipindah | `lib/features/announcements/presentation/pages/home_page.dart` | Disterilkan dari panggilan `Dio` langsung dan pembacaan raw storage. Membaca data via Riverpod `announcementsProvider` dan `savedSessionProvider`. |
| `lib/pages/announcement_page.dart` | presentation | Direfactor & Dipindah | `lib/features/announcements/presentation/pages/announcement_page.dart` | Menghapus mock map hardcoded di dalam widget `build()`; kini mengonsumsi `announcementDetailProvider(id)`. |

---

## 4. Evaluasi Arsitektur: Over-Engineering vs Kebutuhan Nyata

### Kapan Use Case Benar-Benar Dibutuhkan?
Use case menjadi esensial ketika:
1. **Mengandung Aturan Bisnis (*Business Logic*) & Validasi**:
   - Contoh: `LoginUseCase`. Memiliki aturan bisnis spesifik berupa validasi email harus berformat valid (`@`), password minimal 6 karakter, serta pembersihan spasi (`trim()`). Logika ini harus independen dari UI widget agar dapat diuji secara murni (*pure unit test*).
2. **Mengorkestrasi Multi-Repository atau Sumber Data**:
   - Jika suatu alur membutuhkan pengambilan token dari storage lokal, pengecekan ke server, lalu memperbarui status pengguna sekaligus.
3. **Kebutuhan Pengujian Terisolasi**:
   - Logika bisnis dapat diuji secara cepat tanpa membutuhkan emulator, database SQLite, maupun server HTTP aktif.

### Kapan Use Case Tergolong Over-Engineering?
1. **CRUD Sederhana 1-Baris (*Pass-Through*)**:
   - Pada fitur yang hanya melakukan pass-through seperti `GetAnnouncementsUseCase` yang hanya memanggil `_repository.getAnnouncements()`.
   - **Biaya bagi Tim Kecil**: Menambah boilerplate file, memanjangkan alur penelusuran kode, dan meningkatkan kompleksitas tanpa adanya nilai bisnis tambah jika tidak ada transformasi data atau validasi.
   - **Keputusan Kami**: Tetap mengimplementasikannya sebagai bahan demonstrasi arsitektur Clean Architecture yang lengkap, namun untuk operasi token refresh langsung dikelola via interceptor dan repository agar tidak redundant.

---

## 5. Checklist Verifikasi Mandiri (AI Verification Checklist)

| Kriteria Checklist | Status | Catatan Validasi Teknis |
|---|---|---|
| **1. Interface di Domain, Implementasi di Data** | ✅ VALID | `AuthRepository` dan `AnnouncementRepository` adalah *abstract class* di folder `domain/repositories/`, sedangkan implementasi konkret `AuthRepositoryImpl` dan `AnnouncementRepositoryImpl` berada di `data/repositories/`. |
| **2. Domain Bebas Dependensi Eksternal / Framework** | ✅ VALID | Tidak ada satu pun import `package:flutter`, `package:dio`, `package:sqflite`, atau `package:firebase` di dalam layer `domain/`. Terbukti dengan pemeriksaan grep (0 hasil). |
| **3. Entity Bebas Serialisasi Data Luar** | ✅ VALID | `AuthSession` dan `Announcement` murni kelas Dart tanpa `toMap()`, `fromMap()`, atau `fromJson()`. Semua serialisasi berada pada `AuthSessionModel` dan `AnnouncementModel` di layer data. |
| **4. Presentation Steril dari Data Mentah** | ✅ VALID | Tidak ada `Dio`, `openDatabase`, `FlutterSecureStorage`, atau `jsonDecode` di dalam folder presentation. Widget hanya membaca state dari Riverpod. |
| **5. Wiring DI Terpusat di Riverpod Provider** | ✅ VALID | Widget tidak pernah memanggil `new Repository()` atau instansiasi manual. Seluruh ketergantungan diinjeksi melalui `Provider<Repository>` dan `Provider<UseCase>`. |
| **6. Return Type Ganda Tanpa Exception Bocor** | ✅ VALID | Repository mengembalikan Dart Record eksplisit `({T? data, Failure? failure})`. UI menerima pesan kesalahan yang ramah pengguna. |

---

## 6. Bukti Verifikasi 3 Grep Sterilitas

Perintah verifikasi dijalankan pada direktori project `campus_notify`:

```powershell
# 1. Presentation steril dari data mentah (Hasil: NOL temuan)
Get-ChildItem -Recurse lib/features/*/presentation -Filter *.dart | Select-String -Pattern 'Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode'

# 2. Domain steril dari framework & library luar (Hasil: NOL temuan)
Get-ChildItem -Recurse lib/features/*/domain -Filter *.dart | Select-String -Pattern 'import ''package:flutter|import ''package:dio|import ''package:sqflite|import ''package:firebase'

# 3. Static analysis & Unit test
flutter analyze   # No issues found!
flutter test      # All tests passed! (29 tests)
```
