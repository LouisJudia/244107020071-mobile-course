import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/errors/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:campus_notify/features/auth/domain/usecases/login_usecase.dart';
import 'package:campus_notify/features/auth/domain/usecases/logout_usecase.dart';

/// Fake repository murni untuk unit testing domain layer tanpa database / secure storage asli
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session, this.shouldFail = false});

  AuthSession? session;
  final bool shouldFail;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      return (
        session: null,
        failure: const AuthFailure('Kredensial salah (simulasi)'),
      );
    }
    final s = AuthSession(
      access: 'fake-access-$email',
      refresh: 'fake-refresh-$email',
      email: email,
    );
    session = s;
    return (session: s, failure: null);
  }

  @override
  Future<({String? renewedAccessToken, Failure? failure})> refreshToken(
    String refreshToken,
  ) async {
    if (shouldFail) {
      return (
        renewedAccessToken: null,
        failure: const AuthFailure('Gagal refresh token'),
      );
    }
    return (renewedAccessToken: 'fake-renewed-access', failure: null);
  }

  @override
  Future<({bool success, Failure? failure})> logout() async {
    session = null;
    return (success: true, failure: null);
  }

  @override
  Future<({AuthSession? session, Failure? failure})> getSavedSession() async {
    if (shouldFail) {
      return (
        session: null,
        failure: const LocalFailure('Gagal membaca storage'),
      );
    }
    return (session: session, failure: null);
  }
}

void main() {
  group('LoginUseCase Unit Tests', () {
    test('Login berhasil saat email valid dan password >= 6 karakter', () async {
      final repo = FakeAuthRepository();
      final useCase = LoginUseCase(repo);

      final result = await useCase(
        email: 'mahasiswa@polinema.ac.id',
        password: 'password123',
      );

      expect(result.failure, isNull);
      expect(result.session, isNotNull);
      expect(result.session?.access, contains('fake-access'));
      expect(result.session?.email, 'mahasiswa@polinema.ac.id');
    });

    test('Login gagal validasi saat format email tidak valid (tanpa @)', () async {
      final repo = FakeAuthRepository();
      final useCase = LoginUseCase(repo);

      final result = await useCase(
        email: 'bukanemail',
        password: 'password123',
      );

      expect(result.session, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure?.message, contains('Format email tidak valid'));
    });

    test('Login gagal validasi saat password kurang dari 6 karakter', () async {
      final repo = FakeAuthRepository();
      final useCase = LoginUseCase(repo);

      final result = await useCase(
        email: 'mahasiswa@polinema.ac.id',
        password: '123',
      );

      expect(result.session, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure?.message, contains('Kata sandi minimal harus 6 karakter'));
    });

    test('Login meneruskan AuthFailure dari repository saat autentikasi ditolak', () async {
      final repo = FakeAuthRepository(shouldFail: true);
      final useCase = LoginUseCase(repo);

      final result = await useCase(
        email: 'mahasiswa@polinema.ac.id',
        password: 'password123',
      );

      expect(result.session, isNull);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure?.message, 'Kredensial salah (simulasi)');
    });
  });

  group('Logout & CheckAuthStatusUseCase Unit Tests', () {
    test('LogoutUseCase berhasil membersihkan sesi', () async {
      final repo = FakeAuthRepository(
        session: const AuthSession(
          access: 'active-access',
          refresh: 'active-refresh',
        ),
      );
      final useCase = LogoutUseCase(repo);

      final result = await useCase();
      expect(result.success, isTrue);
      expect(repo.session, isNull);
    });

    test('CheckAuthStatusUseCase mendeteksi user aktif dari token tersimpan', () async {
      final repo = FakeAuthRepository(
        session: const AuthSession(
          access: 'active-access',
          refresh: 'active-refresh',
        ),
      );
      final useCase = CheckAuthStatusUseCase(repo);

      final result = await useCase();
      expect(result.isAuthenticated, isTrue);
      expect(result.session?.access, 'active-access');
    });

    test('CheckAuthStatusUseCase mengembalikan false saat belum ada sesi', () async {
      final repo = FakeAuthRepository(session: null);
      final useCase = CheckAuthStatusUseCase(repo);

      final result = await useCase();
      expect(result.isAuthenticated, isFalse);
      expect(result.session, isNull);
    });
  });
}
