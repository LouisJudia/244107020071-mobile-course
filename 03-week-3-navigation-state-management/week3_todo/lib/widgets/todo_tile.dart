import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';

/// Satu baris tugas yang dapat ditandai selesai.
class TodoTile extends ConsumerWidget {
  /// Membuat tile untuk [todo] yang diberikan oleh daftar tugas.
  const TodoTile({required this.todo, super.key});

  /// Tugas yang divisualisasikan oleh tile ini.
  final Todo todo;

  /// Menampilkan checkbox dan judul, lalu mengubah state saat ditekan.
  @override
  Widget build(BuildContext context, WidgetRef ref) => CheckboxListTile(
    value: todo.isCompleted,
    onChanged: (_) => ref.read(todoListProvider.notifier).toggle(todo.id),
    title: Text(
      todo.title,
      style: todo.isCompleted
          ? const TextStyle(decoration: TextDecoration.lineThrough)
          : null,
    ),
  );
}
