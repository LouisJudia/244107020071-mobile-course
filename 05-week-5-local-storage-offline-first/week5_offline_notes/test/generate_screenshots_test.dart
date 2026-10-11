import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/sync.dart';
import 'package:week5_offline_notes/main.dart';
import 'package:week5_offline_notes/pages/note_detail_page.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';
import 'package:week5_offline_notes/pages/settings_page.dart';

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

class OfflineTrueNotifier extends ForceOfflineNotifier {
  @override
  bool build() => true;
}

Future<void> saveScreenshot(
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
        File('../screenshoot/$filename').writeAsBytesSync(bytes);
      }
      image.dispose();
    });
  }
}

final sampleDirtyNotes = [
  Note(
    id: 1,
    title: 'Catatan Belanja Mingguan (Offline)',
    body: '1. Telur 1kg\n2. Susu oat\n3. Sayur bayam & brokoli',
    updatedAt: DateTime(2026, 10, 11, 18, 20),
    dirty: true,
  ),
  Note(
    id: 2,
    title: 'Draft Laporan Praktikum Mobile',
    body: 'Menyelesaikan modul offline-first dengan sqflite dan Riverpod.',
    updatedAt: DateTime(2026, 10, 11, 17, 45),
    dirty: true,
  ),
  Note(
    id: 3,
    title: 'Jadwal Kuliah Semester 5',
    body: 'Senin: Mobile Course\nSelasa: Basis Data Lanjut',
    updatedAt: DateTime(2026, 10, 11, 15, 30),
    dirty: false,
  ),
];

final sampleSyncedNotes = [
  Note(
    id: 1,
    title: 'Catatan Belanja Mingguan (Offline)',
    body: '1. Telur 1kg\n2. Susu oat\n3. Sayur bayam & brokoli',
    updatedAt: DateTime(2026, 10, 11, 18, 20),
    dirty: false,
  ),
  Note(
    id: 2,
    title: 'Draft Laporan Praktikum Mobile',
    body: 'Menyelesaikan modul offline-first dengan sqflite dan Riverpod.',
    updatedAt: DateTime(2026, 10, 11, 17, 45),
    dirty: false,
  ),
  Note(
    id: 3,
    title: 'Jadwal Kuliah Semester 5',
    body: 'Senin: Mobile Course\nSelasa: Basis Data Lanjut',
    updatedAt: DateTime(2026, 10, 11, 15, 30),
    dirty: false,
  ),
];

final samplePosts = [
  const Post(
    id: 1,
    title: 'sunt aut facere repellat provident occaecati excepturi optio',
    body:
        'quia et suscipit suscipit recusandae consequuntur expedita et cum reprehenderit molestiae ut ut quas totam nostrum rerum est autem sunt rem eveniet architecto',
  ),
  const Post(
    id: 2,
    title: 'qui est esse',
    body:
        'est rerum tempore vitae sequi sint nihil reprehenderit dolor beatae ea dolores neque fugiat blanditiis voluptate porro vel nihil molestiae ut reiciendis',
  ),
  const Post(
    id: 3,
    title: 'ea molestias quasi exercitationem repellat qui ipsa sit aut',
    body:
        'et iusto sed quo iure voluptatem occaecati omnis eligendi aut ad voluptatem doloribus vel accusantium quis pariatur molestiae porro eius odio et labore et velit aut',
  ),
];

void main() {
  testWidgets('01 Screenshot Notes Offline Dirty', (tester) async {
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
              ScreenshotNoteRepository(notes: sampleDirtyNotes),
            ),
            syncServiceProvider.overrideWithValue(
              ScreenshotSyncService(posts: samplePosts),
            ),
            forceOfflineProvider.overrideWith(OfflineTrueNotifier.new),
          ],
          child: const OfflineNotesApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await saveScreenshot(tester, key, '01_notes_offline_dirty.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('02 Screenshot Notes Synced Online', (tester) async {
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
              ScreenshotNoteRepository(notes: sampleSyncedNotes),
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
    await saveScreenshot(tester, key, '02_notes_synced_online.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('03 Screenshot Note Detail', (tester) async {
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
              ScreenshotNoteRepository(notes: sampleDirtyNotes),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
            ),
            home: const NoteDetailPage(noteId: 1),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await saveScreenshot(tester, key, '03_note_detail.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('04 Screenshot Settings Light Mode', (tester) async {
    SharedPreferences.setMockInitialValues({
      'dark_mode': false,
      'last_opened_at': '2026-10-11T18:25:00.000Z',
    });
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
            ),
            home: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await saveScreenshot(tester, key, '04_settings_light.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('05 Screenshot Settings Dark Mode', (tester) async {
    SharedPreferences.setMockInitialValues({
      'dark_mode': true,
      'last_opened_at': '2026-10-11T18:25:00.000Z',
    });
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.indigo,
            ),
            home: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await saveScreenshot(tester, key, '05_settings_dark.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('06 Screenshot Cache First API', (tester) async {
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
              ScreenshotNoteRepository(notes: sampleSyncedNotes),
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
    await tester.tap(find.text('Cache-First API'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await saveScreenshot(tester, key, '06_cache_first_api.png');
    await tester.pumpWidget(const SizedBox());
  });
}
