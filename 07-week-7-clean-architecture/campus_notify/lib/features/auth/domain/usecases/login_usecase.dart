import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case untuk operasi bisnis login mahasiswa
/// (Domain layer - Mengandung validasi bisnis independen)
class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<({AuthSession? session, Failure? failure})> call({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return (
        session: null,
        failure: const ValidationFailure('Email dan kata sandi wajib diisi'),
      );
    }

    if (!cleanEmail.contains('@')) {
      return (
        session: null,
        failure: const ValidationFailure(
          'Format email tidak valid (harus mengandung @)',
        ),
      );
    }

    if (cleanPassword.length < 6) {
      return (
        session: null,
        failure: const ValidationFailure('Kata sandi minimal harus 6 karakter'),
      );
    }

    return _repository.login(email: cleanEmail, password: cleanPassword);
  }
}
