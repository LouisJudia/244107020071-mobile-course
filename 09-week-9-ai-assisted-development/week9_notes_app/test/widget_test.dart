import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/sync.dart';
import 'package:week5_offline_notes/main.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class MockNoteRepository extends NoteRepository {
  MockNoteRepository() : super(openDb: () => throw UnimplementedError());

  @override
  Future<List<Note>> fetchNotes() async {
    return [
      Note(
        id: 1,
        title: 'Catatan Pertama',
        body: 'Testing UI widget',
        updatedAt: DateTime.now(),
        dirty: false,
      ),
    ];
  }

  @override
  Future<int> countDirty() async => 0;
}

class MockSyncService extends SyncService {
  MockSyncService() : super(openDb: () => throw UnimplementedError());

  @override
  Future<List<Post>> loadPostsCacheFirst({bool forceOffline = false}) async =>
      [];

  @override
  Future<List<Post>> readCachedPosts() async => [];

  @override
  Future<int> syncNotes(NoteRepository repo) async => 0;
}

void main() {
  testWidgets('OfflineNotesApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'dark_mode': false});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
          syncServiceProvider.overrideWithValue(MockSyncService()),
        ],
        child: const OfflineNotesApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Offline-First Notes'), findsOneWidget);
    expect(find.text('Catatan Lokal'), findsOneWidget);
    expect(find.text('Catatan Pertama'), findsOneWidget);
  });
}
