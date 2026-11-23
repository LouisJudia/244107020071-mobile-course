# 🚀 Minggu 13: CI/CD & Otomatisasi (Continuous Integration & Delivery)

**Mahasiswa:** Louis Judia  
**NIM:** 244107020071  
**Kelas:** TI - 3F / Semester 5  
**Mata Kuliah:** Pemrograman Mobile  
**Status Pipeline CI:** ![Flutter CI](https://github.com/LouisJudia/244107020071-mobile-course/actions/workflows/flutter-ci.yml/badge.svg)

---

## 📌 Ringkasan Modul

Modul Minggu 13 berfokus pada implementasi pipeline **Continuous Integration & Continuous Delivery (CI/CD)** otomatis menggunakan **GitHub Actions** untuk proyek aplikasi Flutter *CampusNotify*.

### Capaian Pembelajaran & Hasil Praktikum:
1. **Otomatisasi Linting, Formatting, dan Testing:**
   - Standar formatting terverifikasi via `dart format --set-exit-if-changed .`.
   - Analisis statis terintegrasi via `flutter analyze`.
   - Menjalankan 77 skenario pengujian otomatis (*unit*, *widget*, dan *integration tests*) secara headless dengan coverage report.
2. **Automated Android Build Artifacts:**
   - Kompilasi otomatis file **Release APK** (`app-release.apk`) untuk instalasi dan uji internal.
   - Kompilasi otomatis file **Release Android App Bundle** (`app-release.aab`) untuk distribusi Google Play Store.
   - Pengunggahan otomatis artefak ke GitHub Actions Artifacts (`android-builds`) dengan masa retensi 7 hari.
3. **Semantic Versioning & Git Release Flow:**
   - Konfigurasi versi semantik `1.3.0+13` pada `pubspec.yaml` (`versionName: 1.3.0`, `versionCode: 13`).
   - Panduan Git Tagging (`v1.3.0`) dan mitigasi keamanan kredensial/secrets.

---

## 📂 Struktur Direktori Proyek

```
13-week-13-ci-cd-automation/
├── .github/workflows/
│   ├── flutter-ci.yml               # Workflow spesifik build & test Minggu 13
│   └── ci.yml                       # Workflow verifikasi root multi-week
├── android/                         # Konfigurasi native Android (Java 17, desugaring enabled)
├── lib/
│   ├── ai/                          # SobatKampus AI & Gemini API Integration
│   ├── core/                        # Formatting, clean architecture utilities
│   ├── data/                        # Repositories, local storage, API adapters
│   ├── domain/                      # Use cases, models, entities
│   ├── messaging/                   # Push notification service adapter
│   ├── presentation/                # Screens, state management, optimized UI
│   └── main.dart                    # Application entry point
├── test/                            # 77 Unit, Widget, dan Integration Tests
├── docs/
│   ├── ci-cd-pipeline.md            # Dokumentasi lengkap pipeline, SemVer & refleksi
│   └── ai-log.md                    # Catatan engineering & pemecahan masalah AI
├── pubspec.yaml                     # version: 1.3.0+13
└── README.md                        # Panduan eksekusi & ikhtisar modul
```

---

## ⚡ Panduan Eksekusi Lokal

Sebelum memicu commit ke GitHub, seluruh pemeriksaan dapat dijalankan secara lokal dengan langkah-langkah berikut:

### 1. Format Kode
```bash
dart format --output=none --set-exit-if-changed .
```

### 2. Analisis Statis
```bash
flutter analyze --no-fatal-infos
```

### 3. Eksekusi Pengujian Otomatis
```bash
flutter test --coverage
```

### 4. Build Binary Android Release
```bash
# Build Standalone Release APK
flutter build apk --release

# Build Google Play App Bundle (AAB)
flutter build appbundle --release
```

---

## 📦 Artefak Rilis yang Dihasilkan

Setelah pipeline GitHub Actions selesai berjalan di branch `main` atau `develop`, artefak build dapat diunduh langsung dari tab **Actions $\rightarrow$ Summary $\rightarrow$ Artifacts**:

| Nama Artefak | Format | Path Output | Kegunaan |
|---|---|---|---|
| `app-release.apk` | APK (~52 MB) | `build/app/outputs/flutter-apk/` | Instalasi sideloading manual & uji coba perangkat QA/Staging |
| `app-release.aab` | AAB (~50 MB) | `build/app/outputs/bundle/release/` | Format resmi pengunggahan ke Google Play Console |

---

## 📖 Dokumentasi Terkait
- [Dokumentasi Lengkap Pipeline CI/CD & Jawaban Refleksi Codelab](docs/ci-cd-pipeline.md)
- [Catatan Rekayasa & Log Asistensi AI](docs/ai-log.md)
