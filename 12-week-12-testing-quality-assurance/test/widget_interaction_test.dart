import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/presentation/widgets/announcement_tile.dart';
import 'package:campus_notify/features/auth/presentation/pages/login_page.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';

class ReadyAuthNotifier extends AuthNotifier {
  @override
  Future<bool> build() async => false;

  @override
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    state = const AsyncValue.data(true);
  }
}

class FakeErrorAuthNotifier extends AuthNotifier {
  @override
  Future<bool> build() async {
    throw Exception('Email atau password salah');
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
  });

  group('Widget Tests: Tampilan & Interaksi UI (Widget Testing)', () {
    testWidgets('1. Tampilan Awal LoginPage merender seluruh kontrol penting', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => ReadyAuthNotifier()),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Periksa Header & Label
      expect(find.text('Campus Notify'), findsOneWidget);
      expect(find.text('Sistem Informasi & Pengumuman Kampus'), findsOneWidget);

      // Periksa Form Fields & Button via Key
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets(
      '2. Kasus Tepi: Menampilkan pesan validasi saat form disubmit kosong',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(() => ReadyAuthNotifier()),
            ],
            child: const MaterialApp(home: LoginPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap tombol Masuk tanpa mengisi form
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();

        // Verifikasi pesan validasi muncul
        expect(find.text('Email tidak boleh kosong'), findsOneWidget);
        expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Kasus Tepi: Validasi format email tidak valid dan kata sandi < 6 karakter',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(() => ReadyAuthNotifier()),
            ],
            child: const MaterialApp(home: LoginPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Masukkan email tanpa '@' dan password pendek
        await tester.enterText(
          find.byKey(const Key('login_email_field')),
          'bukan-email',
        );
        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          '123',
        );

        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('Format email tidak valid'), findsOneWidget);
        expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Interaksi: Toggle visibility password mengubah status obscureText',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(() => ReadyAuthNotifier()),
            ],
            child: const MaterialApp(home: LoginPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Cari ikon visibility
        final toggleButton = find.byIcon(Icons.visibility_outlined);
        expect(toggleButton, findsOneWidget);

        // Tap toggle button
        await tester.tap(toggleButton);
        await tester.pumpAndSettle();

        // Sekarang ikon harus berubah menjadi visibility_off
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      },
    );

    testWidgets(
      '5. Kasus Kegagalan: Menampilkan pesan error banner saat login gagal',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(() => FakeErrorAuthNotifier()),
            ],
            child: const MaterialApp(home: LoginPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi pesan error muncul di banner
        expect(find.text('Email atau password salah'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
    );

    testWidgets(
      '6. AnnouncementTile merender detail, tag kategori, dan terbungkus RepaintBoundary',
      (tester) async {
        const mockAnnouncement = Announcement(
          id: 'ann-101',
          title: 'Pengumuman Beasiswa Unggulan',
          date: '16 Nov 2026',
          category: 'Beasiswa',
          author: 'Kemahasiswaan Polinema',
          content: 'Pendaftaran beasiswa dibuka sampai akhir bulan.',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnnouncementTile(item: mockAnnouncement, onTap: () {}),
            ),
          ),
        );
        await tester.pump();

        // Verifikasi komponen teks
        expect(find.text('Pengumuman Beasiswa Unggulan'), findsOneWidget);
        expect(find.text('16 Nov 2026'), findsOneWidget);
        expect(find.text('Beasiswa'), findsOneWidget);
        expect(find.text('Baca selengkapnya'), findsOneWidget);

        // Verifikasi RepaintBoundary membungkus tile
        final boundaryFinder = find.byType(RepaintBoundary);
        expect(boundaryFinder, findsWidgets);
      },
    );
  });
}
