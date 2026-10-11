# AI Challenge & Storage Trade-Off Analysis

Dokumen ini disusun untuk memenuhi **AI Challenge (Minggu 5 - Local Storage & Offline First)** pada mata kuliah Pemrograman Mobile.

---

## 1. Prompt AI yang Digunakan

Prompt berikut diajukan kepada AI assistant untuk mengeksplorasi opsi arsitektur penyimpanan lokal:

```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

---

## 2. Tabel Perbandingan Opsi Storage

| Kriteria | SharedPreferences | Hive (NoSQL) | sqflite (SQLite) | Drift (Moor) |
| :--- | :--- | :--- | :--- | :--- |
| **Model Data** | Key-Value primitif | Key-Value / Object Box (NoSQL) | Relasional (SQL Tables) | Relasional (Type-safe SQL/Dart) |
| **Kompleksitas Query** | Sangat Rendah (hanya get/set by key) | Rendah (filter in-memory/box scan) | Tinggi (SQL raw query, WHERE, ORDER BY, aggregate) | Sangat Tinggi (Type-safe SQL fluent API, JOIN, subquery) |
| **Kebutuhan Relasi** | Tidak mendukung | Tidak mendukung (manual linking) | Mendukung penuh (Foreign Key, JOIN) | Mendukung penuh (Relasi relasional kuat & auto-join) |
| **Reaktivitas (Stream)** | Tidak ada (manual polling/Notifier) | Mendukung (Watch Box) | Tidak ada bawaan (manual Riverpod invalidation) | Sangat Kuat (`watch()` reaktif berbasis Stream bawaan) |
| **Type-Safety** | Primitif saja (string, int, bool, double) | Lemah/Medium (TypeAdapter via code gen) | Rendah (Map<String, dynamic>, butuh parsing manual) | Sangat Tinggi (Generated Data Classes, compile-time check) |
| **Ukuran Boilerplate** | Sangat Minimal (`getInstance()`) | Rendah-Sedang (TypeAdapter & Hive.init) | Sedang (`openDatabase`, raw SQL CREATE TABLE, toMap/fromMap) | Tinggi (Code generation via `build_runner`, file `.g.dart`) |
| **Kemudahan Testing** | Sangat Mudah (`setMockInitialValues`) | Mudah (`Hive.init` mock directory) | Butuh injeksi `openDb` / in-memory DB / fake repo | Sangat Mudah (Native in-memory database tanpa mocking platform) |

---

## 3. Rekomendasi Penggunaan Final

| Kebutuhan Aplikasi | Pilihan Terpilih | Alasan & Justifikasi Teknis |
| :--- | :--- | :--- |
| **Preferensi Sederhana** (Dark mode, waktu terakhir dibuka) | **SharedPreferences** | Sangat ringan, tanpa overhead database engine, cocok untuk flag boolean dan timestamp string pendek, tidak memerlukan query kompleks. |
| **Koleksi Catatan & Antrean Sinkronisasi** (CRUD Notes, dirty flag) | **sqflite (SQLite)** | Teruji di industri mobile, engine SQLite bawaan OS tanpa beban dependensi besar, mendukung filtering efisien (`WHERE dirty = 1`), pengurutan cepat (`ORDER BY updated_at DESC`), serta transaksi atomik (`txn`). |

---

## 4. Perancangan Skema Data (1000+ Catatan & Antrean Sync)

Untuk menangani 1.000+ catatan secara efisien dengan strategi **Offline-First**, skema database dirancang sebagai berikut:

```sql
-- Tabel Catatan Utama
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    updated_at TEXT NOT NULL,
    dirty INTEGER NOT NULL DEFAULT 0
);

-- Indeks untuk mempercepat pencarian data kotor (antrean sinkronisasi)
CREATE INDEX idx_notes_dirty ON notes(dirty);

-- Indeks untuk mempercepat pengurutan timeline catatan terbaru
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);

-- Tabel Cache Sementara untuk REST API Posts (Cache-First Read)
CREATE TABLE cached_posts (
    id INTEGER PRIMARY KEY,
    payload TEXT NOT NULL,
    cached_at TEXT NOT NULL
);
```

### Penjelasan Skema:
1. **`dirty INTEGER NOT NULL DEFAULT 0`**:
   - `0`: Data di lokal identik dengan server (bersih/synced).
   - `1`: Data baru dibuat/diubah saat offline dan menunggu sinkronisasi (antrean sync).
2. **`idx_notes_dirty`**: Menghindari full-table scan ketika menghitung atau mengambil antrean catatan kotor (`SELECT COUNT(*) FROM notes WHERE dirty = 1`).
3. **`idx_notes_updated_at`**: Memastikan tampilan daftar catatan 1000+ baris tetap instan saat di-render.
4. **`cached_posts`**: Menyimpan payload JSON dari REST API agar halaman langsung menampilkan data seketika tanpa layar kosong (*cache-first*).

---

## 5. Verifikasi Kritis atas Rekomendasi AI (AI Verification Checklist)

| Pertanyaan Verifikasi | Hasil Evaluasi & Tindakan |
| :--- | :--- |
| **Apakah AI menempatkan daftar catatan di SharedPreferences?** | **DITOLAK**. SharedPreferences hanya untuk nilai primitif kecil. Menyimpan koleksi catatan dalam bentuk JSON string panjang akan menyebabkan serialisasi/deserialisasi lambat (blocking UI), tidak mendukung query parsial, dan rawan data corrupt saat crash. |
| **Apakah skema AI mendukung antrean sync (`dirty` / `updated_at`) atau hanya CRUD polos?** | **DIVERIFIKASI & DILENGKAPI**. Skema yang diajukan wajib menyertakan kolom `dirty` dan `updated_at` untuk mendukung sinkronisasi offline-first dengan resolusi konflik *last-write-wins*. |
| **Apakah klaim "real-time" AI didukung stream atau asumsi?** | **DIVERIFIKASI**. Pada SQLite murni (`sqflite`), pembaruan tampilan diatur menggunakan invalidasi Riverpod (`ref.invalidate(notesProvider)`). Drift memiliki stream bawaan, namun membutuhkan dependensi code generation yang berlebihan untuk skala mini project ini. |
| **Apakah estimasi boilerplate AI masuk akal?** | **DIVERIFIKASI**. Drift dan Hive membutuhkan `build_runner` yang memperlambat siklus build pemula. Pilihan kombinasi `SharedPreferences + sqflite` adalah yang paling seimbang antara fleksibilitas, performa, dan kesederhanaan pemeliharaan kode. |

---

## 6. Keputusan Final & Aturan Resolusi Konflik

1. **Stack Terpilih:**
   - **`SharedPreferences`** untuk pengaturan UI (tema gelap, last opened).
   - **`SQLite` (`sqflite`)** untuk repository catatan lokal dan tabel cache API.
   - **`Riverpod` (`AsyncNotifier`)** untuk state management reactive loading/error/data.
2. **Aturan Resolusi Konflik Sinkronisasi:**
   - **Last-Write-Wins (LWW) berdasarkan `updated_at`**: Jika terjadi perbedaan antara versi lokal dan server, catatan dengan timestamp `updated_at` paling baru yang akan dipertahankan.
