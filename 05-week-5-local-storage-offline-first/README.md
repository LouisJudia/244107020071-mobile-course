# Week 5 — Local Storage & Offline-First Notes

**Mata kuliah / codelab:** Flutter Codelab Minggu 5  
**Topik:** Local Storage, Repository Pattern, Offline-First, Riverpod, dan Testing  

---

## 1. Tujuan Pembelajaran

Setelah menyelesaikan praktikum ini, aplikasi diharapkan mampu:

- menjelaskan perbedaan penyimpanan key-value, relasional, dan NoSQL di perangkat;
- menyimpan preferensi sederhana dengan `SharedPreferences`;
- menerapkan CRUD catatan dengan `SQLite` (`sqflite`) melalui repository lokal;
- menerapkan pola **offline-first**: cache-first read, dirty flag, dan antrean sinkronisasi;
- menampilkan state `loading`, `error`, `empty`, dan `success` dengan Riverpod;
- menguji repository lokal menggunakan repository palsu atau database in-memory.

---

## 2. Konsep Inti

### 2.1 Jenis Local Storage

| Kebutuhan | Pilihan | Contoh |
| --- | --- | --- |
| Pengaturan kecil key-value | `SharedPreferences` | tema gelap/terang, bahasa, waktu terakhir dibuka |
| Data terstruktur relasional | `SQLite` via `sqflite` | catatan, tugas, transaksi |
| NoSQL ringan embedded | `Hive` | cache objek, box sederhana |
| Relasional reaktif & type-safe | `Drift` | aplikasi besar dengan query kompleks + stream |

Pada codelab ini digunakan kombinasi `SharedPreferences` + `SQLite (sqflite)`.

### 2.2 Offline-First

Offline-first berarti aplikasi tetap bisa **dibaca dan ditulis** meski tidak ada internet, lalu disinkronkan ketika koneksi kembali.

Tiga mekanisme utamanya:

1. **Cache-first read**  
   Data lokal ditampilkan lebih dulu, lalu di-refresh dari jaringan di background.

2. **Dirty flag**  
   Setiap perubahan lokal yang belum terkirim ditandai dengan `dirty = 1`.

3. **Antrean sinkronisasi**  
   Data dirty diproses berurutan saat online. Konflik diselesaikan dengan aturan eksplisit, misalnya *last-write-wins* berdasarkan `updated_at`.

---

## 3. Setup Project

### 3.1 Buat project

```bash
flutter create week5_offline_notes
cd week5_offline_notes
flutter pub add flutter_riverpod shared_preferences sqflite path
```

### 3.2 Struktur folder

```text
lib/
├── main.dart
├── data/
│   ├── local/
│   │   ├── db.dart
│   │   └── note.dart
│   ├── prefs.dart
│   └── repositories/
│       └── note_repository.dart
└── pages/
    ├── settings_page.dart
    └── notes_page.dart
```

---

## 4. Praktikum 1 — SharedPreferences

### 4.1 Repository preferensi

Semua akses key-value dipusatkan di repository, bukan di widget.

**File:** `lib/data/prefs.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';

class PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> markOpenedNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
  }

  Future<String?> getLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedKey);
  }
}
```

### 4.2 Provider dan halaman pengaturan

Contoh penyambungan dengan Riverpod:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());
final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}
```

### 4.3 Kesalahan umum

- Memanggil `SharedPreferences.getInstance()` langsung di widget.
- Menyimpan banyak data koleksi ke SharedPreferences dalam bentuk JSON panjang.
- Tidak memisahkan repository dari UI.

---

## 5. Praktikum 2 — SQLite dan Repository Catatan

### 5.1 Model catatan

**File:** `lib/data/local/note.dart`

```dart
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,
      };

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
    );
  }
}
```

### 5.2 Pembuka database

**File:** `lib/data/local/db.dart`

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<Database> openNotesDb() async {
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, 'offline_notes.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL DEFAULT '',
          updated_at TEXT NOT NULL,
          dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE cached_posts(
          id INTEGER PRIMARY KEY,
          payload TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');
    },
  );
}
```

### 5.3 Repository data lokal

**File:** `lib/data/repositories/note_repository.dart`

```dart
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    final id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countDirty() async {
    final db = await _openDb();
    final rows =
        await db.rawQuery('SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }
}
```

### 5.4 Kenapa `openDb` di constructor?

Supaya test bisa menyuntikkan database palsu atau in-memory tanpa menyentuh SQLite sungguhan. Pola ini memudahkan pengujian repository secara terisolasi.

---

## 6. Praktikum 3 — Cache-First Read dan Sync

### 6.1 Cache-first untuk data API

