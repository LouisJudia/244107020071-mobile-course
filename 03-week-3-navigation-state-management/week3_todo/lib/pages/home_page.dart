import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Kerangka bersama yang mempertahankan NavigationBar pada setiap rute utama.
class HomePage extends StatelessWidget {
  /// Membuat kerangka navigasi dan menampilkan halaman aktif sebagai [child].
  const HomePage({required this.child, super.key});

  /// Isi rute aktif dari GoRouter.
  final Widget child;

  /// Membuat navigation bar dan berpindah ke path yang dipilih.
  @override
  Widget build(BuildContext context) {
    final isStatsRoute = GoRouterState.of(context).uri.path == '/stats';

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: isStatsRoute ? 1 : 0,
        onDestinationSelected: (index) =>
            context.go(index == 0 ? '/' : '/stats'),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'ToDo'),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
        ],
      ),
    );
  }
}
