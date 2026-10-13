import '../models/announcement_model.dart';

abstract class AnnouncementRemoteDataSource {
  Future<List<AnnouncementModel>> fetchAnnouncements();
  Future<AnnouncementModel?> fetchAnnouncementById(String id);
}

class AnnouncementRemoteDataSourceImpl implements AnnouncementRemoteDataSource {
  static final List<Map<String, dynamic>> _mockData = [
    {
      'id': '101',
      'title': 'Jadwal UTS Semester Ganjil 2024/2025',
      'date': '07 Okt 2024',
      'category': 'Akademik',
      'author': 'Biro Akademik',
      'content':
          'Ujian Tengah Semester (UTS) akan dilaksanakan secara luring mulai tanggal 14 Oktober 2024. Harap persiapkan kartu ujian dan hadir tepat waktu.',
    },
    {
      'id': '102',
      'title': 'Pendaftaran Beasiswa Prestasi Mahasiswa',
      'date': '05 Okt 2024',
      'category': 'Beasiswa',
      'author': 'Kemahasiswaan',
      'content':
          'Pendaftaran Beasiswa Prestasi periode Ganjil telah dibuka sampai 20 Oktober 2024. Lengkapi berkas persyaratannya melalui portal akademik.',
    },
    {
      'id': '103',
      'title': 'Pemeliharaan Server Portal Akademik',
      'date': '01 Okt 2024',
      'category': 'Sistem',
      'author': 'Tim UPT IT',
      'content':
          'Server portal akademik akan mengalami downtime sementara pada Sabtu malam jam 23:00 - 03:00 WIB untuk peningkatan performa.',
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
}
