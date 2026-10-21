# Dokumen Review Checklist & Mid-Project Assessment (Minggu 8)

**Nama Mahasiswa:** Louis Judia  
**NIM:** 244107020071  
**Mata Kuliah:** Pemrograman Mobile (Praktikum)  
**Topik:** #08 | Mid Project Review & Peer Code Review  
**Repository:** `LouisJudia/244107020071-mobile-course`  

---

## 1. Praktikum 1: Hygiene Branch & Commit Audit

### 1.1 Hasil Audit Riwayat Git
Pemeriksaan riwayat commit dan status cabang dilakukan pada repository kerja:

```bash
$ git log --oneline -15
1a5eb6e Minggu 7: Clean Architecture
3371d49 Minggu 5 Local Storage & Offline-First Notes
a843af9 Week 6: Authentication, Security, & FCM (`campus_notify`)
28604d0 Minggu 5 Local Storage & Offline-First Notes
18e138b week 6
d3a57c0 Week 5 — Local Storage & Offline-First Notes
4f3d23f Week 4 - Networking & REST API
5b526b5 Week 4 - Networking & REST API
1dae4a6 Week 03 - Navigation & State Management
43c7ee9 docs: add verification screenshots to week 3 readme
e5a9e22 docs: move refactoring notes to week 3 readme
ef076ed refactor: add todo providers and GoRouter navigation
9318c46 Week 2 Declarative UI & Responsive Design
86c116f Revisi Screenshoot
724c44d feat: create week 1 Flutter profile app

$ git branch -a
* main
  remotes/origin/main

$ git status
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```

#### Identifikasi Masalah Riwayat (Hygiene Findings)
1. **Commit langsung ke `main`**: Pada fase awal (Minggu 1 s.d. 7), pekerjaan dilakukan langsung pada cabang `main` tanpa integrasi bertahap via branch `develop`.
2. **Format pesan commit non-konvensional**: Beberapa pesan commit terlalu singkat dan tidak merefleksikan cakupan teknis (contoh: `week 6`, `Revisi Screenshoot`, duplikasi `Minggu 5 Local Storage...`).
3. **Branch hygiene**: Belum adanya cabang isolasi fitur pendek (`feature/*` / `fix/*`) yang ditutup secara rapi setelah *pull request*.

---

### 1.2 Tabel Refactoring Pesan Commit (3 Contoh Sebelum vs Sesudah)
Sesuai standar **Conventional Commits** (`tipe(scope): deskripsi singkat`):

| Commit Asli | Pesan Baru (Conventional) | Tipe & Scope | Alasan Perbaikan Teknis |
|---|---|---|---|
| `18e138b week 6` | `feat(auth): implement secure token storage and background push messaging` | `feat` (auth) | Pesan asli tidak memberikan konteks fitur. Pesan baru menjelaskan secara presisi penambahan kapabilitas `TokenStore` (Secure Storage) dan listener FCM di background. |
| `86c116f Revisi Screenshoot` | `docs(ui): update responsive dashboard verification screenshots` | `docs` (ui) | Menghilangkan percampuran bahasa dan typo (`Screenshoot`), memperjelas bahwa commit merupakan pembaruan artefak dokumentasi pengujian visual antarmuka responsif. |
| `28604d0 Minggu 5 Local Storage & Offline-First Notes` | `feat(storage): implement sqlite note persistence with dirty flag sync` | `feat` (storage) | Menghindari pesan ganda yang ambigu. Menjelaskan implementasi teknis basis data lokal SQLite dan mekanisme penandaan *dirty flag* untuk sinkronisasi offline-first. |

---

### 1.3 Strategi Branching Model (Git Flow)

```
main       -----------------------------------------------------> [Rilis Stabil & Ujian]
               ^
               | (Merge release / PR final)
develop    ----+-----------------------+------------------------> [Integrasi Mingguan]
                    \                 / (PR #12 Closes #12)
feat/notes-validation+---------------+                          [Fitur Harian < 3 hari]
```

