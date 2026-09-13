import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

/// Halaman yang menampilkan statistik dan seluruh kemungkinan state async-nya.
class StatsPage extends ConsumerWidget {
  /// Membuat halaman statistik.
  const StatsPage({super.key});

  /// Membuat UI berdasarkan nilai yang sedang disediakan oleh [statsProvider].
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch membuat UI dibangun ulang saat loading, error, atau data berubah.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: statsAsync.when(
        // Spinner ditampilkan selama simulasi request dua detik berlangsung.
        loading: () => const Center(child: CircularProgressIndicator()),
        // Pesan error dan retry memungkinkan pengguna mencoba request lagi.
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gagal memuat statistik: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.read(statsProvider.notifier).retry(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        // ListView selalu menampilkan tiga metrik saat request berhasil.
        data: (statistics) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: statistics.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final statistic = statistics[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.insights),
                title: Text(statistic.label),
                trailing: Text(
                  statistic.value,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
