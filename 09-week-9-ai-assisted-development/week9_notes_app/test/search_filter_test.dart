import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/domain/usecases/filter_notes_use_case.dart';
import 'package:week5_offline_notes/pages/notes_page.dart';

class FakeSearchNoteRepository extends NoteRepository {
  FakeSearchNoteRepository(this.notes)
    : super(openDb: () => throw UnimplementedError());

  final List<Note> notes;

  @override
  Future<List<Note>> fetchNotes() async => notes;

  @override
  Future<int> countDirty() async => notes.where((n) => n.dirty).length;

  @override
  Future<void> markAllSynced() async {}
}

void main() {
  final sampleNotes = [
    Note(
      id: 1,
      title: 'Belanja Bulanan Supermarket',
      body: 'Beras, minyak, telur, sayur',
      updatedAt: DateTime.now(),
      dirty: false,
    ),
    Note(
      id: 2,
      title: 'Daftar BELANJA Elektronik',
      body: 'Kabel type-c, charger 65W',
      updatedAt: DateTime.now(),
      dirty: false,
    ),
    Note(
      id: 3,
      title: 'Rapat Proyek Flutter Polinema',
      body: 'Review Clean Architecture dan testing',
      updatedAt: DateTime.now(),
      dirty: true,
    ),
  ];

  group('Domain Use Case Unit Test: filterNotes', () {
    test('filter abaikan huruf besar/kecil', () {
      final result = filterNotes(sampleNotes, 'belanja');
      expect(result, hasLength(2));
      expect(result.any((n) => n.id == 1), isTrue);
      expect(result.any((n) => n.id == 2), isTrue);
      expect(result.any((n) => n.id == 3), isFalse);
    });

    test('query tak cocok kembalikan kosong', () {
      final result = filterNotes(sampleNotes, 'zzz-tak-ada');
      expect(result, isEmpty);
    });

    test('query kosong kembalikan seluruh notes', () {
      final result = filterNotes(sampleNotes, '');
      expect(result, hasLength(3));
    });

    test('query dengan spasi di-trim otomatis', () {
      final result = filterNotes(sampleNotes, '  flutter  ');
      expect(result, hasLength(1));
      expect(result.first.id, 3);
    });
  });

  group('Widget Test: Search & Empty State UI', () {
    testWidgets(
      'pencarian memfilter list dan menampilkan empty state jika tidak cocok',
      (tester) async {
        final fakeRepo = FakeSearchNoteRepository(sampleNotes);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [noteRepositoryProvider.overrideWithValue(fakeRepo)],
            child: const MaterialApp(home: NotesPage()),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verifikasi kondisi awal: seluruh 3 catatan tampil dan input search ada
        expect(find.text('Belanja Bulanan Supermarket'), findsOneWidget);
        expect(find.text('Daftar BELANJA Elektronik'), findsOneWidget);
        expect(find.text('Rapat Proyek Flutter Polinema'), findsOneWidget);
        expect(find.byKey(const Key('search_notes_field')), findsOneWidget);
        expect(find.byKey(const Key('search_empty_state')), findsNothing);

        // 2. Ketik query 'belanja'
        await tester.enterText(
          find.byKey(const Key('search_notes_field')),
          'belanja',
        );
        await tester.pumpAndSettle();

        // Verifikasi filter aktif: catatan rapat tersembunyi
        expect(find.text('Belanja Bulanan Supermarket'), findsOneWidget);
        expect(find.text('Daftar BELANJA Elektronik'), findsOneWidget);
        expect(find.text('Rapat Proyek Flutter Polinema'), findsNothing);

        // 3. Ketik query tak cocok 'zzz-tak-ada'
        await tester.enterText(
          find.byKey(const Key('search_notes_field')),
          'zzz-tak-ada',
        );
        await tester.pumpAndSettle();

        // Verifikasi empty state tampil dengan ikon dan teks penjelas
        expect(find.byKey(const Key('search_empty_state')), findsOneWidget);
        expect(find.text('Tidak ada catatan yang cocok'), findsOneWidget);
        expect(
          find.text('Tidak ditemukan catatan dengan judul "zzz-tak-ada"'),
          findsOneWidget,
        );
        expect(find.text('Belanja Bulanan Supermarket'), findsNothing);

        // 4. Reset query melalui tombol clear (suffix icon silang)
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // Verifikasi kembali normal: semua catatan muncul kembali
        expect(find.text('Belanja Bulanan Supermarket'), findsOneWidget);
        expect(find.text('Daftar BELANJA Elektronik'), findsOneWidget);
        expect(find.text('Rapat Proyek Flutter Polinema'), findsOneWidget);
        expect(find.byKey(const Key('search_empty_state')), findsNothing);
      },
    );
  });
}
