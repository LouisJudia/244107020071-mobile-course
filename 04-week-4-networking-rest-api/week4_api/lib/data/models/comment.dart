/// Model satu komentar dari endpoint JSONPlaceholder.
class Comment {
  /// Membuat objek komentar dengan nilai yang sudah dinormalisasi.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  /// ID post yang memiliki komentar ini.
  final int postId;

  /// ID unik komentar.
  final int id;

  /// Nama penulis komentar.
  final String name;

  /// Email penulis komentar.
  final String email;

  /// Isi komentar.
  final String body;

  /// Mengubah JSON menjadi model dengan fallback aman untuk field yang hilang.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}
