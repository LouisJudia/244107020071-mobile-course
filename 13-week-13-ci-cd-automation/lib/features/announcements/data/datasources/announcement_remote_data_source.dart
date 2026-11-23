import '../models/announcement_model.dart';

abstract class AnnouncementRemoteDataSource {
  Future<List<AnnouncementModel>> fetchAnnouncements();
  Future<AnnouncementModel?> fetchAnnouncementById(String id);
  Future<List<AnnouncementModel>> fetchAnnouncementsPage(
    int page,
    int pageSize,
  );
}

class AnnouncementRemoteDataSourceImpl implements AnnouncementRemoteDataSource {
  static final List<Map<String, dynamic>> _mockData = [
    {
      'id': '101',
      'title': 'Jadwal UTS Semester Ganjil 2024/2025',
      'date': '07 Okt 2024',
      'category': 'Akademik',
      'author': 'Biro Akademik',
      'content': 'Ujian Tengah Semester (UTS) akan dilaksanakan secara luring mulai tanggal 14 Oktober 2024. Harap persiapkan kartu ujian dan hadir tepat waktu.',
      'imageUrl': 'https://picsum.photos/seed/announcement101/600/400',
    },
    {
      'id': '102',
      'title': 'Pendaftaran Beasiswa Prestasi Mahasiswa',
      'date': '05 Okt 2024',
      'category': 'Beasiswa',
      'author': 'Kemahasiswaan',
      'content': 'Pendaftaran Beasiswa Prestasi periode Ganjil telah dibuka sampai 20 Oktober 2024. Lengkapi berkas persyaratannya melalui portal akademik.',
      'imageUrl': 'https://picsum.photos/seed/announcement102/600/400',
    },
    {
      'id': '103',
      'title': 'Pemeliharaan Server Portal Akademik',
      'date': '01 Okt 2024',
      'category': 'Sistem',
      'author': 'Tim UPT IT',
      'content': 'Server portal akademik akan mengalami downtime sementara pada Sabtu malam jam 23:00 - 03:00 WIB untuk peningkatan performa.',
      'imageUrl': 'https://picsum.photos/seed/announcement103/600/400',
    },
    {
      'id': '104',
      'title': 'Workshop Flutter & AI Integration di Graha Polinema',
      'date': '28 Sep 2024',
      'category': 'Akademik',
      'author': 'Jurusan TI Polinema',
      'content': 'Hadiri workshop praktis integrasi fitur AI LLM dan teknik profiling DevTools bersama praktisi industri. Gratis untuk mahasiswa tingkat akhir.',
      'imageUrl': 'https://picsum.photos/seed/announcement104/600/400',
    },
    {
      'id': '105',
      'title': 'Pengumuman Penerima Bantuan UKT Semester Ganjil',
      'date': '25 Sep 2024',
      'category': 'Beasiswa',
      'author': 'Bagian Keuangan',
      'content': 'Daftar mahasiswa penerima subsidi UKT telah dipublikasikan. Silakan cek status di menu keuangan portal SIAKAD masing-masing.',
      'imageUrl': 'https://picsum.photos/seed/announcement105/600/400',
    },
    {
      'id': '106',
      'title': 'Update Layanan Wi-Fi Eduroam Kampus Utama',
      'date': '20 Sep 2024',
      'category': 'Sistem',
      'author': 'UPT Komputer',
      'content': 'Peningkatan kecepatan bandwidth Eduroam telah selesai di seluruh gedung perkuliahan dan laboratorium komputer lantai 6 dan 7.',
      'imageUrl': 'https://picsum.photos/seed/announcement106/600/400',
    },
    {
      'id': '107',
      'title': 'Jadwal Konsultasi DPA dan Revisi KRS Online',
      'date': '18 Sep 2024',
      'category': 'Akademik',
      'author': 'KPS D4 TI',
      'content': 'Batas akhir revisi KRS dan konsultasi lembar studi bersama Dosen Penasihat Akademik (DPA) diperpanjang hingga hari Jumat pukul 16.00 WIB.',
      'imageUrl': 'https://picsum.photos/seed/announcement107/600/400',
    },
    {
      'id': '108',
      'title': 'Kompetisi Nasional Inovasi Vokasi (KMHE & Gemastik)',
      'date': '15 Sep 2024',
      'category': 'Prestasi',
      'author': 'Pusat Karir & Prestasi',
      'content': 'Pendaftaran kontingen Polinema untuk cabang Pengembangan Perangkat Lunak dan Desain UX telah dibuka. Segera bentuk tim Anda.',
      'imageUrl': 'https://picsum.photos/seed/announcement108/600/400',
    },
    {
      'id': '109',
      'title': 'Jam Layanan Perpustakaan Pusat Selama Periode Ujian',
      'date': '12 Sep 2024',
      'category': 'Umum',
      'author': 'UPT Perpustakaan',
      'content': 'Perpustakaan pusat buka lebih lama selama periode UTS hingga pukul 20.00 WIB. Ruang baca bersama dan akses e-journal dibuka penuh.',
      'imageUrl': 'https://picsum.photos/seed/announcement109/600/400',
    },
    {
      'id': '110',
      'title': 'Sosialisasi Program Magang MBKM Bersertifikat Batch 7',
      'date': '10 Sep 2024',
      'category': 'Akademik',
      'author': 'Koordinator MBKM',
      'content': 'Pelajari prosedur konversi 20 SKS untuk magang industri mitra BUMN dan tech unicorns di webinar persiapan MBKM semester depan.',
      'imageUrl': 'https://picsum.photos/seed/announcement110/600/400',
    },
  ];

  @override
  Future<List<AnnouncementModel>> fetchAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockData.map((e) => AnnouncementModel.fromMap(e)).toList();
  }

  @override
  Future<AnnouncementModel?> fetchAnnouncementById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final match = _mockData.where((e) => e['id'] == id).toList();
    if (match.isEmpty) return null;
    return AnnouncementModel.fromMap(match.first);
  }

  @override
  Future<List<AnnouncementModel>> fetchAnnouncementsPage(
    int page,
    int pageSize,
  ) async {
    await Future.delayed(const Duration(milliseconds: 180));
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= _mockData.length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, _mockData.length);
    return _mockData
        .sublist(startIndex, endIndex)
        .map((e) => AnnouncementModel.fromMap(e))
        .toList();
  }
}
