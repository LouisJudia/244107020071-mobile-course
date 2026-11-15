import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/network/api_errors.dart';
import 'package:campus_notify/core/utils/formatters.dart';

void main() {
  group('Unit Tests: Validasi Logika & Kasus Tepi (Edge Cases)', () {
    group('1. Aturan Validasi Teks & Autentikasi', () {
      test('Kasus Normal: Judul tugas atau input teks valid diterima', () {
        // Arrange
        const title = 'Pengumuman KRS Semester Ganjil';

        // Act
        final isValid = title.trim().isNotEmpty && title.trim().length >= 3;

        // Assert
        expect(isValid, isTrue);
      });

      test('Kasus Tepi: Menolak string kosong, spasi berlebih, atau whitespace murni', () {
        // Arrange & Act & Assert
        expect(''.trim().isNotEmpty, isFalse);
        expect('   '.trim().isNotEmpty, isFalse);
        expect('\t\n  \r'.trim().isNotEmpty, isFalse);
      });

      test('Kasus Tepi: Validasi format email kampus (@polinema.ac.id)', () {
        // Arrange
        bool isValidCampusEmail(String email) {
          final trimmed = email.trim();
          return trimmed.contains('@') &&
              trimmed.endsWith('polinema.ac.id') &&
              !trimmed.startsWith('@');
        }

        // Act & Assert
        expect(
          isValidCampusEmail('244107020071@student.polinema.ac.id'),
          isTrue,
        );
        expect(isValidCampusEmail('dosen@polinema.ac.id'), isTrue);
        expect(isValidCampusEmail(''), isFalse);
        expect(isValidCampusEmail('invalid-email'), isFalse);
        expect(isValidCampusEmail('@polinema.ac.id'), isFalse);
        expect(isValidCampusEmail('user@gmail.com'), isFalse);
      });

      test('Kasus Tepi: Validasi panjang password minimal 6 karakter', () {
        // Arrange
        bool isValidPassword(String pwd) => pwd.trim().length >= 6;

        // Act & Assert
        expect(isValidPassword('123456'), isTrue);
        expect(isValidPassword('secretPass!'), isTrue);
        expect(isValidPassword('12345'), isFalse);
        expect(isValidPassword('   12345   '), isFalse);
        expect(isValidPassword(''), isFalse);
      });
    });

    group('2. Aturan Format Data & Parsing Payload', () {
      test('Kasus Normal: maskToken memotong token panjang dengan rapi', () {
        // Arrange
        const token =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0';

        // Act
        final masked = maskToken(token, length: 12);

        // Assert
        expect(masked, equals('eyJhbGciOiJI...'));
        expect(masked.length, equals(15)); // 12 chars + '...'
      });

      test(
        'Kasus Tepi: maskToken menangani null dan string kosong tanpa crash',
        () {
          // Arrange & Act & Assert
          expect(maskToken(null), equals('Belum tersedia'));
          expect(maskToken(''), equals('Belum tersedia'));
          expect(maskToken('pendek', length: 10), equals('pendek'));
        },
      );

      test('Kasus Normal: routeFromMessage mengurai rute eksplisit', () {
        // Arrange
        final data = {'route': '/pengumuman/101'};

        // Act
        final route = routeFromMessage(data);

        // Assert
        expect(route, equals('/pengumuman/101'));
      });

      test('Kasus Tepi: routeFromMessage menambahkan slash depan atau fallback ke id', () {
        // Arrange & Act & Assert
        expect(
          routeFromMessage({'route': 'pengumuman/102'}),
          equals('/pengumuman/102'),
        );
        expect(routeFromMessage({'id': '99'}), equals('/pengumuman/99'));
        expect(routeFromMessage({}), equals('/'));
      });
    });

    group('3. Aturan Sanitasi Privasi & AI Cost Control Limiter', () {
      test('Kasus Tepi: Redaksi data sensitif NIK 16 digit dan nomor HP Indonesia', () {
        // Arrange
        const dirtyPrompt =
            'Tolong cek pengumuman untuk NIK 3507123456789012 dan kontak 081234567890.';

        // Act
        final cleanPrompt = dirtyPrompt
            .replaceAll(
              RegExp(r'\b\d{16}\b'),
              '[DATA PRIVASI NIK DIRAHASIAKAN]',
            )
            .replaceAll(
              RegExp(r'\b(\+62|62|0)8[1-9][0-9]{6,10}\b'),
              '[NOMOR TELEPON DIRAHASIAKAN]',
            );

        // Assert
        expect(cleanPrompt, isNot(contains('3507123456789012')));
        expect(cleanPrompt, isNot(contains('081234567890')));
        expect(cleanPrompt, contains('[DATA PRIVASI NIK DIRAHASIAKAN]'));
        expect(cleanPrompt, contains('[NOMOR TELEPON DIRAHASIAKAN]'));
      });

      test('Kasus Tepi: Penolakan prompt kosong atau hanya spasi', () {
        // Arrange
        const emptyPrompt = '   \t  \n';

        // Act
        final isBlank = emptyPrompt.trim().isEmpty;

        // Assert
        expect(isBlank, isTrue);
      });

      test('Kasus Kegagalan: Batas kuota harian (Cost Control) terlampaui', () {
        // Arrange
        const maxQuota = 30;
        int currentUsage = 30;

        // Act
        bool canSendRequest() => currentUsage < maxQuota;

        // Assert
        expect(canSendRequest(), isFalse);
      });
    });

    group('4. Pemetaan Pesan Error Jaringan & HTTP Status', () {
      test('Kasus Kegagalan: Pemetaan DioException status HTTP ke pesan ramah pengguna', () {
        // Arrange
        final dio401 = DioException(
          requestOptions: RequestOptions(path: '/api/announcements'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/announcements'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        final dio500 = DioException(
          requestOptions: RequestOptions(path: '/api/announcements'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/announcements'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );

        final dioTimeout = DioException(
          requestOptions: RequestOptions(path: '/api/announcements'),
          type: DioExceptionType.connectionTimeout,
        );

        // Act & Assert
        expect(
          getFriendlyErrorMessage(dio401),
          contains('Sesi login telah kedaluwarsa'),
        );
        expect(
          getFriendlyErrorMessage(dio500),
          contains('Server kampus sedang mengalami gangguan teknis'),
        );
        expect(
          getFriendlyErrorMessage(dioTimeout),
          contains('Waktu koneksi habis'),
        );
      });
    });
  });
}
