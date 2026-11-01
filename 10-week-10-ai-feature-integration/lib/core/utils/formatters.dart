/// Pure utility functions for formatting and string parsing
/// (Pure Dart, zero Flutter framework dependencies)
library;

String maskToken(String? token, {int length = 12}) {
  if (token == null || token.isEmpty) return 'Belum tersedia';
  if (token.length <= length) return token;
  return '${token.substring(0, length)}...';
}

String routeFromMessage(Map<String, dynamic> data) {
  final explicitRoute = data['route'] as String?;
  if (explicitRoute != null && explicitRoute.isNotEmpty) {
    return explicitRoute.startsWith('/') ? explicitRoute : '/$explicitRoute';
  }

  final id = data['id'] as String?;
  if (id != null && id.isNotEmpty) {
    return '/pengumuman/$id';
  }

  return '/';
}
