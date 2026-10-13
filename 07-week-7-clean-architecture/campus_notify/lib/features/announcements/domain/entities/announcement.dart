/// Entity murni bisnis mewakili Pengumuman Kampus
/// (Domain layer - Pure Dart, bebas ketergantungan framework & serialisasi)
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    required this.content,
    required this.author,
  });

  final String id;
  final String title;
  final String date;
  final String category;
  final String content;
  final String author;
}
