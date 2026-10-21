import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/utils/formatters.dart';

void main() {
  group('Core Formatters & Masking Tests', () {
    test('maskToken memotong token melebihi panjang batas', () {
      expect(maskToken('123456789012345', length: 12), '123456789012...');
      expect(
        maskToken('mock-fcm-token-campus-client-101', length: 12),
        'mock-fcm-tok...',
      );
    });

    test('maskToken mengembalikan token utuh jika lebih pendek atau sama dengan batas', () {
      expect(maskToken('12345', length: 12), '12345');
    });

    test('maskToken menangani nilai null atau string kosong dengan aman', () {
      expect(maskToken(null), 'Belum tersedia');
      expect(maskToken(''), 'Belum tersedia');
    });

    test('routeFromMessage mengekstrak route dengan slash diawal', () {
      expect(routeFromMessage({'route': 'pengumuman/101'}), '/pengumuman/101');
      expect(routeFromMessage({'route': '/pengumuman/101'}), '/pengumuman/101');
    });

    test('routeFromMessage menggunakan fallback ID bila route tidak ada', () {
      expect(routeFromMessage({'id': '102'}), '/pengumuman/102');
    });

    test(
      'routeFromMessage mengembalikan default root "/" jika payload kosong',
      () {
        expect(routeFromMessage({}), '/');
      },
    );
  });
}