Gunakan endpoint Minggu 4 (`GET /posts` dari JSONPlaceholder). Alurnya:

1. Ambil cache lokal dari tabel `cached_posts`.
2. Tampilkan cache segera agar UI tidak blank saat offline.
3. Refresh dari jaringan di background.
4. Simpan hasil baru untuk kunjungan berikutnya.

```dart
Future<List<Post>> loadPostsCacheFirst() async {
  final cached = await readCachedPosts();
  refreshPostsInBackground();
  return cached;
}
```

### 6.2 Sinkronisasi catatan dirty

Karena backend tulis belum tersedia, sinkronisasi disimulasikan dengan delay.

```dart
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;

  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
```

### 6.3 Simulasi offline yang deterministik

Selain mode pesawat sungguhan, gunakan toggle `forceOffline` pada provider agar demo dan testing tidak bergantung pada kondisi Wi-Fi.

Langkah observasi yang disarankan:

- matikan Wi-Fi atau aktifkan mode pesawat;
- buka aplikasi kembali;
- pastikan catatan tetap tampil;
- cek badge `dirty`;
- aktifkan kembali koneksi;
- jalankan sinkronisasi;
- pastikan badge kembali menjadi `0`;
- simpan screenshot sebelum dan sesudah ke folder `screenshots/`.

### 6.4 Aturan konflik

Gunakan satu aturan konflik dan tulis secara eksplisit di dokumentasi, misalnya:

> **last-write-wins** berdasarkan `updated_at`

Tanpa aturan konflik yang jelas, sinkronisasi dua arah bisa menimpa data secara diam-diam.

---

## 7. Rekomendasi Struktur UI

### Halaman `Settings`
- toggle tema gelap/terang
- info terakhir membuka aplikasi

### Halaman `Notes`
- daftar catatan lokal
- tombol tambah catatan
- tombol hapus catatan
- badge jumlah catatan `dirty`
- status kosong / loading / error / sukses

---

## 8. Riverpod State Pattern

Gunakan `AsyncValue` untuk memodelkan state:

- `loading`
- `error`
- `empty`
- `data`

Alur yang dianjurkan:

- UI hanya membaca provider
- provider memanggil repository
- repository mengelola SQLite / SharedPreferences
- exception platform diterjemahkan menjadi kegagalan yang mudah dipahami UI

---

## 9. Testing Repository

### Fokus pengujian
- repository tidak bergantung langsung pada UI;
- `openDb` bisa diganti dengan database palsu;
- `countDirty()` mengembalikan jumlah yang benar;
- `markAllSynced()` mengubah semua data dirty menjadi bersih.

### Contoh pendekatan
- gunakan database in-memory atau fake repository;
- uji operasi CRUD;
- uji sinkronisasi dan perubahan status `dirty`.

---

## 10. Checklist Pengerjaan

- [ ] Project Flutter berhasil dibuat
- [ ] `SharedPreferences` berjalan untuk tema dan last opened
- [ ] Database SQLite berhasil dibuat
- [ ] Model `Note` dan mapping `toMap/fromMap` berfungsi
- [ ] Repository catatan berhasil melakukan CRUD
- [ ] Badge `dirty` tampil dengan benar
- [ ] Cache-first read pada data API sudah diterapkan
- [ ] Sinkronisasi catatan kotor sudah disimulasikan
- [ ] Toggle `forceOffline` tersedia untuk demo
- [ ] Screenshot sebelum/sesudah sudah disimpan
- [ ] Repository lokal sudah diuji

---

## 11. Catatan Penting

- Jangan simpan semua data aplikasi ke `SharedPreferences`.
- Jangan akses SQLite langsung dari widget.
- Jangan menunggu jaringan untuk menampilkan data yang sudah ada di lokal.
- Selalu dokumentasikan keputusan teknis, terutama saat memilih storage dan aturan konflik.

---

## 12. Output yang Diharapkan

Setelah praktikum selesai, aplikasi sebaiknya mampu:

- menyimpan preferensi lokal;
- menampilkan catatan tanpa internet;
- menandai data yang belum tersinkron;
- melakukan sinkronisasi saat online;
- mempertahankan arsitektur yang mudah diuji dan dirawat.

---

## 14. Ringkasan

Minggu 5 menekankan bahwa aplikasi yang baik bukan hanya berjalan saat online, tetapi tetap berguna saat offline. Karena itu, storage harus dipilih sesuai kebutuhan:

- `SharedPreferences` untuk data kecil,
- `SQLite` untuk data relasional,
- repository untuk menjaga arsitektur tetap rapi,
- Riverpod untuk state management,
- dan pola offline-first untuk pengalaman pengguna yang stabil.

