# Dokumentasi Skenario Pengujian & Jaminan Kualitas (Test Scenarios & QA Matrix)

**Mata Kuliah:** Pemrograman Mobile (Course 244107020071)  
**Modul:** Minggu 12 - Testing & Quality Assurance (Pengujian dan Jaminan Kualitas)  
**Aplikasi:** Campus Notify (`campus_notify`)  
**Status Pengujian:** 88/88 Tests Passed (100%) • Code Coverage: 71.7% • 0 Linter Issues  

---

## 1. Strategi Piramida Pengujian (Testing Pyramid)

Aplikasi `Campus Notify` menerapkan piramida pengujian terstruktur sesuai standar rekayasa perangkat lunak mobile:

```
                  /\
                 /  \
                / IT \     <-- Integration Tests (1 Flow End-to-End)
               /------\
              /   WT   \    <-- Widget Tests (Tampilan UI, Form, Error States)
             /----------\
            /     UT     \   <-- Unit Tests (Validasi Logika, Edge Cases, Fake Repos)
           /--------------\
```

- **Unit Tests (Paling Cepat & Murah):** Memeriksa aturan bisnis murni, algoritma sanitasi data, validasi masukan string, logika penomoran kuota cost control, dan pemetaan kode error HTTP tanpa menyentuh rendering UI.
- **Widget Tests (Menengah):** Memeriksa komponen visual, responsivitas form, simulasi gestur ketukan (`tap`), input teks (`enterText`), status loading, pesan validasi, dan isolasi layer render.
- **Integration Tests (Paling Komprehensif):** Memeriksa keselarasan seluruh modul dari awal hingga akhir (*end-to-end user journey*) pada emulator/device.

---

## 2. Matriks Rincian Skenario Pengujian

### Skenario 1: Kasus Normal (Happy Path)
| ID Skenario | Lapisan | Komponen yang Diuji | Tindakan (Act) | Ekspektasi Hasil (Assert) |
|---|:---:|---|---|---|
| `SC-HP-01` | Unit | `maskToken()` | Mengirim token JWT panjang (> 12 karakter) | Token dipotong menjadi 12 karakter pertama diakhiri `...` |
| `SC-HP-02` | Unit | `routeFromMessage()` | Menerima payload push notification dengan key `route` | Mengembalikan rute berawalan slash `/pengumuman/101` |
| `SC-HP-03` | Unit | `GetAnnouncementsUseCase` | Mengambil daftar pengumuman melalui fake repo | Mengembalikan daftar 2 pengumuman tanpa failure (`failure == null`) |
| `SC-HP-04` | Widget | `LoginPage` | Render awal halaman login | Ditemukan field email, field password, dan tombol 'Masuk' |
| `SC-HP-05` | Widget | `AnnouncementTile` | Render kartu pengumuman | Menampilkan judul, tanggal, kategori, dan terisolasi `RepaintBoundary` |
| `SC-HP-06` | Integration | `app_test.dart` | Input kredensial valid dan tap 'Masuk' | Berhasil login, navigasi otomatis berpindah ke `HomePage` |

---

### Skenario 2: Kasus Tepi (Edge Cases)
| ID Skenario | Lapisan | Komponen yang Diuji | Tindakan (Act) | Ekspektasi Hasil (Assert) |
|---|:---:|---|---|---|
| `SC-EC-01` | Unit | String Validation | Input string kosong `""`, spasi `"   "`, atau `\t\n` | `trim().isNotEmpty` mengembalikan `false` |
| `SC-EC-02` | Unit | Campus Email Validation | Input email non-Polinema (`user@gmail.com`) atau `@polinema.ac.id` tanpa prefix | Validasi domain kampus menolak input (`isFalse`) |
| `SC-EC-03` | Unit | Password Validation | Input password kurang dari 6 karakter (misal `'12345'`) | Validasi panjang menolak input (`isFalse`) |
| `SC-EC-04` | Unit | `maskToken()` | Mengirim token bernilai `null` atau string kosong | Mengembalikan string fallback aman `'Belum tersedia'` tanpa crash |
| `SC-EC-05` | Unit | AI Data Sanitizer | Prompt pengguna mengandung NIK 16-digit atau format HP Indonesia | Nilai digit disamarkan menjadi tag redaksi privasi |
| `SC-EC-06` | Unit | AI Cost Limiter | Jumlah pemanggilan harian mencapai batas kuota (30 kali) | Sistem menolak eksekusi prompt baru (`canSendRequest == false`) |
| `SC-EC-07` | Unit | Fake Repo Paginasi | Meminta halaman di luar batas dataset (`page = 99`) | Mengembalikan list kosong dengan flag `hasMore: false` tanpa exception |
| `SC-EC-08` | Widget | `LoginPage` Form | Tap tombol 'Masuk' saat form kosong | Form memvalidasi dan memunculkan error text merah pada masing-masing field |
| `SC-EC-09` | Widget | Password Toggle | Tap ikon mata (`Icons.visibility_outlined`) | Nilai `_obscurePassword` berbalik dan ikon berganti ke `visibility_off` |

