# Laporan Temuan Profiling Awal (Baseline Performance Findings)

**Mata Kuliah:** Pemrograman Mobile (Course 244107020071)  
**Modul:** Minggu 11 - Performance Optimization (Optimasi Performa)  
**Aplikasi:** Campus Notify (`campus_notify`)  
**Platform Uji:** Flutter 3.38.5 • Windows / Android Emulation • Profile Mode  
**Tanggal Profiling:** 10 November 2026  

---

## 1. Ringkasan Eksekutif

Sebelum dilakukan optimasi pada Minggu 11, aplikasi `Campus Notify` telah mengintegrasikan fitur Autentikasi JWT, Push Notifications (FCM), Clean Architecture, State Management Riverpod, dan Asisten AI Gemini. Namun, evaluasi baseline menggunakan **Flutter DevTools (Performance, CPU Profiler, dan Memory Inspector)** mengungkapkan sejumlah *bottleneck* performa yang signifikan, khususnya pada halaman dashboard (`HomePage`) dan daftar pengumuman berukuran besar:

1. **Rebuild Cascade (Semesta):** Pemanggilan `ref.watch(savedSessionProvider)` di level atas `HomePage` menyebabkan seluruh widget tree (termasuk list, header, search bar, dan tombol aksi) di-*rebuild* ulang secara berulang meskipun hanya ada perubahan status kecil.
2. **Jank saat Scrolling:** Render item daftar menggunakan widget raksasa tanpa batasan isolasi paint (`RepaintBoundary`) mengakibatkan *raster thread* bekerja keras melakukan repaint menyeluruh setiap kali layar bergeser 1 piksel.
3. **Memory Spikes akibat Bitmap Raksasa:** Gambar thumbnail pengumuman dirender pada resolusi penuh (full bitmap decoding) tanpa parameter downsampling ukuran memori (`memCacheWidth` / `memCacheHeight`), menyebabkan lonjakan heap memory hingga **142+ MB**.
4. **Redundant Network Requests:** Data pengumuman selalu diambil ulang melalui jaringan HTTP setiap kali halaman dimuat tanpa mekanisme *caching* lokal atau interceptor, meningkatkan latensi jaringan dan konsumsi kuota pengguna.

---

## 2. Metodologi Profiling

Profiling baseline dilakukan dengan prosedur baku:
- **Build Mode:** Profile Mode (`flutter run --profile`) untuk memastikan kode dikompilasi AOT (Ahead-Of-Time) dan tidak terpengaruh overhead `debug` assertions.
- **Perangkat Profiling:** Profiling dilakukan di lingkungan desktop Windows dan simulator 412x892 @ 420dpi.
- **Instrumen:** Flutter DevTools (Performance View, Flame Chart, Memory Timeline, Allocation Profile, Network Profiler).
- **Skenario Pengujian:**
  1. *App Cold Start*: Waktu pemuatan awal dan inisialisasi sesi.
  2. *Feed Scrolling*: Scrolling cepat (fling gesture) menyusuri 50 item pengumuman untuk merekam drop frames dan jank.
  3. *AI Interaction*: Streaming respons AI dan indikator mengetik (typing indicator).

---

## 3. Temuan Detail Berdasarkan Instrumen

### A. Flame Chart & Timeline Profiling (DevTools Performance)
- **Frame Rendering Times:**
  - Rata-rata frame time saat scrolling: **24.8 ms – 33.2 ms** (melebihi batas ambang 16.6 ms untuk 60 FPS).
  - Terdeteksi sejumlah **Jank Frames** (merah/oranye di DevTools Timeline) dengan frame duration mencapai **42.5 ms** (setara dengan drop ke 23 FPS).
- **Beban UI Thread vs Raster Thread:**
  - *UI Thread Time:* Mengalami bottleneck hingga **18.4 ms** saat `build()` dipanggil berulang kali untuk setiap widget `Card` pengumuman yang tidak bermoised (`const`).
  - *Raster (GPU) Thread Time:* Mencapai **15.6 ms** karena tidak adanya pemisahan layer paint; seluruh canvas di-*repaint* ulang bersama latar belakang gradien.

### B. Memory Heap Analysis (DevTools Memory)
- **Baseline Heap Allocation:** **142.4 MB** saat memuat 20 item pengumuman bergambar.
- **Penyebab Utama:**
  - Setiap gambar thumbnail berukuran asli ~1920x1080 (2.07 MP) didecode secara mentah ke format RGBA 32-bit di memori:
    $$\text{Memori per gambar} = 1920 \times 1080 \times 4\text{ bytes} \approx 8.29\text{ MB}$$
  - Memuat 10 gambar saja menyedot memori bitmap hingga **82.9 MB** murni untuk *image cache*, memicu garbage collection (GC) *thrashing* yang menyebabkan stuttering visual.

### C. Analisis Rebuild & State Management
- `ref.watch(savedSessionProvider)`: Mengembalikan objek `AsyncValue<AuthSession?>`. Perubahan internal apa pun pada provider sesi memicu rebuild seluruh `HomePageBody`.
- Ketiadaan *widget extraction*: Komponen sapaan (`UserGreetingBanner`) dan list tile berada dalam satu metode build raksasa (`_HomePageState.build`), mencegah Flutter framework melakukan sub-tree pruning.

### D. Network Bottleneck
- Ketiadaan *In-Memory Repository Cache*: Setiap kali user kembali ke `HomePage` dari halaman detail atau AI screen, HTTP request `GET /api/announcements` dieksekusi ulang secara sinkron.
- Ketiadaan *Pagination*: Dataset ditarik sekaligus (unbounded query) sehingga payload JSON membengkak seiring bertambahnya jumlah pengumuman di database kampus.

---

## 4. Matriks Ringkasan Masalah & Rencana Aksi

| No | Gejala / Bottleneck | Akar Masalah | Komponen Terdampak | Rencana Solusi |
|---|---|---|---|---|
| 1 | UI Thread Jank (24-33 ms) | Rebuild semesta akibat `ref.watch` global | `home_page.dart` | Granular `ref.watch(...select())` & extract widget |
| 2 | Raster Thread Overload | Repaint menyeluruh setiap scroll | `HomePage` list cards | Bungkus `AnnouncementTile` dengan `RepaintBoundary` |
| 3 | Memory Spikes (142+ MB) | Full-size bitmap decoding | Image rendering | Gunakan `cached_network_image` + `memCacheWidth/Height` |
| 4 | Latensi & UI Kosong | Ketiadaan offline/local cache | `announcement_repository_impl` | Implementasi pola *Stale-While-Revalidate* (SWR) |
| 5 | Network Overload | Seluruh dataset dimuat sekaligus | `announcement_remote_data_source` | Implementasi *Lazy Loading* & infinite scroll pagination |
| 6 | Transient Network Flakiness | Kegagalan request langsung throw error | `api_client.dart` | Tambahkan `DioCacheInterceptor` & `DioRetryInterceptor` |

---

## 5. Kesimpulan Profiling Baseline

Kondisi baseline membuktikan bahwa penambahan fitur-fitur modern (seperti AI, push notifications, dan media kaya) tanpa rekayasa performa yang cermat langsung menimbulkan *degradasi pengalaman pengguna (UX)* berupa lag visual, konsumsi memori berlebih, dan ketergantungan jaringan yang rapuh. Langkah-langkah optimasi terstruktur pada Minggu 11 difokuskan untuk menyelesaikan akar masalah tersebut secara komprehensif.

