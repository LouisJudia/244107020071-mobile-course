import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Satu tugas yang ditampilkan pada daftar ToDo.
class Todo {
  /// Membuat tugas dengan ID unik, judul, dan status penyelesaian.
  const Todo({required this.id, required this.title, this.isCompleted = false});

  /// ID dipakai untuk memperbarui tugas yang tepat.
  final String id;

  /// Teks tugas yang dimasukkan pengguna.
  final String title;

  /// Menandakan apakah tugas telah selesai.
  final bool isCompleted;

  /// Menghasilkan salinan tugas dengan status selesai yang baru.
  Todo copyWith({bool? isCompleted}) =>
      Todo(id: id, title: title, isCompleted: isCompleted ?? this.isCompleted);
}

/// Menyimpan dan mengubah daftar tugas utama aplikasi.
class TodoListNotifier extends Notifier<List<Todo>> {
  /// Daftar baru selalu dimulai dari keadaan kosong.
  @override
  List<Todo> build() => [];

  /// Menambahkan tugas baru bila teksnya tidak kosong.
  void add(String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    state = [
      ...state,
      Todo(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: trimmedTitle,
      ),
    ];
  }

  /// Mengubah status selesai sebuah tugas berdasarkan [id].
  void toggle(String id) {
    state = [
      for (final todo in state)
        todo.id == id ? todo.copyWith(isCompleted: !todo.isCompleted) : todo,
    ];
  }
}

/// Provider sumber data seluruh daftar tugas.
final todoListProvider = NotifierProvider<TodoListNotifier, List<Todo>>(
  TodoListNotifier.new,
);

/// Provider turunan yang hanya menyajikan tugas yang belum selesai.
final incompleteTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) => !todo.isCompleted).toList(growable: false);
});
