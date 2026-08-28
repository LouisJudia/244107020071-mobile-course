# Week 1 - Mobile Development Ecosystem & Flutter Refresh

Dokumentasi praktikum dan tugas minggu pertama mata kuliah **Pemrograman Mobile**.

---

## Hot Reload vs Hot Restart

Selama praktikum, saya mempelajari dua fitur yang sering digunakan saat mengembangkan aplikasi Flutter.

- **Hot Reload (r)** digunakan untuk melihat perubahan tampilan secara langsung tanpa menghilangkan data yang sedang berjalan di aplikasi. Fitur ini sangat membantu saat mengubah desain atau tampilan UI.
- **Hot Restart (R)** digunakan untuk menjalankan ulang aplikasi dari awal. Semua state akan direset sehingga cocok digunakan ketika ada perubahan pada proses inisialisasi aplikasi.

---

# 1. Aplikasi Profil Mahasiswa (my_first_app)

Pada praktikum ini saya membuat aplikasi Flutter sederhana yang menampilkan profil mahasiswa. Tujuan dari praktikum ini adalah mengenal struktur project Flutter dan penggunaan widget dasar seperti **Scaffold**, **AppBar**, **Center**, **Column**, **Icon**, dan **Text**.

### Mini Assignment

Pada mini assignment, aplikasi dikembangkan dengan menambahkan beberapa informasi identitas.

Fitur yang ditambahkan:

- Menampilkan nama mahasiswa.
- Menampilkan NIM.
- Menampilkan program studi.
- Mengatur tata letak menggunakan widget `Column` dan `SizedBox` agar tampilan lebih rapi.

### Tampilan Aplikasi

![Profil Mahasiswa](screenshots/profile_app.png)

---

# 2. Latihan Dart

Selain membuat aplikasi Flutter, saya juga mengerjakan latihan dasar bahasa Dart.

Materi yang dipelajari antara lain:

- Membuat fungsi `hitungLuasPersegiPanjang()`.
- Membuat class `Profil`.
- Menggunakan constructor.
- Menerapkan konsep **Null Safety** dengan operator `??`.

### Hasil Program

![Output Latihan Dart](screenshots/latihanmandiri.png)

---

# 3. Verifikasi Environment

Untuk memastikan Flutter telah terpasang dengan benar, dilakukan beberapa pengecekan.

- Menjalankan `flutter doctor` untuk memastikan seluruh komponen Flutter telah terinstal dengan baik.
- Menjalankan `flutter devices` untuk memastikan emulator atau perangkat Android berhasil terdeteksi.

### Screenshot

**Flutter Doctor**

![Flutter Doctor](screenshots/flutter_doctor.png)

**Flutter Devices**

![Flutter Devices](screenshots/flutter_devices.png)

---

# 4. Kendala yang Ditemui

Saat proses instalasi, saya mengalami kendala ketika menjalankan perintah:

```bash
flutter doctor --android-licenses
```

Perintah tersebut tidak dapat dijalankan karena versi **Android Command-line Tools** yang terpasang belum sesuai.

### Solusi

Saya membuka **SDK Manager** di Android Studio kemudian menginstal versi **Command-line Tools** yang kompatibel. Setelah itu saya menjalankan kembali pengecekan hingga status **Android Toolchain** berubah menjadi valid.

---

# 5. Refleksi

### 1. Kapan native lebih tepat digunakan dibandingkan cross-platform?

Menurut saya, pengembangan native lebih cocok jika aplikasi membutuhkan performa yang tinggi atau akses langsung ke fitur-fitur perangkat seperti kamera, Bluetooth, sensor, maupun fitur khusus Android atau iOS.

### 2. Bagaimana hubungan state dengan widget tree?

Flutter menggunakan konsep UI deklaratif. Ketika nilai state berubah, Flutter akan melakukan rebuild pada widget yang diperlukan sehingga tampilan aplikasi ikut berubah secara otomatis tanpa harus memperbarui UI secara manual.

### 3. Mengapa commit kecil dengan pesan yang jelas itu penting?

Commit yang kecil dan memiliki pesan yang jelas membuat riwayat perubahan lebih mudah dipahami. Selain memudahkan saat mencari kesalahan (debugging), hal ini juga membantu ketika bekerja dalam tim dan membuat portofolio GitHub terlihat lebih rapi.

---

## Kesimpulan

Melalui praktikum minggu pertama ini saya berhasil:

- Menginstal dan mengonfigurasi Flutter.
- Membuat aplikasi Flutter pertama.
- Mengenal widget dasar Flutter.
- Mempelajari dasar bahasa Dart.
- Menggunakan Git dan GitHub untuk menyimpan project.
- Memahami perbedaan Hot Reload dan Hot Restart.