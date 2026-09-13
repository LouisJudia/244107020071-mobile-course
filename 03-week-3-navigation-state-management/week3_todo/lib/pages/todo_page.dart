import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

/// Halaman daftar tugas yang menampilkan tugas belum selesai.
class TodoPage extends ConsumerWidget {
  /// Membuat halaman ToDo.
  const TodoPage({super.key});

  /// Menampilkan daftar tugas atau keadaan kosong.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodosProvider);
    final activeFilter = ref.watch(todoFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ToDo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<TodoFilter>(
              segments: const [
                ButtonSegment(value: TodoFilter.all, label: Text('Semua')),
                ButtonSegment(
                  value: TodoFilter.incomplete,
                  label: Text('Belum selesai'),
                ),
              ],
              selected: {activeFilter},
              onSelectionChanged: (filters) => ref
                  .read(todoFilterProvider.notifier)
                  .select(filters.first),
            ),
          ),
          Expanded(
            child: todos.isEmpty
                ? const Center(child: Text('Belum ada tugas'))
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) => TodoTile(todo: todos[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Membuka dialog untuk memasukkan judul tugas baru.
  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddTodoDialog(
        onAdd: (title) => ref.read(todoListProvider.notifier).add(title),
      ),
    );
  }
}

/// Dialog yang memiliki controller sendiri selama dialog masih berada di tree.
class _AddTodoDialog extends StatefulWidget {
  /// Membuat dialog dan menerima aksi yang menambahkan tugas.
  const _AddTodoDialog({required this.onAdd});

  /// Callback untuk menyimpan teks tugas ke provider.
  final ValueChanged<String> onAdd;

  @override
  State<_AddTodoDialog> createState() => _AddTodoDialogState();
}

/// Mengelola siklus hidup TextEditingController untuk [_AddTodoDialog].
class _AddTodoDialogState extends State<_AddTodoDialog> {
  /// Controller hidup sampai overlay dialog benar-benar dihapus.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tambah tugas'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: const InputDecoration(hintText: 'Contoh: Kerjakan PR'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          widget.onAdd(_controller.text);
          Navigator.of(context).pop();
        },
        child: const Text('Tambah'),
      ),
    ],
  );
}
