import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/home_page.dart';
import 'pages/stats_page.dart';
import 'pages/todo_page.dart';

/// Router aplikasi untuk daftar tugas dan halaman statistik.
final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => HomePage(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const TodoPage()),
        GoRoute(path: '/stats', builder: (context, state) => const StatsPage()),
      ],
    ),
  ],
);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Week 3',
      routerConfig: appRouter,
    );
  }
}
