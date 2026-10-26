# 🔍 AI Review Challenge & Tabel Usulan vs Keputusan

**Mahasiswa:** Louis Judia  
**NIM:** 244107020071  
**Kelas:** TI-3F / Semester 5  
**Modul:** Minggu 09 – AI-Assisted Development / Vibe Coding  
**Proyek:** Fitur Pencarian & Filter Catatan (`week9_notes_app`)  

---

## 1. AI Review Prompt Challenge

Berikut adalah prompt pengujian review yang diajukan ke AI Coding Assistant sebagai simulasi *Senior Developer Code Review*:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: Feature-first (presentation -> domain <- data), Riverpod 3.x, SQLite + Dio.
Fokus: Kebenaran fungsional, arsitektur Clean Architecture, dan test coverage.
Abaikan style/formatting.
Beri 3 temuan konkret beserta levelnya (Blocker / Saran) dan alasan teknis mendalam.
```

---

## 2. Tanggapan & Tiga Temuan AI

AI Coding Assistant memberikan 3 temuan hasil peninjauan kode:

```text
Hasil Review Senior Dev:

1. [Temuan 1 - Saran Arsitektur]:
   Provider `filteredNotesProvider` menggabungkan `notesAsync` dan `searchQueryProvider`.
   Jika daftar catatan memiliki ribuan item, komputasi `filterNotes` pada UI thread dapat
   memblokir frame rendering. Disarankan memindahkan filter ke Isolate atau debouncing query.
   Level: SARAN OPTIMASI

2. [Temuan 2 - Blocker Fungsional]:
   Pada TextField pencarian, pemanggilan `updateQuery` dilakukan pada setiap ketikan karakter
   tanpa pembersihan spasi terisolasi di sisi use case. Bila ada catatan dengan spasi ganda
   atau user mengetik spasi tak sengaja di depan query (' flutter'), substring matching
   akan gagal jika filter domain tidak menerapkan .trim().
   Level: BLOCKER KEBENARAN

3. [Temuan 3 - Saran / Usulan Overkill]:
   Filter catatan sebaiknya dilakukan langsung di level query SQLite menggunakan perintah
   SQL `SELECT * FROM notes WHERE title LIKE '%query%'` setiap kali user mengetik karakter,
   agar memori HP hemat dan tidak perlu me-load semua objek Note ke Dart heap.
   Level: SARAN ARSITEKTUR
