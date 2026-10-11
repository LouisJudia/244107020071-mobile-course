import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/pages/login_page.dart';
import 'package:campus_notify/pages/home_page.dart';
import 'package:campus_notify/pages/announcement_page.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/providers/auth_provider.dart';

class MockTokenStore extends TokenStore {
  MockTokenStore({this.access, this.refresh});
  String? access;
  String? refresh;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

class ReadyAuthNotifier extends AuthNotifier {
  @override
  Future<bool> build() async => false;
}

Future<void> captureBoundary(
    WidgetTester tester, GlobalKey key, String filename) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary != null) {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        File('../screenshots/$filename').writeAsBytesSync(bytes);
      }
      image.dispose();
    });
  }
}

Future<void> loadRealFonts() async {
  // 1. Regular System Font (Segoe UI)
  final fontFile = File(r'C:\Windows\Fonts\segoeui.ttf');
  if (fontFile.existsSync()) {
    final bytes = fontFile.readAsBytesSync();
    for (final family in ['Roboto', 'sans-serif', '.SF Pro Text']) {
      final fontLoader = FontLoader(family);
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();
    }
  }

  // 2. Bold System Font (Segoe UI Bold)
  final boldFontFile = File(r'C:\Windows\Fonts\segoeuib.ttf');
  if (boldFontFile.existsSync()) {
    final bytes = boldFontFile.readAsBytesSync();
    final fontLoader = FontLoader('Roboto');
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  }

  // 3. Monospace Font (Consolas)
  final monoFile = File(r'C:\Windows\Fonts\consola.ttf');
  if (monoFile.existsSync()) {
    final bytes = monoFile.readAsBytesSync();
    for (final family in ['monospace', 'Courier', 'Courier New']) {
      final fontLoader = FontLoader(family);
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();
    }
  }

  // 4. Material Icons Font
  final iconFile = File(
      r'C:\Users\louis\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf');
  if (iconFile.existsSync()) {
    final iconBytes = iconFile.readAsBytesSync();
    final iconLoader = FontLoader('MaterialIcons');
    iconLoader.addFont(Future.value(ByteData.view(iconBytes.buffer)));
    await iconLoader.load();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRealFonts();
  });

  testWidgets('Capture UI Frames for GIF', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );

    // Frame 1: Login Empty
    final key1 = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key1,
        child: ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => ReadyAuthNotifier()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme,
            home: const LoginPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await captureBoundary(tester, key1, 'frame_login_empty.png');
    await tester.pumpWidget(const SizedBox());

    // Frame 2: Login Filled
    final key2 = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key2,
        child: ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => ReadyAuthNotifier()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme,
            home: const LoginPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(
        find.byType(TextFormField).first, 'mahasiswa@polinema.ac.id');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await captureBoundary(tester, key2, 'frame_login_filled.png');
    await tester.pumpWidget(const SizedBox());

    // Frame 3: Home Initial with Access & Refresh Token
    final key3 = GlobalKey();
    final mockStore = MockTokenStore(
      access: 'mock-access-for-mahasiswa@polinema.ac.id',
      refresh: 'mock-refresh-for-mahasiswa@polinema.ac.id',
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: key3,
        child: ProviderScope(
          overrides: [
            tokenStoreProvider.overrideWithValue(mockStore),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme,
            home: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await captureBoundary(tester, key3, 'frame_home_initial.png');
    await tester.pumpWidget(const SizedBox());

    // Frame 4: Home Token Refreshed via Dio Interceptor
    final key4 = GlobalKey();
    final refreshedStore = MockTokenStore(
      access: 'mock-access-renewed-1729000000000',
      refresh: 'mock-refresh-for-mahasiswa@polinema.ac.id',
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: key4,
        child: ProviderScope(
          overrides: [
            tokenStoreProvider.overrideWithValue(refreshedStore),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme,
            home: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Uji Refresh Token (Dio)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await captureBoundary(tester, key4, 'frame_home_refreshed.png');
    await tester.pumpWidget(const SizedBox());

    // Frame 5: Home with Push Notification Banner
    final key5 = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key5,
        child: ProviderScope(
          overrides: [
            tokenStoreProvider.overrideWithValue(refreshedStore),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme,
            home: Stack(
              children: [
                const HomePage(),
                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.blue.shade400, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              color: Colors.blue,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Jadwal Kuliah Berubah',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Kelas Mobile pindah ke Ruang A2 jam 13.00 WIB (Ketuk untuk detail)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await captureBoundary(tester, key5, 'frame_notification_banner.png');
    await tester.pumpWidget(const SizedBox());

    // Frame 6: Announcement Detail
    final key6 = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key6,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          home: const AnnouncementPage(id: '101'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await captureBoundary(tester, key6, 'frame_announcement_detail.png');
    await tester.pumpWidget(const SizedBox());
  });
}
