class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String announcementPattern = '/pengumuman/:id';

  static String announcementDetail(String id) => '/pengumuman/$id';
}

/// Fungsi murni untuk mengekstrak rute tujuan dari payload FCM data.
/// Memastikan selalu diawali dengan slash dan menangani fallback id.
String routeFromMessage(Map<String, dynamic> data) {
  if (data.containsKey('route') && data['route'] != null) {
    final route = data['route'].toString().trim();
    if (route.isNotEmpty) {
      return route.startsWith('/') ? route : '/$route';
    }
  }

  if (data.containsKey('id') && data['id'] != null) {
    final id = data['id'].toString().trim();
    if (id.isNotEmpty) {
      return AppRoutes.announcementDetail(id);
    }
  }

  return AppRoutes.home;
}