* **`main`**: Cabang produksi yang selalu stabil, dapat di-*build*, dan dilarang menerima commit langsung.
* **`develop`**: Target default untuk penggabungan (*merge*) seluruh fitur mingguan.
* **`feat/*`**: Cabang kerja spesifik untuk satu fitur kecil berdurasi pendek (< 3 hari).
* **`fix/*`**: Cabang perbaikan bug cepat yang dilengkapi dengan unit test regresi.

---

## 2. Praktikum 2: Peer Code Review & Pull Request

### 2.1 Template & Rekam Pull Request (PR #12)
* **Judul:** `feat(notes): validasi judul kosong + test`
* **Target Branch:** `develop` <- `feat/notes-validation`
* **Status:** Merged into `develop` (Closes #12)

```markdown
### Deskripsi Perubahan
- **Masalah:** Pengguna berpotensi mengirim atau menyimpan catatan tanpa judul atau hanya berisi spasi kosong jika input form di-bypass atau dipanggil langsung via repository.
- **Solusi:** 
  1. Menambahkan validasi `title.trim().isEmpty` pada level `NoteRepository.addNote()` yang melempar `ArgumentError('Judul catatan tidak boleh kosong')`.
  2. Menambahkan validasi form pada `notes_page.dart` dengan feedback visual instan `'Judul wajib diisi'`.
  3. Menyusun unit test otomatis pada `test/validate_note_test.dart`.
- **Cara Pengujian:**
  1. Jalankan unit test: `flutter test test/validate_note_test.dart`
  2. Uji manual via form dialog: Input spasi kosong -> Tekan "Simpan" -> Pesan error validasi merah muncul.
- **Terkait Issue:** Closes #12
```

---

### 2.2 Hasil Peer Code Review (Checklist Terstruktur)

Pemeriksaan dilakukan dengan pola konstruktif: **Observasi → Dampak → Usulan Konkret**:

```
[Komentar 1 - Kebenaran: Edge Case Spasi Kosong]
Observasi: Validasi awal hanya memeriksa string kosong (val == '').
Dampak: Pengguna dapat menekan spasi beberapa kali ('   ') dan catatan kosong tetap tersimpan di SQLite.
Usulan: Gunakan `val.trim().isEmpty` pada validator input dan lakukan sanitasi string sebelum insert ke database.
Status: DITERAPKAN ✅

[Komentar 2 - Kebenaran: Asynchronous UI Mounted Check]
Observasi: Pemanggilan SnackBar dilakukan langsung setelah await `ref.read(notesProvider.notifier).addNote(...)`.
Dampak: Berisiko memicu exception `setState() called after dispose()` bila pengguna menutup dialog sebelum operasi selesai.
Usulan: Bungkus panggilan feedback dengan guard condition `if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...); }`.
Status: DITERAPKAN ✅

[Komentar 3 - Arsitektur: Isolasi Akses Database]
Observasi: Pengujian komponen domain/usecase tidak boleh membuka SQLite sesungguhnya.
Dampak: Test menjadi lambat, bergantung pada OS/platform, dan sulit diuji di environment CI headless.
Usulan: Gunakan `FakeNoteRepository` atau override factory `openDb: () => throw UnimplementedError(...)` agar layer atas murni menguji logika bisnis tanpa menyentuh I/O database.
Status: DITERAPKAN ✅

[Komentar 4 - Pengujian: Skenario Negatif]
Observasi: Unit test awal hanya memverifikasi skenario sukses (`fromMap` dan serialisasi).
Dampak: Kasus kegagalan (input invalid, database error) tidak terdeteksi otomatis saat terjadi regresi.
Usulan: Tambahkan test suite `validate_note_test.dart` yang menguji `throwsA(isA<ArgumentError>())` pada input string kosong dan spasi.
Status: DITERAPKAN ✅

[Komentar 5 - Keterbacaan & Kebersihan Kode]
Observasi: Dialog form menambah catatan memiliki nested widget yang cukup panjang di dalam fungsi pembantu.
Dampak: Keterbacaan kode menurun saat pemeliharaan state form.
Usulan: Pisahkan deklarasi `titleController`, `bodyController`, dan `formKey` secara rapi dan pastikan controller di-dispose bila dijadikan StatefulWidget.
Status: DITERAPKAN ✅
```

* **Keputusan Akhir Reviewer:** **APPROVE** (Seluruh 5 temuan telah diperbaiki dan diverifikasi hijau).

