import '../../../../core/errors/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_data_source.dart';

/// Implementasi konkrit dari kontrak AnnouncementRepository di Data Layer
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({AnnouncementRemoteDataSource? remoteDataSource})
    : _remoteDataSource =
          remoteDataSource ?? AnnouncementRemoteDataSourceImpl();

  final AnnouncementRemoteDataSource _remoteDataSource;

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements() async {
    try {
      final models = await _remoteDataSource.fetchAnnouncements();
      final entities = models.map((m) => m.toEntity()).toList();
      return (announcements: entities, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: LocalFailure('Gagal memuat daftar pengumuman: $e'),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    try {
      final model = await _remoteDataSource.fetchAnnouncementById(id);
      if (model == null) {
        return (
          announcement: null,
          failure: const LocalFailure('Pengumuman tidak ditemukan.'),
        );
      }
      return (announcement: model.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: LocalFailure('Gagal memuat detail pengumuman: $e'),
      );
    }
  }
}
