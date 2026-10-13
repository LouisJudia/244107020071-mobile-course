import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';

/// Kontrak abstraksi repository untuk autentikasi
/// (Domain layer - Pure Dart, arah dependensi mengarah ke dalam)
abstract class AuthRepository {
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({String? renewedAccessToken, Failure? failure})> refreshToken(
    String refreshToken,
  );

  Future<({bool success, Failure? failure})> logout();

  Future<({AuthSession? session, Failure? failure})> getSavedSession();
}
