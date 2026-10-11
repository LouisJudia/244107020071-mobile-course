import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'local/db.dart';
import 'repositories/note_repository.dart';

class Post {
  final int id;
  final String title;
  final String body;

  const Post({
    required this.id,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
      };
}

class SyncService {
  SyncService({
    Future<Database> Function()? openDb,
    Dio? dio,
  })  : _openDb = openDb ?? openNotesDb,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://jsonplaceholder.typicode.com',
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 5),
              ),
            );

  final Future<Database> Function() _openDb;
  final Dio _dio;

  /// Sinkronisasi catatan kotor (dirty)
  /// Aturan konflik: last-write-wins berdasarkan updated_at
  Future<int> syncNotes(NoteRepository repo) async {
    final dirtyCount = await repo.countDirty();
    if (dirtyCount == 0) return 0;

    // Simulasi upload ke server remote
    await Future.delayed(const Duration(milliseconds: 1200));
    await repo.markAllSynced();
    return dirtyCount;
  }

  /// Membaca post yang tersimpan di cache SQLite lokal
  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows.map((r) {
      final payload = r['payload'] as String;
      final map = jsonDecode(payload) as Map<String, dynamic>;
      return Post.fromJson(map);
    }).toList();
  }

  /// Refresh posts dari internet di background dan simpan ke SQLite
  Future<List<Post>> refreshPosts({bool forceOffline = false}) async {
    if (forceOffline) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        error: 'Simulasi Offline Aktif: Koneksi internet dimatikan.',
        type: DioExceptionType.connectionError,
      );
    }

    final response = await _dio.get('/posts');
    final rawList = response.data as List<dynamic>;
    // Ambil 10 post teratas untuk demo cache yang rapi
    final posts = rawList
        .take(10)
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();

    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.delete('cached_posts');
      final now = DateTime.now().toIso8601String();
      for (final post in posts) {
        await txn.insert(
          'cached_posts',
          {
            'id': post.id,
            'payload': jsonEncode(post.toJson()),
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return posts;
  }

  /// Pola Cache-First: Tampilkan data lokal segera, lalu perbarui di latar belakang jika online
  Future<List<Post>> loadPostsCacheFirst({bool forceOffline = false}) async {
    final cached = await readCachedPosts();
    if (cached.isNotEmpty) {
      // Refresh di latar belakang jika tidak dipaksa offline
      if (!forceOffline) {
        refreshPosts(forceOffline: false).catchError((_) => <Post>[]);
      }
      return cached;
    }

    // Jika cache kosong, ambil langsung dari jaringan
    return refreshPosts(forceOffline: forceOffline);
  }
}
