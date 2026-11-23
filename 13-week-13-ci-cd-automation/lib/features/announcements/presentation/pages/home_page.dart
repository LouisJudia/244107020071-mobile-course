import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../messaging/push_service.dart';
import '../../../../routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/announcement_providers.dart';
import '../widgets/announcement_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  String? _fcmToken;
  String _apiStatus = '';
  String _fcmStatus = '';
  bool _isLoadingApi = false;

  @override
  void initState() {
    super.initState();
    _setupFcm();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Listener Infinite Scroll (Step 4 Codelab: Pagination)
  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedAnnouncementsProvider.notifier).loadMore();
    }
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
    // Optimasi Riverpod: Menggunakan .select() untuk isolasi rebuild (Step 3 Codelab)
    final accessToken = ref.watch(
      savedSessionProvider.select((s) => s.value?.access),
    );
    final refreshToken = ref.watch(
      savedSessionProvider.select((s) => s.value?.refresh),
    );
    final userEmail = ref.watch(
      savedSessionProvider.select(
        (s) => s.value?.email ?? 'Mahasiswa Polinema',
      ),
    );

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
          await ref.read(paginatedAnnouncementsProvider.notifier).refresh();
          ref.invalidate(announcementsProvider);
          ref.invalidate(savedSessionProvider);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Banner terisolasi
              RepaintBoundary(
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary,
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
              ),

              const SizedBox(height: 12),

              // AI Assistant Quick Card (RepaintBoundary terisolasi)
              RepaintBoundary(
                child: Card(
                  elevation: 1,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    key: const Key('home_ai_card_tile'),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text(
                      'SobatKampus AI Assistant',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Tanya jadwal kuliah, beasiswa, atau info akademik kampus',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push(AppRoutes.chat),
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

              RepaintBoundary(
                child: Card(
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
                              ? 'Memproses Refresh...'
                              : 'Kirim Request API Terproteksi',
                        ),
                      ),
                      if (_apiStatus.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _apiStatus.contains('Sukses')
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _apiStatus.contains('Sukses')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          child: Text(
                            _apiStatus,
                            style: TextStyle(
                              fontSize: 12,
                              color: _apiStatus.contains('Sukses')
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section: Pengumuman Terkini (Lazy Loaded & Paginated)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pengumuman Terkini',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Lazy + Cache',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Muat Ulang',
                    onPressed: () {
                      ref
                          .read(paginatedAnnouncementsProvider.notifier)
                          .refresh();
                      ref.invalidate(announcementsProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Daftar Pengumuman: Menggunakan ListView.builder & AnnouncementTile
              _buildAnnouncementsSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('home_ai_chat_fab'),
        onPressed: () => context.push(AppRoutes.chat),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Tanya AI'),
      ),
    );
  }

  Widget _buildAnnouncementsSection(BuildContext context) {
    final paginated = ref.watch(paginatedAnnouncementsProvider);
    final legacyAsync = ref.watch(announcementsProvider);

    final items = paginated.items.isNotEmpty
        ? paginated.items
        : (legacyAsync.value ?? const []);

    final isLoading = paginated.isLoading && items.isEmpty;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Belum ada pengumuman tersedia.'),
        ),
      );
    }

    // Lazy list menggunakan ListView.builder
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length + (paginated.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final item = items[index];
        return AnnouncementTile(
          item: item,
          onTap: () {
            context.push(AppRoutes.announcementDetail(item.id));
          },
        );
      },
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
}
