/// Entity murni bisnis mewakili sesi otentikasi pengguna
/// (Domain layer - Pure Dart tanpa framework Flutter / mapping data)
class AuthSession {
  const AuthSession({
    required this.access,
    required this.refresh,
    this.email,
  });

  final String access;
  final String refresh;
  final String? email;

  bool get isValid => access.isNotEmpty && refresh.isNotEmpty;
}
