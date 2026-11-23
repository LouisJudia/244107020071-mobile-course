import '../../../../core/errors/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Use case untuk mengambil detail satu pengumuman berdasarkan ID
class GetAnnouncementDetailUseCase {
  const GetAnnouncementDetailUseCase(this._repository);
  final AnnouncementRepository _repository;

  Future<({Announcement? announcement, Failure? failure})> call(String id) {
    if (id.trim().isEmpty) {
      return Future.value((
        announcement: null,
        failure: const ValidationFailure(
          'ID pengumuman tidak valid atau kosong',
        ),
      ));
    }
    return _repository.getAnnouncementById(id.trim());
  }
}
