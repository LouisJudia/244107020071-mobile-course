import '../../../../core/errors/failures.dart';
import '../entities/announcement.dart';

/// Kontrak abstraksi repository pengumuman dengan dukungan Stale-While-Revalidate Caching & Pagination
/// (Domain layer - Pure Dart)
abstract class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements();

  Future<
    ({List<Announcement> announcements, bool isFromCache, Failure? failure})
  >
  getAnnouncementsWithCache({bool forceRefresh = false}) async {
    final res = await getAnnouncements();
    return (
      announcements: res.announcements,
      isFromCache: false,
      failure: res.failure,
    );
  }

  Future<({List<Announcement> announcements, bool hasMore, Failure? failure})>
  getAnnouncementsPaginated({int page = 1, int pageSize = 5}) async {
    final res = await getAnnouncements();
    return (
      announcements: res.announcements,
      hasMore: false,
      failure: res.failure,
    );
  }

  void clearCache() {}
  int get cacheCount => 0;

  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  );
}
