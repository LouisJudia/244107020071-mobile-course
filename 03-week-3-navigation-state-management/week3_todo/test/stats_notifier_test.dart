import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/stats_provider.dart';

/// Random palsu agar unit test dapat menentukan hasil request dengan pasti.
class FixedRandom implements Random {
  /// Membuat random palsu yang selalu mengembalikan [nextDoubleValue].
  FixedRandom(this.nextDoubleValue);

  /// Nilai yang digunakan untuk mensimulasikan sukses atau gagal.
  final double nextDoubleValue;

  /// Mengembalikan nilai tetap untuk pengujian peluang kegagalan.
  @override
  double nextDouble() => nextDoubleValue;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

/// Notifier khusus test yang tidak menunggu dua detik agar test tetap cepat.
class TestStatsNotifier extends StatsNotifier {
  /// Meneruskan random palsu dan delay nol ke notifier produksi.
  TestStatsNotifier(Random random)
    : super(random: random, delay: Duration.zero);
}

void main() {
  group('StatsNotifier', () {
    test('menghasilkan tiga statistik ketika request berhasil', () async {
      // Nilai 0.5 lebih besar dari 0.3, sehingga simulasi harus berhasil.
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(() => TestStatsNotifier(FixedRandom(0.5))),
        ],
      );
      addTearDown(container.dispose);

      // future menunggu state AsyncData dari provider.
      final statistics = await container.read(statsProvider.future);

      expect(statistics, hasLength(3));
      expect(statistics.first.label, 'Tugas selesai');
      expect(statistics.last.value, '75%');
    });

    test('menghasilkan error ketika peluang gagal terpenuhi', () async {
      // Nilai 0.2 kurang dari 0.3, sehingga simulasi harus gagal.
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(() => TestStatsNotifier(FixedRandom(0.2))),
        ],
      );
      addTearDown(container.dispose);

      // future meneruskan exception yang berasal dari build notifier.
      await expectLater(
        container.read(statsProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
