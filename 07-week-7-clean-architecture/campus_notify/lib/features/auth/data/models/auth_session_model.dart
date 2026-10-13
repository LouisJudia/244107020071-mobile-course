import '../../domain/entities/auth_session.dart';

/// Model representasi data otentikasi (Data layer)
/// Bertanggung jawab untuk serialisasi/deserialisasi dari/ke format data luar
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.access,
    required super.refresh,
    super.email,
  });

  factory AuthSessionModel.fromMap(Map<String, dynamic> map) {
    return AuthSessionModel(
      access: map['access'] as String? ?? '',
      refresh: map['refresh'] as String? ?? '',
      email: map['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'access': access,
        'refresh': refresh,
        if (email != null) 'email': email,
      };

  AuthSession toEntity() => AuthSession(
        access: access,
        refresh: refresh,
        email: email,
      );
}
