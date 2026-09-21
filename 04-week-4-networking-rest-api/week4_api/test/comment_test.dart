import 'package:flutter_test/flutter_test.dart';

import 'package:week4_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson memakai fallback saat field hilang', () {
    // JSON parsial meniru response API yang tidak lengkap.
    final comment = Comment.fromJson({'id': 7, 'email': 'user@example.com'});

    // Field yang tersedia tetap dipetakan dan field yang hilang menjadi default.
    expect(comment.id, 7);
    expect(comment.email, 'user@example.com');
    expect(comment.postId, 0);
    expect(comment.name, '');
    expect(comment.body, '');
  });
}
