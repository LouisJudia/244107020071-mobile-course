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
final getAnnouncementsUseCaseProvider = Provider<GetAnnouncementsUseCase>((ref) {
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

final announcementDetailProvider =
    FutureProvider.family<Announcement?, String>((ref, id) async {
  final useCase = ref.watch(getAnnouncementDetailUseCaseProvider);
  final result = await useCase(id);
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.announcement;
});
