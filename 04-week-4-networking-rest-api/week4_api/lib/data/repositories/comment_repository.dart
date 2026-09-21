import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Menangani komunikasi endpoint komentar dengan JSONPlaceholder.
class CommentRepository {
  /// Menyimpan client Dio yang dipakai untuk request HTTP.
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil semua komentar untuk post tertentu.
  Future<List<Comment>> fetchComments(int postId) async {
    // Base URL dan seluruh timeout dipusatkan di createDio().
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: {'postId': postId},
    );

    // Response kosong diperlakukan sebagai list kosong, bukan null error.
    final data = response.data ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
