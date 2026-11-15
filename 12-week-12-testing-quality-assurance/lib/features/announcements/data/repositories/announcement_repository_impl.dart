import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../datasources/announcement_remote_data_source.dart';

/// Implementasi AnnouncementRepository dengan strategi caching Stale-While-Revalidate & Pagination
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({AnnouncementRemoteDataSource? remoteDataSource})
    : _remoteDataSource =
          remoteDataSource ?? AnnouncementRemoteDataSourceImpl();

  final AnnouncementRemoteDataSource _remoteDataSource;

  // In-Memory Cache Store untuk optimasi performa Stale-While-Revalidate
  final List<Announcement> _cache = [];
  DateTime? _lastCacheTime;
  static const Duration _cacheTtl = Duration(minutes: 5);

  @override
  int get cacheCount => _cache.length;

  @override
  void clearCache() {
    _cache.clear();
    _lastCacheTime = null;
  }

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements() async {
    final result = await getAnnouncementsWithCache();
    return (announcements: result.announcements, failure: result.failure);
  }

  @override
  Future<
    ({List<Announcement> announcements, bool isFromCache, Failure? failure})
  >
  getAnnouncementsWithCache({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final hasFreshCache =
        _cache.isNotEmpty &&
        _lastCacheTime != null &&
        now.difference(_lastCacheTime!) < _cacheTtl;

    // 1. Skenario Cache-First: Kembalikan cache segera jika tersedia dan tidak forceRefresh (<1ms)
    if (_cache.isNotEmpty && !forceRefresh) {
      if (!hasFreshCache) {
        unawaited(_revalidateCacheInBackground());
      }
      return (
        announcements: List<Announcement>.unmodifiable(_cache),
        isFromCache: true,
        failure: null,
      );
    }

    // 2. Fetch fresh data dari remote data source
    try {
      final models = await _remoteDataSource.fetchAnnouncements();
      final entities = models.map((m) => m.toEntity()).toList();

      _cache.clear();
      _cache.addAll(entities);
      _lastCacheTime = DateTime.now();

      return (
        announcements: List<Announcement>.unmodifiable(_cache),
        isFromCache: false,
        failure: null,
      );
    } catch (e) {
      // 3. Fallback Offline: Jika remote gagal tapi cache lokal ada, kembalikan cache
      if (_cache.isNotEmpty) {
        return (
          announcements: List<Announcement>.unmodifiable(_cache),
          isFromCache: true,
          failure: null,
        );
      }
      return (
        announcements: const <Announcement>[],
        isFromCache: false,
        failure: LocalFailure('Gagal memuat daftar pengumuman: $e'),
      );
    }
  }

  Future<void> _revalidateCacheInBackground() async {
    try {
      final models = await _remoteDataSource.fetchAnnouncements();
      final entities = models.map((m) => m.toEntity()).toList();
      _cache.clear();
      _cache.addAll(entities);
      _lastCacheTime = DateTime.now();
    } catch (_) {
      // Abaikan error di background revalidation agar tidak memblokir aplikasi
    }
  }

  @override
  Future<({List<Announcement> announcements, bool hasMore, Failure? failure})>
  getAnnouncementsPaginated({int page = 1, int pageSize = 5}) async {
    try {
      final models = await _remoteDataSource.fetchAnnouncementsPage(
        page,
        pageSize,
      );
      final entities = models.map((m) => m.toEntity()).toList();
      final hasMore = entities.length == pageSize;

      // Update local cache dengan data halaman terbaru
      for (final entity in entities) {
        if (!_cache.any((item) => item.id == entity.id)) {
          _cache.add(entity);
        }
      }
      _lastCacheTime = DateTime.now();

      return (announcements: entities, hasMore: hasMore, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        hasMore: false,
        failure: LocalFailure('Gagal memuat halaman $page: $e'),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    // 1. Cek di cache memori terlebih dahulu (<1ms)
    final cachedMatch = _cache.where((a) => a.id == id).toList();
    if (cachedMatch.isNotEmpty) {
      return (announcement: cachedMatch.first, failure: null);
    }

    // 2. Cari di remote data source jika tidak ada di cache
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
