# Dokumentasi AI Prompt Challenge & Verifikasi Keputusan Review

**Nama Mahasiswa:** Louis Judia  
**NIM:** 244107020071  
**Mata Kuliah:** Pemrograman Mobile (Praktikum)  
**Dokumen:** #08 | AI Review vs. Human Technical Decision  

---

## 1. Prompt AI Challenge
Prompt berikut dijalankan pada AI coding assistant untuk mereview kode pull request dan arsitektur proyek:

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

---

## 2. Output Awal Review AI (5 Temuan Teratas)

### Temuan AI #1 (Level: Blocker - Kebenaran)
* **Kategori:** *Data Integrity & Edge Cases*
* **Observasi AI:** Pada fungsi penyimpanan catatan `NoteRepository.addNote()`, validasi string kosong hanya mengandalkan form UI. Jika fungsi dipanggil dari background sync atau modul lain secara langsung, judul catatan yang hanya terdiri dari string kosong atau karakter spasi (`'   '`) tetap akan tersimpan ke dalam tabel SQLite dengan `dirty = 1`.
* **Usulan AI:**
```dart
Future<Note> addNote({required String title, String body = ''}) async {
  final cleanTitle = title.trim();
  if (cleanTitle.isEmpty) {
    throw ArgumentError('Judul catatan tidak boleh kosong');
  }
  final db = await _openDb();
  // ... simpan ke db
}
```

---

### Temuan AI #2 (Level: Saran - Ketahanan Error)
* **Kategori:** *Robustness & Failure Handling*
* **Observasi AI:** Pada implementasi remote data source pengumuman, konversi JSON mentah ke model data berisiko mengalami runtime exception bila server mengembalikan format yang tidak sesuai ekspektasi (misalnya `response.data` berupa map bukan list).
* **Usulan AI:**
```dart
// Pastikan parsing memvalidasi tipe sebelum mapping
if (response.data is! List) {
  throw const FormatException('Payload pengumuman bukan merupakan daftar array');
}
```

---

### Temuan AI #3 (Level: Blocker - Usulan Arsitektur Eksternal)
* **Kategori:** *Error Reporting & Presentation coupling*
* **Observasi AI:** Use case `GetAnnouncementDetailUseCase` di domain layer hanya mengembalikan objek `Either<AnnouncementFailure, Announcement>`. Agar pengguna mendapatkan dialog alert peringatan instan saat terjadi kegagalan jaringan, use case disarankan menerima parameter `BuildContext` dan mengimpor `package:flutter/material.dart` untuk memanggil `showDialog()` secara langsung.
* **Usulan AI:**
```dart
import 'package:flutter/material.dart'; // Usulan AI di domain layer

class GetAnnouncementDetailUseCase {
  Future<Announcement?> execute(BuildContext context, String id) async {
    // ... panggil repo, jika error langsung:
    // showDialog(context: context, builder: (_) => AlertDialog(...));
  }
}
```

---

### Temuan AI #4 (Level: Saran - Cakupan Pengujian)
* **Kategori:** *Unit Testing Coverage*
* **Observasi AI:** Pengujian unit model `Note` saat ini hanya menguji skenario positif (input field valid) dan kegagalan database tiruan. Belum ada pengujian otomatis untuk memverifikasi penolakan input judul kosong atau spasi murni pada `addNote`.
* **Usulan AI:**
```dart
test('addNote melempar ArgumentError jika judul hanya spasi', () async {
  final repo = NoteRepository(openDb: () => throw UnimplementedError());
  expect(() => repo.addNote(title: '   '), throwsA(isA<ArgumentError>()));
});
```

---

### Temuan AI #5 (Level: Blocker - Usulan Model Active Record)
* **Kategori:** *Domain Model Persistence*
* **Observasi AI:** Entity dan Model terpisah dianggap terlalu rumit. AI menyarankan menggabungkan entity domain dengan package `sqflite` sehingga model dapat menyimpan dirinya sendiri langsung ke database SQLite via method `note.save()`.
* **Usulan AI:**
```dart
import 'package:sqflite/sqflite.dart';

class Note {
  // ... field
  Future<void> save(Database db) async {
    await db.insert('notes', toMap());
  }
}
```

---

## 3. Checklist Verifikasi & Analisis Teknis Manusia

Pemeriksaan kritis dilakukan sebelum menerima atau menolak setiap saran AI:

| No | Temuan AI | Hasil Verifikasi Empiris | Status Keputusan | Argumen Teknis Pengambilan Keputusan |
|---|---|---|:---:|---|
| **1** | Validasi judul kosong di level repository | Terbukti benar melalui reproduksi kode. Sanitasi form UI saja tidak cukup untuk menjamin integritas data di layer storage. | **DITERIMA & DITERAPKAN** ✅ | Menjaga invariant data pada modul offline. Diterapkan di `NoteRepository.addNote()` dan diverifikasi via unit test. |
| **2** | Validasi tipe array respons API remote | Terbukti benar. Kegagalan serialisasi tipe data harus ditangkap dan dibungkus menjadi `AnnouncementFailure`. | **DITERIMA & DITERAPKAN** ✅ | Menjaga prinsip bahwa layer domain tidak boleh menerima runtime crash yang tidak tertangani. Selaras dengan arsitektur fail-safe. |
| **3** | Impor Flutter & `BuildContext` di layer Domain | **PELANGGARAN FATAL DEPENDENCY RULE!** Layer domain wajib murni Dart (*pure Dart*). | **DITOLAK DENGAN TEGAS** ❌ | UI dialog dan `BuildContext` adalah hak eksklusif Presentation Layer. Jika domain mengimpor Flutter, uji usecase terisolasi tanpa emulator/widget runner akan mustahil dilakukan dan melanggar prinsip *Separation of Concerns*. |
| **4** | Penambahan unit test untuk edge case spasi | Terbukti perlu. Sebelumnya belum ada test otomatis untuk input spasi saja. | **DITERIMA & DITERAPKAN** ✅ | Dibuat file pengujian khusus `validate_note_test.dart` dengan 2 kasus uji yang lulus 100%. |
| **5** | Pola Active Record (Entity mengimpor `sqflite`) | **PELANGGARAN CLEAN ARCHITECTURE!** Entity tidak boleh tahu menahu tentang database engine. | **DITOLAK DENGAN TEGAS** ❌ | Pola Active Record mengikat entitas bisnis ke SQLite secara permanen. Clean Architecture mengharuskan entitas murni (*Plain Old Dart Object*), sementara persistensi didelegasikan ke `Repository Pattern` di Data Layer. |

---

## 4. Rangkuman Pertanggungjawaban Teknis

1. **Jumlah Temuan Diterima:** 3 temuan (Temuan #1, #2, dan #4).  
   * **Bukti Eksekusi:** Terbukti lulus uji pada `validate_note_test.dart` dan `announcement_usecases_test.dart`.
2. **Jumlah Temuan Ditolak:** 2 temuan (Temuan #3 dan #5).  
   * **Bukti Grep Sterilitas:** Layer domain tetap 100% steril dari import `package:flutter/...` dan `package:sqflite/...`.
3. **Pelajaran Kunci:**  
   AI sangat mahir mendeteksi *defensive programming edge cases* (seperti sanitasi string dan tipe data), namun memiliki kecenderungan memberikan usulan jalan pintas (*quick dirty hacks*) yang merusak arsitektur jangka panjang (seperti membocorkan `BuildContext` ke domain atau mengawinkan entity dengan database engine). Tanggung jawab integritas arsitektur tetap berada sepenuhnya di tangan perekayasa perangkat lunak.
