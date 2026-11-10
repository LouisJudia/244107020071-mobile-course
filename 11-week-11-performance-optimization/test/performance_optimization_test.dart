import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/network/api_client.dart';
import 'package:campus_notify/features/announcements/data/datasources/announcement_remote_data_source.dart';
import 'package:campus_notify/features/announcements/data/models/announcement_model.dart';
import 'package:campus_notify/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:campus_notify/features/announcements/presentation/widgets/announcement_tile.dart';

class MockRemoteDataSource implements AnnouncementRemoteDataSource {
  int fetchCount = 0;
  bool shouldThrow = false;
  List<AnnouncementModel> mockItems = List.generate(
    10,
    (i) => AnnouncementModel(
      id: 'ann-$i',
      title: 'Judul Pengumuman $i',
      date: '01 Nov 2026',
      category: i.isEven ? 'Akademik' : 'Beasiswa',
      author: 'Biro Akademik',
      content: 'Isi pengumuman lengkap untuk item nomor $i',
      imageUrl: 'https://example.com/image_$i.png',
    ),
  );

  @override
  Future<List<AnnouncementModel>> fetchAnnouncements() async {
    fetchCount++;
    if (shouldThrow) throw Exception('Simulated Network Down');
    return mockItems;
  }

  @override
  Future<AnnouncementModel?> fetchAnnouncementById(String id) async {
    if (shouldThrow) throw Exception('Simulated Network Down');
    final match = mockItems.where((e) => e.id == id).toList();
    return match.isNotEmpty ? match.first : null;
  }

  @override
  Future<List<AnnouncementModel>> fetchAnnouncementsPage(
    int page,
    int pageSize,
  ) async {
    fetchCount++;
    if (shouldThrow) throw Exception('Simulated Network Down');
    final start = (page - 1) * pageSize;
    if (start >= mockItems.length) return [];
    final end = (start + pageSize).clamp(0, mockItems.length);
    return mockItems.sublist(start, end);
  }
}

