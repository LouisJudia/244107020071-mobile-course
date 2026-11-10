import '../../domain/entities/announcement.dart';

/// Model representasi data pengumuman (Data layer)
/// Menangani mapping ke/dari Map / JSON
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.date,
    required super.category,
    required super.content,
    required super.author,
    super.imageUrl,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      date: map['date'] as String? ?? '',
      category: map['category'] as String? ?? 'Umum',
      content: map['content'] as String? ?? '',
      author: map['author'] as String? ?? 'Admin Kampus',
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'date': date,
    'category': category,
    'content': content,
    'author': author,
    'imageUrl': imageUrl,
  };

  Announcement toEntity() => Announcement(
    id: id,
    title: title,
    date: date,
    category: category,
    content: content,
    author: author,
    imageUrl: imageUrl,
  );
}