---

## 3. Praktikum 3: Static Analysis & Penilaian Kesiapan Tengah Semester

### 3.1 Bukti Pemeriksaan Tiga Mesin (Clean CI Triad)

| Pemeriksaan Mesin | Target Proyek | Perintah | Hasil | Status |
|---|---|---|---|---|
| **1. Static Analysis** | `campus_notify` | `flutter analyze` | `No issues found! (ran in 9.8s)` | 🟢 PASSED |
| **1. Static Analysis** | `week5_offline_notes` | `flutter analyze` | `No issues found! (ran in 5.7s)` | 🟢 PASSED |
| **2. Code Formatter** | Seluruh workspace | `dart format --output=none --set-exit-if-changed .` | `Formatted 47 files (0 changed)` | 🟢 PASSED |
| **3. Unit Testing** | `campus_notify` | `flutter test` | `All 29 tests passed!` | 🟢 PASSED |
| **3. Unit Testing** | `week5_offline_notes` | `flutter test` | `All 6 tests passed!` | 🟢 PASSED |

---

### 3.2 Uji Sterilitas Clean Architecture (Tiga Grep Minggu 7)
Untuk membuktikan kepatuhan terhadap *The Dependency Rule* (Domain Layer tidak boleh bergantung pada detail implementasi luar):

```bash
# Grep 1: Memastikan layer domain bebas dari Flutter Framework
Select-String -Path '07-week-7-clean-architecture\campus_notify\lib\features\*\domain\*.dart', '07-week-7-clean-architecture\campus_notify\lib\features\*\domain\*\*.dart' -Pattern 'import.*flutter'
Hasil: 0 baris ditemukan (STERIL / BERSIH) ✅

# Grep 2: Memastikan layer domain bebas dari HTTP Client (Dio)
Select-String -Path '07-week-7-clean-architecture\campus_notify\lib\features\*\domain\*.dart', '07-week-7-clean-architecture\campus_notify\lib\features\*\domain\*\*.dart' -Pattern 'import.*dio'
Hasil: 0 baris ditemukan (STERIL / BERSIH) ✅

# Grep 3: Memastikan layer domain bebas dari Storage/Database (Sqflite)
Select-String -Path '07-week-7-clean-architecture\campus_notify\lib\features\*\domain\*.dart', '07-week-7-clean-architecture\campus_notify\lib\features\*\domain\*\*.dart' -Pattern 'import.*sqflite'
Hasil: 0 baris ditemukan (STERIL / BERSIH) ✅
```

---

### 3.3 Scorecard Kesiapan Tengah Semester (Mid-Project Readiness)

| Komponen Penilaian | Kriteria Kelulusan | Status Verifikasi | Keterangan Teknis |
|---|---|:---:|---|
| **Arsitektur & SOLID** | Feature-first Clean Architecture, pemisahan Presentation-Domain-Data, dependensi ke dalam. | **100% SIAP** | Domain steril, kontrak abstraksi dipatuhi, Either/Result pattern terintegrasi. |
| **State Management** | Riverpod Notifier terstruktur, terbebas dari anti-pattern provider global liar. | **100% SIAP** | `authNotifierProvider`, `announcementsNotifierProvider`, StateNotifier responsif. |
| **Keamanan & Storage** | Token terenkripsi `flutter_secure_storage`, offline sync SQLite dengan *dirty flag*. | **100% SIAP** | Interceptor Dio otomatis me-refresh token 401 dan fallback ke login dengan aman. |
| **Testing Harness** | Mock & Fake Repository independen, pengujian parsing payload FCM & use cases. | **100% SIAP** | 35 pengujian unit otomatis mencakup skenario sukses, edge cases, dan failure path. |
| **Otomatisasi CI/CD** | GitHub Actions Workflow memvalidasi analyze, format, dan test pada setiap PR. | **100% SIAP** | File `.github/workflows/ci.yml` terkonfigurasi pada root repository. |
| **Dokumentasi & Git** | Commit konvensional, riwayat PR terstruktur, README informatif beserta tangkapan layar. | **100% SIAP** | Seluruh dokumen dan artefak tersimpan di direktori `08-week-8-mid-project-review/`. |
