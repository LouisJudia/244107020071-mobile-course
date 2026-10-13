import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/errors/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcement_detail_usecase.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcements_usecase.dart';

/// Fake repository pengumuman murni tanpa koneksi internet atau SQLite sungguhan
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({
    this.items = const [],
    this.fail = false,
  });

  final List<Announcement> items;
  final bool fail;

  @override
  Future<({List<Announcement> announcements, Failure? failure})> getAnnouncements() async {
    if (fail) {
      return (
        announcements: const <Announcement>[],
        failure: const NetworkFailure('Koneksi timeout (simulasi)'),
      );
    }
    return (announcements: items, failure: null);
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    if (fail) {
      return (
        announcement: null,
        failure: const LocalFailure('Database terkunci (simulasi)'),
      );
    }
    final match = items.where((e) => e.id == id).toList();
    if (match.isEmpty) {
      return (
        announcement: null,
        failure: const LocalFailure('Pengumuman tidak ditemukan'),
      );
    }
    return (announcement: match.first, failure: null);
  }
}

void main() {
  group('GetAnnouncementsUseCase Unit Tests', () {
    test('GetAnnouncements meneruskan daftar pengumuman dari repository', () async {
      final repo = FakeAnnouncementRepository(
        items: [
          const Announcement(
            id: '101',
            title: 'Jadwal UTS',
            date: '07 Okt 2024',
            category: 'Akademik',
            content: 'Ujian Tengah Semester',
            author: 'Biro Akademik',
          ),
          const Announcement(
            id: '102',
            title: 'Beasiswa Prestasi',
            date: '05 Okt 2024',
            category: 'Beasiswa',
            content: 'Pendaftaran beasiswa',
            author: 'Kemahasiswaan',
          ),
        ],
      );

      final useCase = GetAnnouncementsUseCase(repo);
      final result = await useCase();

      expect(result.failure, isNull);
      expect(result.announcements.length, 2);
      expect(result.announcements.first.title, 'Jadwal UTS');
      expect(result.announcements.last.category, 'Beasiswa');
    });

    test('GetAnnouncements meneruskan failure tanpa melempar exception crash', () async {
      final repo = FakeAnnouncementRepository(fail: true);
      final useCase = GetAnnouncementsUseCase(repo);

      final result = await useCase();

      expect(result.failure, isA<NetworkFailure>());
      expect(result.failure?.message, contains('Koneksi timeout'));
      expect(result.announcements, isEmpty);
    });
  });

  group('GetAnnouncementDetailUseCase Unit Tests', () {
    test('GetAnnouncementDetail menemukan item dengan ID yang tepat', () async {
      final repo = FakeAnnouncementRepository(
        items: [
          const Announcement(
            id: '101',
            title: 'Jadwal UTS',
            date: '07 Okt 2024',
            category: 'Akademik',
            content: 'Detail lengkap ujian',
            author: 'Biro Akademik',
          ),
        ],
      );

      final useCase = GetAnnouncementDetailUseCase(repo);
      final result = await useCase('101');

      expect(result.failure, isNull);
      expect(result.announcement, isNotNull);
      expect(result.announcement?.id, '101');
      expect(result.announcement?.title, 'Jadwal UTS');
    });

    test('GetAnnouncementDetail mengembalikan failure saat ID kosong', () async {
      final repo = FakeAnnouncementRepository();
      final useCase = GetAnnouncementDetailUseCase(repo);

      final result = await useCase('');

      expect(result.announcement, isNull);
      expect(result.failure, isA<ValidationFailure>());
    });

    test('GetAnnouncementDetail mengembalikan failure saat ID tidak ada', () async {
      final repo = FakeAnnouncementRepository(items: []);
      final useCase = GetAnnouncementDetailUseCase(repo);

      final result = await useCase('999');

      expect(result.announcement, isNull);
      expect(result.failure, isA<LocalFailure>());
      expect(result.failure?.message, contains('tidak ditemukan'));
    });
  });
}
