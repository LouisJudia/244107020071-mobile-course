import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';
import 'note_detail_page.dart';
import 'settings_page.dart';

// Providers
final noteRepositoryProvider = Provider((ref) => NoteRepository());
final syncServiceProvider = Provider((ref) => SyncService());

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setOffline(bool value) => state = value;
}

final forceOfflineProvider = NotifierProvider<ForceOfflineNotifier, bool>(
  ForceOfflineNotifier.new,
);

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() {
    return ref.watch(noteRepositoryProvider).fetchNotes();
  }

  Future<void> addNote({required String title, String body = ''}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(noteRepositoryProvider);
      await repo.addNote(title: title, body: body);
      return repo.fetchNotes();
    });
  }

  Future<void> deleteNote(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(noteRepositoryProvider);
      await repo.deleteNote(id);
      return repo.fetchNotes();
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(noteRepositoryProvider).fetchNotes();
    });
  }
}

final dirtyCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  ref.watch(notesProvider);
  return repo.countDirty();
});

final syncStateProvider = AsyncNotifierProvider<SyncNotifier, int?>(
  SyncNotifier.new,
);

class SyncNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async => null;

  Future<int> runSync() async {
    final isOffline = ref.read(forceOfflineProvider);
    if (isOffline) {
      throw Exception(
        'Mode offline aktif! Matikan mode offline untuk sinkronisasi.',
      );
    }

    state = const AsyncLoading();
    int synced = 0;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(noteRepositoryProvider);
      final syncService = ref.read(syncServiceProvider);
      synced = await syncService.syncNotes(repo);
      ref.invalidate(notesProvider);
      return synced;
    });
    return synced;
  }
}

final cachedPostsProvider =
    AsyncNotifierProvider<CachedPostsNotifier, List<Post>>(
      CachedPostsNotifier.new,
    );

class CachedPostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final syncService = ref.watch(syncServiceProvider);
    final isOffline = ref.watch(forceOfflineProvider);
    return syncService.loadPostsCacheFirst(forceOffline: isOffline);
  }

  Future<void> refresh() async {
    final syncService = ref.read(syncServiceProvider);
    final isOffline = ref.read(forceOfflineProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return syncService.refreshPosts(forceOffline: isOffline);
    });
  }
}

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Catatan Baru'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  hintText: 'Contoh: Belanja Mingguan',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bodyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan',
                  hintText: 'Tulis detail catatan...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                Navigator.pop(ctx);
                await ref
                    .read(notesProvider.notifier)
                    .addNote(title: title, body: body);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Catatan berhasil disimpan ke SQLite (dirty = 1)',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyCountAsync = ref.watch(dirtyCountProvider);
    final isOffline = ref.watch(forceOfflineProvider);
    final syncState = ref.watch(syncStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline-First Notes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: (dirtyCountAsync.value ?? 0) > 0,
                backgroundColor: Colors.orange,
                label: Text('${dirtyCountAsync.value ?? 0}'),
                child: const Icon(Icons.note_alt_outlined),
              ),
              text: 'Catatan Lokal',
            ),
            const Tab(
              icon: Icon(Icons.cloud_download_outlined),
              text: 'Cache-First API',
            ),
          ],
        ),
        actions: [
          // Tombol Sinkronisasi
          IconButton(
            icon: syncState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sinkronisasi Catatan',
            onPressed: syncState.isLoading
                ? null
                : () async {
                    try {
                      final count = await ref
                          .read(syncStateProvider.notifier)
                          .runSync();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text(
                              count > 0
                                  ? 'Berhasil sinkronisasi $count catatan kotor (dirty = 0)!'
                                  : 'Semua catatan sudah tersinkron.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  },
          ),
          // Pengaturan
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Koneksi / Simulasi Offline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isOffline ? Colors.amber.shade100 : Colors.blue.shade50,
            child: Row(
              children: [
                Icon(
                  isOffline ? Icons.wifi_off : Icons.wifi,
                  color: isOffline
                      ? Colors.orange.shade800
                      : Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOffline
                        ? 'Simulasi Offline Aktif (Semua operasi dari SQLite lokal)'
                        : 'Koneksi Online (Siap sinkronisasi remote)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOffline
                          ? Colors.orange.shade900
                          : Colors.blue.shade900,
                    ),
                  ),
                ),
                Switch(
                  value: isOffline,
                  activeThumbColor: Colors.orange,
                  onChanged: (val) {
                    ref.read(forceOfflineProvider.notifier).setOffline(val);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: CATATAN LOKAL
                RefreshIndicator(
                  onRefresh: () => ref.read(notesProvider.notifier).refresh(),
                  child: notesAsync.when(
                    data: (notes) {
                      if (notes.isEmpty) {
                        return Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.note_alt_outlined,
                                  size: 72,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum ada catatan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Ketuk tombol + di bawah untuk membuat catatan.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return NoteTile(
                            note: note,
                            onTap: () {
                              if (note.id != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NoteDetailPage(noteId: note.id!),
                                  ),
                                );
                              }
                            },
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Catatan?'),
                                  content: Text(
                                    'Catatan "${note.title}" akan dihapus dari SQLite.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && note.id != null) {
                                await ref
                                    .read(notesProvider.notifier)
                                    .deleteNote(note.id!);
                              }
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Memuat catatan lokal dari SQLite...'),
                        ],
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text('Gagal membaca SQLite: $err'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(notesProvider.notifier).refresh(),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: CACHE-FIRST API (JSONPlaceholder)
                Consumer(
                  builder: (context, ref, _) {
                    final postsAsync = ref.watch(cachedPostsProvider);
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(cachedPostsProvider.notifier).refresh(),
                      child: postsAsync.when(
                        data: (posts) {
                          if (posts.isEmpty) {
                            return const Center(
                              child: Text('Cache kosong dan sedang offline.'),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${post.id}'),
                                  ),
                                  title: Text(
                                    post.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    post.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_off,
                                  size: 48,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Gagal memuat API: $err',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => ref
                                      .read(cachedPostsProvider.notifier)
                                      .refresh(),
                                  child: const Text('Coba Refresh'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.add),
        label: const Text('Catatan Baru'),
      ),
    );
  }
}
