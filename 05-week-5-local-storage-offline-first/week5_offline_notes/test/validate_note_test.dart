import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';

void main() {
  group('Note Validation Tests (feat/notes-validation)', () {
    late NoteRepository repository;

    setUp(() {
      repository = NoteRepository(
        openDb: () => throw UnimplementedError('Database should not be accessed on invalid input'),
      );
    });

    test('addNote melempar ArgumentError jika judul kosong ("")', () async {
      expect(
        () => repository.addNote(title: ''),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('tidak boleh kosong'),
        )),
      );
    });

    test('addNote melempar ArgumentError jika judul hanya spasi ("   ")', () async {
      expect(
        () => repository.addNote(title: '     '),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('tidak boleh kosong'),
        )),
      );
    });
  });
}
