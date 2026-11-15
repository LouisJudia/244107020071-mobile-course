import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcement_detail_usecase.dart';
import '../../domain/usecases/get_announcements_usecase.dart';

// --- DATA LAYER WIRING (Dependency Injection) ---
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl();
});

// --- DOMAIN LAYER WIRING (Use Cases) ---
final getAnnouncementsUseCaseProvider = Provider<GetAnnouncementsUseCase>((
  ref,
) {
  final repository = ref.watch(announcementRepositoryProvider);
  return GetAnnouncementsUseCase(repository);
});

final getAnnouncementDetailUseCaseProvider =
    Provider<GetAnnouncementDetailUseCase>((ref) {
      final repository = ref.watch(announcementRepositoryProvider);
      return GetAnnouncementDetailUseCase(repository);
    });

// --- PRESENTATION LAYER STATE (UI Providers) ---
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final useCase = ref.watch(getAnnouncementsUseCaseProvider);
  final result = await useCase();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.announcements;
});

final announcementDetailProvider = FutureProvider.family<Announcement?, String>(
  (ref, id) async {
    final useCase = ref.watch(getAnnouncementDetailUseCaseProvider);
    final result = await useCase(id);
    if (result.failure != null) {
      throw Exception(result.failure!.message);
    }
    return result.announcement;
  },
);

/// State untuk Infinite Scroll Pagination & Lazy Loading (Step 4 Codelab)
class PaginatedAnnouncementsState {
  final List<Announcement> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;
  final bool isFromCache;

  const PaginatedAnnouncementsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.isFromCache = false,
  });

  PaginatedAnnouncementsState copyWith({
    List<Announcement>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    bool? isFromCache,
  }) {
    return PaginatedAnnouncementsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

/// Notifier untuk Pagination (Infinite Scroll) & Memory Sizing
class PaginatedAnnouncementsNotifier
    extends Notifier<PaginatedAnnouncementsState> {
  static const int pageSize = 4;

  @override
  PaginatedAnnouncementsState build() {
    Future.microtask(() => loadInitial());
    return const PaginatedAnnouncementsState(isLoading: true);
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    final repo = ref.read(announcementRepositoryProvider);
    state = state.copyWith(isLoading: true, error: null);

    final result = await repo.getAnnouncementsPaginated(
      page: 1,
      pageSize: pageSize,
    );
    if (result.failure != null && state.items.isEmpty) {
      state = state.copyWith(isLoading: false, error: result.failure!.message);
    } else {
      state = state.copyWith(
        items: result.announcements,
        isLoading: false,
        hasMore: result.hasMore,
        page: 1,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    final nextPage = state.page + 1;
    final repo = ref.read(announcementRepositoryProvider);
    final result = await repo.getAnnouncementsPaginated(
      page: nextPage,
      pageSize: pageSize,
    );

    if (result.failure == null) {
      state = state.copyWith(
        items: [...state.items, ...result.announcements],
        page: nextPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } else {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    final repo = ref.read(announcementRepositoryProvider);
    repo.clearCache();
    await loadInitial(forceRefresh: true);
  }
}

final paginatedAnnouncementsProvider =
    NotifierProvider<
      PaginatedAnnouncementsNotifier,
      PaginatedAnnouncementsState
    >(PaginatedAnnouncementsNotifier.new);
