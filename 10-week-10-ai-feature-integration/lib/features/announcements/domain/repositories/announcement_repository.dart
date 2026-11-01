import '../../../../core/errors/failures.dart';
import '../entities/announcement.dart';

/// Kontrak abstraksi repository pengumuman
/// (Domain layer - Pure Dart)
abstract class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements();

  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  );
}