---

### Skenario 3: Kasus Kegagalan & Penanganan Error (Failure & Resilience)
| ID Skenario | Lapisan | Komponen yang Diuji | Tindakan (Act) | Ekspektasi Hasil (Assert) |
|---|:---:|---|---|---|
| `SC-FL-01` | Unit | `MockableAnnouncementRepo` | Mensimulasikan server backend mengembalikan HTTP 500 | Mengembalikan `ServerFailure` dengan payload list kosong tanpa crash |
| `SC-FL-02` | Unit | `MockableAnnouncementRepo` | Mensimulasikan koneksi internet terputus | Mengembalikan `NetworkFailure` dengan pesan kesalahan ramah pengguna |
| `SC-FL-03` | Unit | `GetAnnouncementDetailUseCase` | Mencari pengumuman dengan ID kosong atau ID tidak terdaftar | Mengembalikan `ValidationFailure` atau `ServerFailure` (not found) |
| `SC-FL-04` | Unit | `getFriendlyErrorMessage()` | Memetakan `DioException` (401, 500, Connection Timeout) | Pesan ramah pengguna disajikan tanpa membocorkan token/stack trace |
| `SC-FL-05` | Unit | SWR Cache Resilience | Server down saat pemanggilan `getAnnouncementsWithCache` | Data dari cache memori tetap disajikan (`isFromCache: true`) |
| `SC-FL-06` | Widget | `LoginPage` Error Banner | Provider autentikasi melempar error login gagal | Muncul banner merah bertuliskan *'Email atau password salah'* |

---

## 3. Strategi Isolasi Dependensi: Fake Repository

Pengujian pada unit dan widget tidak boleh mengandalkan server backend sungguhan karena:
1. **Ketidakstabilan Jaringan:** Latensi jaringan dan fluktuasi sinyal membuat pengujian menjadi lambat (*slow*) dan tidak deterministik (*flaky*).
2. **Ketergantungan State Server:** Data pengumuman di server nyata dapat ditambah, diubah, atau dihapus oleh admin sewaktu-waktu.
3. **Kesulitan Simulasi Error:** Meniru kegagalan server (HTTP 500), timeout jaringan, atau token kedaluwarsa pada backend sungguhan sangat sulit dilakukan tanpa merusak data produksi.

### Implementasi Fake Repository:
Pada [`test/fake_repository_dependency_test.dart`](file:///c:/Users/louis/Semester%205/244107020071-mobile-course/12-week-12-testing-quality-assurance/test/fake_repository_dependency_test.dart), kami mengimplementasikan class `MockableAnnouncementRepository` yang mengimplementasikan interface `AnnouncementRepository`. Class ini menyediakan switch pengujian sederhana:
- `shouldThrowServerException`: Mengalihkan hasil menjadi `ServerFailure`.
- `shouldReturnNetworkFailure`: Mengalihkan hasil menjadi `NetworkFailure`.
- `announcements`: Mengisi dataset in-memory terkontrol.
- `delayMilliseconds`: Mensimulasikan latensi asinkron jika diperlukan.

---

## 4. Evaluasi Code Coverage (`lcov.info`)

Eksekusi perintah `flutter test --coverage` menghasilkan ringkasan cakupan baris kode:
- **Total Baris Kode yang Dievaluasi:** 1,339 baris
- **Total Baris Ter-cover (Hit):** 960 baris
- **Cakupan Rata-rata Aplikasi:** **71.70%**

### Tabel Cakupan Modul Utama:
| Modul / File | Baris Teruji (Hit) | Total Baris | Persentase | Status |
|---|:---:|:---:|:---:|:---:|
| `login_page.dart` | 84 | 87 | **96.6%** | Sangat Tinggi (Excellence) |
| `ai_service.dart` | 63 | 68 | **92.6%** | Sangat Tinggi |
| `announcement_providers.dart` | 46 | 51 | **90.2%** | Sangat Tinggi |
| `home_page.dart` | 164 | 187 | **87.7%** | Tinggi |
| `announcement_tile.dart` | 61 | 71 | **85.9%** | Tinggi |
| `chat_screen.dart` | 89 | 109 | **81.7%** | Tinggi |
| `announcement_page.dart` | 42 | 57 | **73.7%** | Cukup Baik |
| `chat_bubble.dart` | 45 | 62 | **72.6%** | Cukup Baik |
| `chat_providers.dart` | 46 | 74 | **62.2%** | Memenuhi Standar |
| `api_client.dart` | 45 | 80 | **56.2%** | Memenuhi Standar |
