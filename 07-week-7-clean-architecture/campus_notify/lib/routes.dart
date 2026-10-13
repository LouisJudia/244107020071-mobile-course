import 'core/utils/formatters.dart' as fmt;

class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String announcementPattern = '/pengumuman/:id';

  static String announcementDetail(String id) => '/pengumuman/$id';
}

/// Helper delegasi ke fungsi murni formatters
String routeFromMessage(Map<String, dynamic> data) {
  return fmt.routeFromMessage(data);
}
