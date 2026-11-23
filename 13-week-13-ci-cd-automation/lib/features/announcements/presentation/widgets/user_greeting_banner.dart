import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

/// Widget banner sapaan pengguna yang dioptimasi dengan Riverpod select (Step 3 Codelab)
/// Hanya rebuild jika email berubah, bukan saat seluruh state sesi atau token di-refresh
class UserGreetingBanner extends ConsumerWidget {
  const UserGreetingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Isolasi rebuild: hanya dengarkan perubahan email
    final userEmail = ref.watch(
      savedSessionProvider.select(
        (s) => s.value?.email ?? 'Mahasiswa Polinema',
      ),
    );

    return RepaintBoundary(
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
