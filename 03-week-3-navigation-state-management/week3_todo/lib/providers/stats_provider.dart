import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model sederhana untuk satu baris data yang ditampilkan di halaman statistik.
class Statistic {
  /// Membuat data statistik dengan judul dan nilai yang akan ditampilkan.
  const Statistic({required this.label, required this.value});

  /// Nama metrik, misalnya "Tugas selesai".
  final String label;

  /// Nilai metrik yang sesuai dengan [label].
  final String value;
}

/// Mengelola state asynchronous untuk pengambilan daftar statistik.
class StatsNotifier extends AsyncNotifier<List<Statistic>> {
  /// Membuat notifier dengan dependensi opsional agar mudah diuji.
  StatsNotifier({Random? random, Duration? delay})
    : _random = random ?? Random(),
      _delay = delay ?? const Duration(seconds: 2);

  /// Sumber angka acak untuk menentukan simulasi kegagalan 30%.
  final Random _random;

  /// Lama simulasi request jaringan.
  final Duration _delay;

  /// Memuat statistik pertama kali saat provider mulai didengarkan.
  @override
  Future<List<Statistic>> build() => _fetchStatistics();

  /// Memuat ulang data dan mengubah state menjadi loading selama proses berjalan.
  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchStatistics);
  }

  /// Meniru request API: menunggu dua detik dan gagal dengan peluang 30%.
  Future<List<Statistic>> _fetchStatistics() async {
    await Future<void>.delayed(_delay);

    // Angka 0.0 sampai kurang dari 0.3 berarti request simulasi gagal.
    if (_random.nextDouble() < 0.3) {
      throw Exception('Server statistik sedang tidak tersedia.');
    }

    // Data yang dikembalikan ketika request simulasi berhasil.
    return const [
      Statistic(label: 'Tugas selesai', value: '24'),
      Statistic(label: 'Tugas aktif', value: '8'),
      Statistic(label: 'Produktivitas', value: '75%'),
    ];
  }
}

/// Satu-satunya provider state statistik yang dipakai oleh halaman statistik.
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<Statistic>>(
  StatsNotifier.new,
  // Retry dilakukan lewat tombol di UI, bukan otomatis oleh Riverpod.
  retry: (_, _) => null,
);
