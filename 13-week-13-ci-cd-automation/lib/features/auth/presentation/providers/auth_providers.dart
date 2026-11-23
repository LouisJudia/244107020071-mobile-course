import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

// --- DATA LAYER WIRING (Dependency Injection) ---
final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore();
});

// Menghubungkan implementasi data ke kontrak domain interface
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final store = ref.watch(tokenStoreProvider);
  return AuthRepositoryImpl(store: store);
});

// --- DOMAIN LAYER WIRING (Use Cases) ---
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogoutUseCase(repository);
});

final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return CheckAuthStatusUseCase(repository);
});

// --- PRESENTATION LAYER STATE (UI State & Notifiers) ---
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final checkUseCase = ref.watch(checkAuthStatusUseCaseProvider);
    final result = await checkUseCase();
    return result.isAuthenticated;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase(email: email, password: password);

    if (result.failure != null) {
      state = AsyncError(
        Exception(result.failure!.message),
        StackTrace.current,
      );
    } else {
      state = const AsyncData(true);
      ref.invalidate(savedSessionProvider);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    final logoutUseCase = ref.read(logoutUseCaseProvider);
    await logoutUseCase();
    state = const AsyncData(false);
    ref.invalidate(savedSessionProvider);
  }
}

final savedSessionProvider = FutureProvider<AuthSession?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final result = await repository.getSavedSession();
  return result.session;
});
