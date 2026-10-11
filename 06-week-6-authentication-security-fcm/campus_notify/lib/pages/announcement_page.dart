import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    // Data pengumuman mock berdasarkan ID
    final announcementsData = {
      '101': {
        'title': 'Jadwal UTS Semester Ganjil 2024/2025',
        'date': '07 Oktober 2024',
        'author': 'Biro Akademik',
        'category': 'Akademik',
        'content':
            'Diumumkan kepada seluruh mahasiswa aktif bahwa Ujian Tengah Semester (UTS) Ganjil T.A. 2024/2025 akan diselenggarakan pada tanggal 14 - 25 Oktober 2024.\n\nKetentuan Pelaksanaan:\n1. Mahasiswa wajib membawa Kartu Tanda Mahasiswa (KTM) atau Kartu Ujian.\n2. Berpakaian rapi dan sopan (Kemeja putih & celana/rok gelap).\n3. Keterlambatan toleransi maksimal 15 menit dari jadwal dimulainya ujian.\n\nJadwal detail per mata kuliah dapat diunduh pada SIADIN masing-masing program studi.'
      },
      '102': {
        'title': 'Pendaftaran Beasiswa Prestasi Mahasiswa',
        'date': '05 Oktober 2024',
        'author': 'Kemahasiswaan',
        'category': 'Beasiswa',
        'content':
            'Program Beasiswa Prestasi periode semester Ganjil 2024 resmi dibuka bagi mahasiswa berprestasi akademik maupun non-akademik.\n\nPersyaratan:\n1. IPK minimal 3.50 (lampirkan transkrip nilai terlegalisir).\n2. Sertifikat perlombaan/kompetisi minimal tingkat provinsi.\n3. Surat rekomendasi dari Ketua Program Studi.\n\nBatas akhir pengumpulan berkas adalah tanggal 20 Oktober 2024 pukul 16:00 WIB.'
      },
      '103': {
        'title': 'Pemeliharaan Server Portal Akademik',
        'date': '01 Oktober 2024',
        'author': 'Tim UPT IT',
        'category': 'Sistem',
        'content': 'Disampaikan kepada seluruh pengembang dan pengguna portal kampus bahwa akan dilakukan pemeliharaan rutinitas server database pada:\n\nHari/Tanggal: Sabtu, 12 Oktober 2024\nWaktu: 23:00 - 03:00 WIB\n\nSelama proses pemeliharaan, layanan SIAKAD, E-learning, dan Portal Akademik tidak dapat diakses sementara. Mohon maaf atas ketidaknyamanannya.'
      }
    };

    final item = announcementsData[id] ?? {
      'title': 'Pengumuman #$id',
      'date': 'Hari ini',
      'author': 'Admin Kampus',
      'category': 'Umum',
      'content': 'Detail informasi untuk pengumuman dengan ID $id tidak ditemukan atau telah diarsip.'
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(
                item['category']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              item['title']!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item['author']!,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item['date']!,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              item['content']!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
