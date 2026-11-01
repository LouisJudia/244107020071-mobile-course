import '../../../../core/errors/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case untuk mengambil seluruh daftar pengumuman kampus
class GetAnnouncementsUseCase {
  const GetAnnouncementsUseCase(this._repository);
  final AnnouncementRepository _repository;

  Future<({List<Announcement> announcements, Failure? failure})> call() {
    return _repository.getAnnouncements();
  }
}
