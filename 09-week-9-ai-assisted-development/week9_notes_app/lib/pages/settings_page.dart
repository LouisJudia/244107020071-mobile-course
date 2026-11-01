import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final lastOpenedProvider = FutureProvider<String?>((ref) async {
  return ref.watch(prefsRepositoryProvider).getLastOpened();
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkModeAsync = ref.watch(darkModeProvider);
    final lastOpenedAsync = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  darkModeAsync.value == true
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Tema Gelap (Dark Mode)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Disimpan persisten di SharedPreferences'),
                value: darkModeAsync.value ?? false,
                onChanged: darkModeAsync.isLoading
                    ? null
                    : (_) => ref.read(darkModeProvider.notifier).toggle(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                Icons.access_time_filled,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                'Terakhir Dibuka',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: lastOpenedAsync.when(
                data: (time) {
                  if (time == null || time.isEmpty) {
                    return const Text('Baru pertama kali membuka aplikasi');
                  }
                  final dt = DateTime.tryParse(time);
                  if (dt == null) return Text(time);
                  return Text(
                    '${dt.toLocal().day}/${dt.toLocal().month}/${dt.toLocal().year} ${dt.toLocal().hour.toString().padLeft(2, '0')}:${dt.toLocal().minute.toString().padLeft(2, '0')}:${dt.toLocal().second.toString().padLeft(2, '0')}',
                  );
                },
                loading: () => const Text('Memuat timestamp...'),
                error: (err, _) => Text('Gagal membaca: $err'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Praktikum 1 — SharedPreferences',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Seluruh preferensi key-value dikelola oleh PrefsRepository dan dibungkus dalam Riverpod Notifier, sehingga build() widget tidak memanggil SharedPreferences secara langsung.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
