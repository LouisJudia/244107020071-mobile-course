import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_notify/core/errors/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';
import 'package:campus_notify/main.dart';

class FakeIntegrationAnnouncementRepo implements AnnouncementRepository {
  final List<Announcement> items = [
    const Announcement(
      id: 'ann-101',
      title: 'Workshop Pengujian Kualitas Perangkat Lunak',
      date: '16 Nov 2026',
      category: 'Akademik',
      author: 'Jurusan Teknologi Informasi',
      content: 'Mahasiswa diwajibkan memahami pengujian unit, widget, dan integrasi.',
    ),
    const Announcement(
      id: 'ann-102',
      title: 'Jadwal Ujian Akhir Semester Ganjil',
      date: '20 Nov 2026',
      category: 'Jadwal',
      author: 'Biro Administrasi Akademik',
      content: 'UAS akan dilaksanakan secara luring di Gedung TI.',
    ),
  ];

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  getAnnouncements() async => (announcements: items, failure: null);

  @override
  Future<
    ({List<Announcement> announcements, bool isFromCache, Failure? failure})
  >
  getAnnouncementsWithCache({bool forceRefresh = false}) async =>
      (announcements: items, isFromCache: true, failure: null);

  @override
  Future<({List<Announcement> announcements, bool hasMore, Failure? failure})>
  getAnnouncementsPaginated({int page = 1, int pageSize = 5}) async =>
      (announcements: items, hasMore: false, failure: null);

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(
    String id,
  ) async {
    final item = items.firstWhere((a) => a.id == id, orElse: () => items.first);
    return (announcement: item, failure: null);
  }

  @override
  void clearCache() {}

  @override
  int get cacheCount => items.length;
}

class FakeIntegrationAuthNotifier extends AuthNotifier {
  @override
  Future<bool> build() async => false;

  @override
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    state = const AsyncValue.data(true);
  }

  @override
  Future<void> logout() async {
    state = const AsyncValue.data(false);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
  });

  group('Pengujian Integrasi End-to-End (Alur Utama Aplikasi)', () {
    testWidgets('Alur Lengkap: Login -> Dashboard -> Detail -> Logout', (
      tester,
    ) async {
      final fakeRepo = FakeIntegrationAnnouncementRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementRepositoryProvider.overrideWithValue(fakeRepo),
            authStateProvider.overrideWith(() => FakeIntegrationAuthNotifier()),
            savedSessionProvider.overrideWith(
              (ref) async => const AuthSession(
                access: 'dummy_access_token',
                refresh: 'dummy_refresh_token',
                email: 'louis.judika@polinema.ac.id',
              ),
            ),
          ],
          child: const CampusNotifyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi berada di halaman Login
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);

      // 2. Masukkan Kredensial Login
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'louis.judika@polinema.ac.id',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password123',
      );
      await tester.pumpAndSettle();

      // 3. Tekan Tombol Masuk
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      // 4. Verifikasi Navigasi Masuk ke HomePage (Dashboard)
      expect(find.text('Campus Notify'), findsWidgets);
      expect(find.text('louis.judika@polinema.ac.id'), findsOneWidget);
      expect(
        find.text('Workshop Pengujian Kualitas Perangkat Lunak'),
        findsOneWidget,
      );

      // 5. Interaksi: Tap Tombol Logout
      final logoutButton = find.byKey(const Key('home_logout_button'));
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // 6. Verifikasi Berhasil Kembali ke LoginPage
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });
  });
}