```

---

## 3. Evaluasi Kritis Temuan AI (Verifikasi Manusia)

Developer melakukan audit atas ketiga temuan tersebut:

### ✅ Temuan Terbukti Benar & Diperbaiki (Temuan 2 - Blocker)
* **Status:** **DITERIMA & DIIMPLEMENTASIKAN**
* **Analisis:** Temuan AI mengenai perlunya pembersihan karakter (`trim()`) pada use case terbukti sangat penting. Jika user mengetik spasi `'  flutter  '`, pencarian terhadap judul `'Rapat Proyek Flutter Polinema'` akan gagal jika use case hanya mengandalkan substring tanpa pemangkasan spasi.
* **Bukti Grep & Test:**
  Unit test berikut membuktikan kebenaran perbaikan:
  ```dart
  test('query dengan spasi di-trim otomatis', () {
    final result = filterNotes(sampleNotes, '  flutter  ');
    expect(result, hasLength(1));
    expect(result.first.id, 3);
  });
  ```
  Kode `cleanQuery = query.trim().toLowerCase()` memastikan validasi input selalu bersih.

---

### ❌ Temuan Ditolak dengan Alasan Teknis (Temuan 3 - Saran SQL Langsung)
* **Status:** **DITOLAK KERAS**
* **Alasan Teknis Tertulis:**
  1. **Konflik Arsitektur Offline-First & Cache In-Memory:** Aplikasi ini mengusung model *offline-first in-memory reactive stream* via Riverpod. Daftar catatan lokal sudah dimuat ke dalam memori aplikasi (`notesProvider`).
  2. **I/O Disk Thrashing:** Menjalankan `db.rawQuery()` ke disk SQLite pada setiap perubahan huruf (*onChanged*) akan memicu lonjakan I/O disk lokal yang tidak perlu dan mengharuskan *debouncing* kompleks serta penanganan *race condition* (query lama kembali setelah query baru selesai).
  3. **Ukuran Dataset:** Untuk aplikasi catatan personal (biasanya puluhan hingga ratusan catatan), penyaringan in-memory Dart membutuhkan waktu < 0.1 milidetik, jauh lebih cepat daripada latensi query SQLite (1-5 milidetik).
  4. **Testability:** Menyaring di domain murni Dart memungkinkan unit test berjalan instan tanpa mock framework database.

---

### 💡 Temuan 1: Saran Optimasi Debouncing (Diterima Bersyarat untuk Skalabilitas)
* **Status:** **DITERIMA SECARA KONSEPTUAL, TETAPI DISELESAIKAN LEWAT RIVERPOD**
* **Analisis:** Menggunakan `ref.watch(searchQueryProvider)` di dalam synchronous `Provider` Dart sudah sangat efisien. Riverpod secara otomatis meng-cache hasil filter selama query dan list catatan tidak berubah. Tidak diperlukan Isolate tambahan untuk dataset ringan karena overhead *spawning isolate* justru lebih besar daripada iterasi list sederhana.

---

## 4. Tabel Keputusan Per Berkas (Decisions Table)

| Lokasi Berkas | Layer Arsitektur | Usulan AI | Keputusan Pengembang | Alasan Teknis & Refactoring |
|---|---|---|---|---|
| `lib/domain/usecases/filter_notes_use_case.dart` | **Domain** | Gunakan `contains()` langsung tanpa trim | **Terima + Refactor** | Logika substring diterima, namun ditambah `.trim()` dan `.toLowerCase()`. File tetap 100% murni Dart tanpa import Flutter/Dio/SQLite. |
| `lib/pages/notes_page.dart` | **Presentation (State)** | Simpan query di local `setState` widget SearchBox | **Tolak + Tulis Manual** | Menggunakan `SearchQueryNotifier` dan `filteredNotesProvider` berbasis Riverpod agar state reaktif dan dapat di-override pada widget testing. |
| `lib/pages/notes_page.dart` | **Presentation (UI)** | Buat dialog pencarian terpisah | **Tolak + Tulis Manual** | Dibuat `TextField` modern persisten di bagian atas tab catatan lokal lengkap dengan tombol clear icon silang untuk UX yang lebih intuitif. |
| `lib/pages/notes_page.dart` | **Presentation (Empty State)** | Tampilkan teks merah 'Data tidak ada' | **Terima + Refactor** | Diubah menjadi komponen Empty State modern dengan `Key('search_empty_state')`, ikon `Icons.search_off_outlined`, dan teks dinamis penyebut query yang dicari. |
| `test/search_filter_test.dart` | **Testing** | Hanya 1 unit test sederhana | **Terima + Refactor** | Ditambahkan 4 unit test lengkap (case-insensitive, empty query, not found, trimmed) serta 1 widget test komprehensif menguji interaksi user. |
| `test/generate_screenshots_test.dart` | **Testing & Dok** | Screenshot manual via emulator | **Tolak + Tulis Otomatis** | Menggunakan RepaintBoundary test headless Flutter untuk merender PNG pixel-perfect 3 kondisi query ke folder `screenshots/`. |

---

## 5. Ringkasan Verifikasi Tiga Mesin

Seluruh berkas yang dihasilkan telah divalidasi dan lolos pengujian tanpa peringatan (*zero warnings*):

1. **Format:** `dart format --output=none --set-exit-if-changed .` -> **0 changed** (Lolos)
2. **Analysis:** `flutter analyze` -> **No issues found!** (Lolos)
3. **Automated Testing:** `flutter test` -> **All 15 tests passed!** (Lolos)
