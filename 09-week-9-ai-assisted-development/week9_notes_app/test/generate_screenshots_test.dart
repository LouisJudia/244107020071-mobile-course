import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/sync.dart';
import 'package:week5_offline_notes/main.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class ScreenshotNoteRepository extends NoteRepository {
  ScreenshotNoteRepository({required this.notes})
    : super(openDb: () => throw UnimplementedError());

  final List<Note> notes;

  @override
  Future<List<Note>> fetchNotes() async => notes;

  @override
  Future<Note?> getNoteById(int id) async {
    return notes.firstWhere((n) => n.id == id, orElse: () => notes.first);
  }

  @override
  Future<int> countDirty() async {
    return notes.where((n) => n.dirty).length;
  }
}

class ScreenshotSyncService extends SyncService {
  ScreenshotSyncService({required this.posts})
    : super(openDb: () => throw UnimplementedError());

  final List<Post> posts;

  @override
  Future<List<Post>> loadPostsCacheFirst({bool forceOffline = false}) async {
    return posts;
  }

  @override
  Future<List<Post>> readCachedPosts() async => posts;

  @override
  Future<int> syncNotes(NoteRepository repo) async => 0;
}

Future<void> saveScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary != null) {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final path = '../screenshots/$filename';
        File(path).writeAsBytesSync(bytes);
      }
      image.dispose();
    });
  }
}

Future<void> loadRealFonts() async {
  final fontFile = File(r'C:\Windows\Fonts\segoeui.ttf');
  if (fontFile.existsSync()) {
    final bytes = fontFile.readAsBytesSync();
    for (final family in ['Roboto', 'sans-serif', '.SF Pro Text']) {
      final fontLoader = FontLoader(family);
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();
    }
  }

  final boldFontFile = File(r'C:\Windows\Fonts\segoeuib.ttf');
  if (boldFontFile.existsSync()) {
    final bytes = boldFontFile.readAsBytesSync();
    final fontLoader = FontLoader('Roboto');
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  }

  final monoFile = File(r'C:\Windows\Fonts\consola.ttf');
  if (monoFile.existsSync()) {
    final bytes = monoFile.readAsBytesSync();
    for (final family in ['monospace', 'Courier', 'Courier New']) {
      final fontLoader = FontLoader(family);
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();
    }
  }

  final iconFile = File(
    r'C:\Users\louis\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
  );
  if (iconFile.existsSync()) {
    final iconBytes = iconFile.readAsBytesSync();
    final iconLoader = FontLoader('MaterialIcons');
    iconLoader.addFont(Future.value(ByteData.view(iconBytes.buffer)));
    await iconLoader.load();
  }
}

final sampleNotes = [
  Note(
    id: 1,
    title: 'Catatan Belanja Mingguan',
    body: '1. Telur 1kg\n2. Susu oat\n3. Sayur bayam & brokoli',
    updatedAt: DateTime(2026, 10, 26, 10, 15),
    dirty: false,
  ),
  Note(
    id: 2,
    title: 'Daftar Belanja Kebutuhan Kos',
    body: 'Deterjen, sabun mandi, pasta gigi, tisu gulung',
    updatedAt: DateTime(2026, 10, 26, 09, 30),
    dirty: false,
  ),
  Note(
    id: 3,
    title: 'Draft Laporan Praktikum Minggu 9 AI',
    body: 'Dokumentasi workflow vibe coding, prompt 5 slot, dan Clean Architecture.',
    updatedAt: DateTime(2026, 10, 26, 08, 00),
    dirty: true,
  ),
  Note(
    id: 4,
    title: 'Jadwal Kuliah Pemrograman Mobile',
    body: 'Senin 07.00 - 12.00 WIB di Lab JTI Polinema',
    updatedAt: DateTime(2026, 10, 25, 14, 00),
    dirty: false,
  ),
];

final samplePosts = [
  const Post(
    id: 1,
    title: 'sunt aut facere repellat provident occaecati excepturi optio',
    body: 'quia et suscipit suscipit recusandae consequuntur expedita et cum reprehenderit molestiae',
  ),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRealFonts();
  });

  testWidgets('01 Screenshot Notes Search Initial All', (tester) async {
    SharedPreferences.setMockInitialValues({'dark_mode': false});
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(
              ScreenshotNoteRepository(notes: sampleNotes),
            ),
            syncServiceProvider.overrideWithValue(
              ScreenshotSyncService(posts: samplePosts),
            ),
          ],
          child: const OfflineNotesApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await saveScreenshot(tester, key, '01_notes_search_initial_all.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('02 Screenshot Notes Search Query Matched', (tester) async {
    SharedPreferences.setMockInitialValues({'dark_mode': false});
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(
              ScreenshotNoteRepository(notes: sampleNotes),
            ),
            syncServiceProvider.overrideWithValue(
              ScreenshotSyncService(posts: samplePosts),
            ),
          ],
          child: const OfflineNotesApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('search_notes_field')),
      'belanja',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await saveScreenshot(tester, key, '02_notes_search_query_matched.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('03 Screenshot Notes Search Empty State', (tester) async {
    SharedPreferences.setMockInitialValues({'dark_mode': false});
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            noteRepositoryProvider.overrideWithValue(
              ScreenshotNoteRepository(notes: sampleNotes),
            ),
            syncServiceProvider.overrideWithValue(
              ScreenshotSyncService(posts: samplePosts),
            ),
          ],
          child: const OfflineNotesApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('search_notes_field')),
      'zzz-tak-ada',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await saveScreenshot(tester, key, '03_notes_search_empty_state.png');
    await tester.pumpWidget(const SizedBox());
  });
}