void main() {
  group('Stale-While-Revalidate Caching Tests (Step 5 Codelab)', () {
    late MockRemoteDataSource mockRemote;
    late AnnouncementRepositoryImpl repository;

    setUp(() {
      mockRemote = MockRemoteDataSource();
      repository = AnnouncementRepositoryImpl(remoteDataSource: mockRemote);
    });

    test('Initial call fetches from remote and caches result', () async {
      final result = await repository.getAnnouncementsWithCache();

      expect(result.failure, isNull);
      expect(result.announcements.length, 10);
      expect(result.isFromCache, isFalse);
      expect(mockRemote.fetchCount, 1);
      expect(repository.cacheCount, 10);
    });

    test('Subsequent calls return from cache instantly without incrementing remote calls', () async {
      await repository.getAnnouncementsWithCache();
      expect(mockRemote.fetchCount, 1);

      // Panggilan kedua harus membaca dari cache (Cache hit)
      final cachedResult = await repository.getAnnouncementsWithCache();

      expect(cachedResult.failure, isNull);
      expect(cachedResult.isFromCache, isTrue);
      expect(cachedResult.announcements.length, 10);
      expect(mockRemote.fetchCount, 1); // Tidak ada panggilan jaringan tambahan
    });

    test('forceRefresh bypasses cache and queries remote source', () async {
      await repository.getAnnouncementsWithCache();
      expect(mockRemote.fetchCount, 1);

      final freshResult = await repository.getAnnouncementsWithCache(
        forceRefresh: true,
      );

      expect(freshResult.isFromCache, isFalse);
      expect(mockRemote.fetchCount, 2);
    });

    test('clearCache empties cache and triggers fresh remote call', () async {
      await repository.getAnnouncementsWithCache();
      expect(repository.cacheCount, 10);

      repository.clearCache();
      expect(repository.cacheCount, 0);

      final result = await repository.getAnnouncementsWithCache();
      expect(result.isFromCache, isFalse);
      expect(mockRemote.fetchCount, 2);
    });

    test('Gracefully returns cached data when network throws an error (Offline Fallback)', () async {
      // 1. Sukses pertama untuk mengisi cache
      await repository.getAnnouncementsWithCache();
      expect(repository.cacheCount, 10);

      // 2. Simulasi jaringan putus
      mockRemote.shouldThrow = true;

      // 3. Request berikutnya harus fallback ke data cache tanpa crash
      final fallbackResult = await repository.getAnnouncementsWithCache();

      expect(fallbackResult.failure, isNull);
      expect(fallbackResult.isFromCache, isTrue);
      expect(fallbackResult.announcements.length, 10);
    });
  });

  group('Pagination & Lazy Loading Tests (Step 4 Codelab)', () {
    late MockRemoteDataSource mockRemote;
    late AnnouncementRepositoryImpl repository;

    setUp(() {
      mockRemote = MockRemoteDataSource();
      repository = AnnouncementRepositoryImpl(remoteDataSource: mockRemote);
    });

    test(
      'getAnnouncementsPaginated returns correct page chunk and hasMore flag',
      () async {
        final page1 = await repository.getAnnouncementsPaginated(
          page: 1,
          pageSize: 4,
        );
        expect(page1.announcements.length, 4);
        expect(page1.hasMore, isTrue);
        expect(page1.announcements.first.id, 'ann-0');

        final page2 = await repository.getAnnouncementsPaginated(
          page: 2,
          pageSize: 4,
        );
        expect(page2.announcements.length, 4);
        expect(page2.hasMore, isTrue);
        expect(page2.announcements.first.id, 'ann-4');

        final page3 = await repository.getAnnouncementsPaginated(
          page: 3,
          pageSize: 4,
        );
        expect(page3.announcements.length, 2); // Hanya tersisa 2 item
        expect(page3.hasMore, isFalse); // Tidak ada halaman lagi
      },
    );
  });

  group('PaginatedAnnouncementsNotifier Unit Tests', () {
    test('loadInitial and loadMore append items properly', () async {
      final mockRemote = MockRemoteDataSource();
      final repository = AnnouncementRepositoryImpl(
        remoteDataSource: mockRemote,
      );

      final container = ProviderContainer(
        overrides: [
          announcementRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(paginatedAnnouncementsProvider.notifier);

      // Panggil loadInitial secara eksplisit
      await notifier.loadInitial();
      var state = container.read(paginatedAnnouncementsProvider);

      expect(state.isLoading, isFalse);
      expect(state.items.length, 4);
      expect(state.page, 1);
      expect(state.hasMore, isTrue);

      // Panggil loadMore untuk halaman kedua
      await notifier.loadMore();
      state = container.read(paginatedAnnouncementsProvider);

      expect(state.isLoadingMore, isFalse);
      expect(state.items.length, 8);
      expect(state.page, 2);
      expect(state.hasMore, isTrue);

      // Refresh mengembalikan ke halaman pertama
      await notifier.refresh();
      state = container.read(paginatedAnnouncementsProvider);

      expect(state.items.length, 4);
      expect(state.page, 1);
    });
  });

  group('Dio Performance Interceptor Tests (Step 5 Codelab)', () {
    test(
      'DioCacheInterceptor caches GET responses and resolves subsequent calls',
      () async {
        final interceptor = DioCacheInterceptor();
        final dio = Dio();
        dio.interceptors.add(interceptor);

        // Simulasikan RequestOptions
        final req1 = RequestOptions(
          path: '/test-endpoint',
          method: 'GET',
          baseUrl: 'https://example.com',
        );
        final res1 = Response(
          requestOptions: req1,
          statusCode: 200,
          data: {'key': 'value123'},
        );

        // Simulasikan onResponse menyimpan cache
        final mockHandler = MockResponseInterceptorHandler();
        interceptor.onResponse(res1, mockHandler);

        expect(interceptor.cachedEntriesCount, 1);

        // Simulasikan onRequest berikutnya mendeteksi cache hit
        var resolvedFromCache = false;
        final reqHandler = MockRequestInterceptorHandler(
          onResolve: (resp) {
            resolvedFromCache = true;
            expect(resp.data, {'key': 'value123'});
            expect(resp.headers.value('x-from-cache'), 'true');
          },
        );

        interceptor.onRequest(req1, reqHandler);
        expect(resolvedFromCache, isTrue);
      },
    );
  });

  group('Optimized Widget & RepaintBoundary Widget Tests', () {
    testWidgets('AnnouncementTile wraps in RepaintBoundary and handles tap', (
      tester,
    ) async {
      const item = Announcement(
        id: 'tile-1',
        title: 'Jadwal Kuliah Semester Baru',
        date: '01 Nov 2026',
        category: 'Akademik',
        content: 'Isi lengkap jadwal kuliah mahasiswa D4 TI',
        author: 'Admin Jurusan TI',
      );

      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementTile(
              item: item,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verifikasi widget dibungkus RepaintBoundary untuk isolasi repaint
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.text('Jadwal Kuliah Semester Baru'), findsOneWidget);
      expect(find.text('Akademik'), findsOneWidget);

      await tester.tap(find.byType(AnnouncementTile));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}

class MockResponseInterceptorHandler extends ResponseInterceptorHandler {
  @override
  void next(Response response) {}
}

class MockRequestInterceptorHandler extends RequestInterceptorHandler {
  final void Function(Response response)? onResolve;
  MockRequestInterceptorHandler({this.onResolve});

  @override
  void resolve(
    Response response, [
    bool callFollowingResponseInterceptor = false,
  ]) {
    onResolve?.call(response);
  }

  @override
  void next(RequestOptions requestOptions) {}
}
