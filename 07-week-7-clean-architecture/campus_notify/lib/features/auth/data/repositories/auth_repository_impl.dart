import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/token_store.dart';
import '../models/auth_session_model.dart';

/// Implementasi konkrit dari kontrak AuthRepository di Data Layer
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.store});

  final TokenStore store;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      // Simulasi panggilan jaringan otentikasi
      await Future.delayed(const Duration(milliseconds: 300));

      if (!email.contains('@') || password.length < 6) {
        return (
          session: null,
          failure: const AuthFailure('Email atau kata sandi tidak valid.'),
        );
      }

      final model = AuthSessionModel(
        access: 'mock-access-for-$email',
        refresh: 'mock-refresh-for-$email',
        email: email,
      );

      // Simpan kredensial token ke secure storage
      await store.save(
        access: model.access,
        refresh: model.refresh,
        email: email,
      );

      return (
        session: model.toEntity(),
        failure: null,
      );
    } catch (e) {
      return (
        session: null,
        failure: LocalFailure('Gagal melakukan proses login: $e'),
      );
    }
  }

  @override
  Future<({String? renewedAccessToken, Failure? failure})> refreshToken(
    String refreshToken,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      if (refreshToken.isEmpty) {
        return (
          renewedAccessToken: null,
          failure: const AuthFailure('Refresh token tidak ditemukan atau kosong.'),
        );
      }

      final renewed = 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
      await store.save(access: renewed, refresh: refreshToken);
      return (
        renewedAccessToken: renewed,
        failure: null,
      );
    } catch (e) {
      return (
        renewedAccessToken: null,
        failure: LocalFailure('Gagal memperbarui access token: $e'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> logout() async {
    try {
      await store.clear();
      return (success: true, failure: null);
    } catch (e) {
      return (
        success: false,
        failure: LocalFailure('Gagal membersihkan sesi login: $e'),
      );
    }
  }

  @override
  Future<({AuthSession? session, Failure? failure})> getSavedSession() async {
    try {
      final access = await store.readAccess();
      final refresh = await store.readRefresh();
      final email = await store.readEmail();

      if (access == null || refresh == null) {
        return (session: null, failure: null);
      }

      final model = AuthSessionModel(
        access: access,
        refresh: refresh,
        email: email,
      );

      return (
        session: model.toEntity(),
        failure: null,
      );
    } catch (e) {
      return (
        session: null,
        failure: LocalFailure('Gagal membaca sesi tersimpan: $e'),
      );
    }
  }
}
