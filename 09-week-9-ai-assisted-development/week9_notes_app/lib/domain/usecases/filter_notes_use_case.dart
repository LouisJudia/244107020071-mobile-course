import '../../data/local/note.dart';

/// Use case murni (Domain layer) untuk menyaring catatan berdasarkan query judul.
/// Bebas dari dependensi Flutter, SQLite, Dio, maupun state management UI.
List<Note> filterNotes(List<Note> notes, String query) {
  final cleanQuery = query.trim().toLowerCase();
  if (cleanQuery.isEmpty) {
    return notes;
  }
  return notes.where((note) {
    return note.title.toLowerCase().contains(cleanQuery);
  }).toList();
}
