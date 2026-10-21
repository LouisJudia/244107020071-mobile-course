import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../messaging/push_service.dart';
import '../../../../routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/announcement_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _fcmToken;
  String _apiStatus = '';
  String _fcmStatus = '';
  bool _isLoadingApi = false;

  @override
  void initState() {
    super.initState();
    _setupFcm();
  }

  Future<void> _setupFcm() async {
    await initFcmToken(
      onToken: (token) async {
        if (mounted) {
          setState(() {
            _fcmToken = token;
            _fcmStatus = 'FCM Token dikirim ke backend /devices';
          });
        }
      },
    );
  }

  Future<void> _testApiRefresh() async {
    setState(() {
      _isLoadingApi = true;
      _apiStatus = 'Mengirim request API...';
    });

    try {
      final message = await ref.refresh(testApiRefreshProvider.future);
      if (mounted) {
        setState(() {
          _isLoadingApi = false;
          _apiStatus = 'Sukses (200 OK): $message';
        });
        ref.invalidate(savedSessionProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingApi = false;
          _apiStatus =
              'Respon: ${e.toString().replaceFirst("Exception: ", "")}';
        });
        ref.invalidate(savedSessionProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(savedSessionProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    final accessToken = sessionAsync.value?.access;
    final refreshToken = sessionAsync.value?.refresh;
    final userEmail = sessionAsync.value?.email ?? 'Mahasiswa Polinema';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Notify',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            key: const Key('home_logout_button'),
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(announcementsProvider);
          ref.invalidate(savedSessionProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Banner
              Card(
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

              const SizedBox(height: 20),

              // Section: OWASP Security & Token Status
              Text(
                'Status Keamanan & Token (OWASP)',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTokenRow(
                        context,
                        'Access Token (Secure Storage)',
                        maskToken(accessToken),
                        Icons.key,
                        Colors.blue,
                      ),
                      const Divider(),
                      _buildTokenRow(
                        context,
                        'Refresh Token (Secure Storage)',
                        maskToken(refreshToken),
                        Icons.refresh,
                        Colors.orange,
                      ),
                      const Divider(),
                      _buildTokenRow(
                        context,
                        'FCM Registration Token',
                        maskToken(_fcmToken),
                        Icons.notifications_active,
                        Colors.green,
                      ),
                      if (_fcmStatus.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _fcmStatus,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.green[700],
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action: Test Auto Refresh Interceptor
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Uji Coba Auto Refresh Token (Dio Interceptor 401)',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mengirim request ke endpoint protected. Jika 401 Unauthorized, interceptor otomatis memperbarui token dan melakukan retry.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        key: const Key('home_test_refresh_button'),
                        onPressed: _isLoadingApi ? null : _testApiRefresh,
                        icon: _isLoadingApi
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isLoadingApi
                              ? 'Memproses...'
                              : 'Kirim Protected Request',
                        ),
                      ),
                      if (_apiStatus.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _apiStatus.contains('Sukses')
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _apiStatus.contains('Sukses')
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _apiStatus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _apiStatus.contains('Sukses')
                                  ? Colors.green[800]
                                  : Colors.brown[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Section: Announcements List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pengumuman Terkini',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '#pengumuman-kampus',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              announcementsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Gagal memuat pengumuman: $e'),
                  ),
                ),
                data: (announcements) {
                  if (announcements.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Belum ada pengumuman tersedia.'),
                      ),
                    );
                  }

                  return Column(
                    children: announcements.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            context.push(AppRoutes.announcementDetail(item.id));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(
                                          context,
                                          item.category,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _getCategoryTextColor(
                                            context,
                                            item.category,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      item.date,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Baca selengkapnya',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenRow(
    BuildContext context,
    String label,
    String maskedValue,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  maskedValue,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category) {
      case 'Akademik':
        return Colors.blue.withValues(alpha: 0.15);
      case 'Beasiswa':
        return Colors.green.withValues(alpha: 0.15);
      case 'Sistem':
        return Colors.orange.withValues(alpha: 0.15);
      default:
        return Colors.grey.withValues(alpha: 0.15);
    }
  }

  Color _getCategoryTextColor(BuildContext context, String category) {
    switch (category) {
      case 'Akademik':
        return Colors.blue[800]!;
      case 'Beasiswa':
        return Colors.green[800]!;
      case 'Sistem':
        return Colors.orange[800]!;
      default:
        return Colors.grey[800]!;
    }
  }
}
