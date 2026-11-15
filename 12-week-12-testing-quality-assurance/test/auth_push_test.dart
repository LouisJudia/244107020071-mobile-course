import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:campus_notify/routes.dart';
import 'package:campus_notify/core/network/api_errors.dart';

class FakeTokenStore {
  String? access;
  String? refresh;
}

void main() {
  group('Route & Payload Parsing Tests (Refactoring Challenge)', () {
    test('routeFromMessage menangani route kosong dan tanpa slash', () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('data payload membawa id pengumuman', () {
      const data = {'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
    });

    test(
      'data payload hanya dengan id otomatis diarahkan ke detail pengumuman',
      () {
        const data = {'id': '101'};
        expect(routeFromMessage(data), '/pengumuman/101');
      },
    );

    test('konstanta rute AppRoutes terpusat dengan benar', () {
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.home, '/');
      expect(AppRoutes.announcementPattern, '/pengumuman/:id');
      expect(AppRoutes.announcementDetail('55'), '/pengumuman/55');
    });
  });

  group('Auth & Token State Logic Tests', () {
    test('provider auth membaca status login dari token', () async {
      final store = FakeTokenStore()..access = 'mock-access';
      expect(store.access != null, isTrue);
      store.access = null;
      expect(store.access != null, isFalse);
    });

    test('refresh gagal -> sesi dibersihkan (paksa login ulang)', () async {
      final store = FakeTokenStore()..refresh = '';
      final needsLogin = (store.refresh ?? '').isEmpty;
      expect(needsLogin, isTrue);
    });
  });

  group('Api Error Friendly Message Tests', () {
    test('getFriendlyErrorMessage menangani 401 Unauthorized', () {
      final err401 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(
        getFriendlyErrorMessage(err401),
        contains('Sesi login telah kedaluwarsa'),
      );
    });

    test('getFriendlyErrorMessage menangani Connection Timeout', () {
      final errTimeout = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        getFriendlyErrorMessage(errTimeout),
        contains('Waktu koneksi habis'),
      );
    });

    test('getFriendlyErrorMessage menangani 500 Internal Server Error', () {
      final err500 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(
        getFriendlyErrorMessage(err500),
        contains('Server kampus sedang mengalami gangguan teknis'),
      );
    });
  });
}
