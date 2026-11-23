import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/errors/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcements_usecase.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcement_detail_usecase.dart';

/// Fake repository yang dapat dikendalikan dalam pengujian
/// untuk mensimulasikan kondisi jaringan sukses, error server, dan data kosong.
class MockableAnnouncementRepository implements AnnouncementRepository {
  bool shouldThrowServerException = false;
  bool shouldReturnNetworkFailure = false;
  List<Announcement> announcements = [];
  int delayMilliseconds = 0;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements() async {
    if (delayMilliseconds > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMilliseconds));
    }
    if (shouldThrowServerException) {
      return (
        announcements: <Announcement>[],
        failure: const ServerFailure('500 Internal Server Error'),
      );
    }
    if (shouldReturnNetworkFailure) {
      return (
        announcements: <Announcement>[],
        failure: const NetworkFailure('Koneksi internet terputus'),
      );
    }
    return (announcements: announcements, failure: null);
  }

  @override
  Future<
    ({List<Announcement> announcements, bool isFromCache, Failure? failure})
  >
  getAnnouncementsWithCache({bool forceRefresh = false}) async {
    if (shouldThrowServerException) {
      return (
        announcements: announcements,
        isFromCache: true,
        failure: const ServerFailure(
          'Background fetch failed, returning cache',
        ),
      );
    }
    return (announcements: announcements, isFromCache: true, failure: null);
  }

  @override
  Future<({List<Announcement> announcements, bool hasMore, Failure? failure})>
  getAnnouncementsPaginated({int page = 1, int pageSize = 5}) async {
    if (shouldThrowServerException) {
      return (
        announcements: <Announcement>[],
        hasMore: false,
        failure: const ServerFailure('Gagal memuat paginasi'),
      );
    }
    final start = (page - 1) * pageSize;
    if (start >= announcements.length) {
      return (announcements: <Announcement>[], hasMore: false, failure: null);
    }
    final end = (start + pageSize).clamp(0, announcements.length);
    final slice = announcements.sublist(start, end);
    return (
      announcements: slice,
      hasMore: end < announcements.length,
      failure: null,
    );
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    if (id.trim().isEmpty) {
      return (
        announcement: null,
        failure: const ValidationFailure('ID pengumuman tidak boleh kosong'),
      );
    }
    try {
      final found = announcements.firstWhere((a) => a.id == id);
      return (announcement: found, failure: null);
    } catch (_) {
      return (
        announcement: null,
        failure: const ServerFailure('Pengumuman tidak ditemukan'),
      );
    }
  }

  @override
  void clearCache() {
    announcements.clear();
  }

  @override
  int get cacheCount => announcements.length;
}

void main() {
  group('Fake Repository & Dependency Isolation Tests', () {
    late MockableAnnouncementRepository fakeRepository;
    late GetAnnouncementsUseCase getAnnouncementsUseCase;
    late GetAnnouncementDetailUseCase getAnnouncementDetailUseCase;

    setUp(() {
      fakeRepository = MockableAnnouncementRepository();
      getAnnouncementsUseCase = GetAnnouncementsUseCase(fakeRepository);
      getAnnouncementDetailUseCase = GetAnnouncementDetailUseCase(
        fakeRepository,
      );

      fakeRepository.announcements = [
        const Announcement(
          id: 'ann-1',
          title: 'Jadwal Kuliah Semester Baru',
          date: '2026-11-16',
          category: 'Akademik',
          author: 'Biro Akademik',
          content: 'Perkuliahan semester ganjil dimulai pekan depan.',
        ),
        const Announcement(
          id: 'ann-2',
          title: 'Sosialisasi Beasiswa Djarum',
          date: '2026-11-17',
          category: 'Beasiswa',
          author: 'Bagian Kemahasiswaan',
          content: 'Pendaftaran dibuka untuk mahasiswa semester 5.',
        ),
      ];
    });

    test(
      'Arrange-Act-Assert: Berhasil mengambil data tanpa API sungguhan',
      () async {
        // Arrange (data telah disiapkan di setUp)

        // Act
        final result = await getAnnouncementsUseCase();

        // Assert
        expect(result.failure, isNull);
        expect(result.announcements.length, equals(2));
        expect(result.announcements.first.id, equals('ann-1'));
      },
    );

    test('Kasus Kegagalan: Server mengembalikan error 500 ditangani dengan ServerFailure', () async {
      // Arrange
      fakeRepository.shouldThrowServerException = true;

      // Act
      final result = await getAnnouncementsUseCase();

      // Assert
      expect(result.failure, isA<ServerFailure>());
      expect(result.announcements, isEmpty);
      expect(result.failure?.message, contains('500'));
    });

    test('Kasus Kegagalan: Jaringan terputus menghasilkan NetworkFailure tanpa crash', () async {
      // Arrange
      fakeRepository.shouldReturnNetworkFailure = true;

      // Act
      final result = await getAnnouncementsUseCase();

      // Assert
      expect(result.failure, isA<NetworkFailure>());
      expect(result.failure?.message, contains('internet terputus'));
    });

    test(
      'Kasus Tepi: Dataset kosong mengembalikan list kosong dengan sukses',
      () async {
        // Arrange
        fakeRepository.clearCache();

        // Act
        final result = await getAnnouncementsUseCase();

        // Assert
        expect(result.failure, isNull);
        expect(result.announcements, isEmpty);
      },
    );

    test('Kasus Tepi: Mencari ID kosong melempar ValidationFailure', () async {
      // Arrange & Act
      final result = await getAnnouncementDetailUseCase('   ');

      // Assert
      expect(result.failure, isA<ValidationFailure>());
      expect(result.announcement, isNull);
    });

    test(
      'Kasus Tepi: Mencari ID yang tidak ada melempar ServerFailure',
      () async {
        // Arrange & Act
        final result = await getAnnouncementDetailUseCase('non-existent-id');

        // Assert
        expect(result.failure, isA<ServerFailure>());
        expect(result.announcement, isNull);
      },
    );

    test(
      'Asinkron & Cache: SWR mengembalikan data lokal saat remote server gagal',
      () async {
        // Arrange
        fakeRepository.shouldThrowServerException = true;

        // Act
        final result = await fakeRepository.getAnnouncementsWithCache();

        // Assert
        expect(result.isFromCache, isTrue);
        expect(result.announcements.length, equals(2));
        expect(result.failure, isNotNull);
      },
    );
  });
}
