import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/announcement.dart';

/// Widget kartu pengumuman yang dioptimasi (Step 3 & 4 Codelab):
/// 1. RepaintBoundary untuk mengisolasi operasi render / paint
/// 2. const constructor & sub-widget terisolasi untuk meminimalkan rebuild
/// 3. CachedNetworkImage dengan batasan memCacheWidth & memCacheHeight
class AnnouncementTile extends StatelessWidget {
  final Announcement item;
  final VoidCallback onTap;

  const AnnouncementTile({super.key, required this.item, required this.onTap});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Akademik':
        return Colors.blue.withValues(alpha: 0.15);
      case 'Beasiswa':
        return Colors.green.withValues(alpha: 0.15);
      case 'Sistem':
        return Colors.orange.withValues(alpha: 0.15);
      case 'Prestasi':
        return Colors.purple.withValues(alpha: 0.15);
      default:
        return Colors.grey.withValues(alpha: 0.15);
    }
  }

  Color _getCategoryTextColor(String category) {
    switch (category) {
      case 'Akademik':
        return Colors.blue[800]!;
      case 'Beasiswa':
        return Colors.green[800]!;
      case 'Sistem':
        return Colors.orange[800]!;
      case 'Prestasi':
        return Colors.purple[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Isolasi paint menggunakan RepaintBoundary
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12.0),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar thumbnail dengan optimasi caching dan memCache sizing
              if (item.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 300,
                  memCacheHeight: 200,
                  placeholder: (context, url) => Container(
                    height: 140,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 140,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Center(
                      child: Icon(
                        Icons.campaign_outlined,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(item.category),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryTextColor(item.category),
                            ),
                          ),
                        ),
                        Text(
                          item.date,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Baca selengkapnya',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
