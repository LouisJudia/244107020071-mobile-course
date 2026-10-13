import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case untuk memeriksa status otentikasi awal saat aplikasi dijalankan
class CheckAuthStatusUseCase {
  const CheckAuthStatusUseCase(this._repository);
  final AuthRepository _repository;

  Future<({bool isAuthenticated, AuthSession? session, Failure? failure})> call() async {
    final result = await _repository.getSavedSession();
    if (result.failure != null) {
      return (isAuthenticated: false, session: null, failure: result.failure);
    }
    final isAuth = result.session != null && result.session!.access.isNotEmpty;
    return (isAuthenticated: isAuth, session: result.session, failure: null);
  }
}
