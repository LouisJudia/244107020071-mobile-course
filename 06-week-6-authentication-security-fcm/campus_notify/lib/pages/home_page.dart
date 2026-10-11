import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../data/api_errors.dart';
import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _accessToken;
  String? _refreshToken;
  String? _fcmToken;
  String _apiStatus = '';
  String _fcmStatus = '';
  bool _isLoadingApi = false;

  final List<Map<String, String>> _announcements = [
    {
      'id': '101',
      'title': 'Jadwal UTS Semester Ganjil 2024/2025',
      'date': '07 Okt 2024',
      'category': 'Akademik',
      'content': 'Ujian Tengah Semester (UTS) akan dilaksanakan secara luring mulai tanggal 14 Oktober 2024. Harap persiapkan kartu ujian dan hadir tepat waktu.'
    },
    {
      'id': '102',
      'title': 'Pendaftaran Beasiswa Prestasi Mahasiswa',
      'date': '05 Okt 2024',
      'category': 'Beasiswa',
      'content': 'Pendaftaran Beasiswa Prestasi periode Ganjil telah dibuka sampai 20 Oktober 2024. Lengkapi berkas persyaratannya melalui portal akademik.'
    },
    {
      'id': '103',
      'title': 'Pemeliharaan Server Portal Akademik',
      'date': '01 Okt 2024',
      'category': 'Sistem',
      'content': 'Server portal akademik akan mengalami downtime sementara pada Sabtu malam jam 23:00 - 03:00 WIB untuk peningkatan performa.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _setupFcm();
  }

  Future<void> _loadTokens() async {
    final store = ref.read(tokenStoreProvider);
    final access = await store.readAccess();
    final refresh = await store.readRefresh();
    if (mounted) {
      setState(() {
        _accessToken = access;
        _refreshToken = refresh;
      });
    }
  }

  Future<void> _setupFcm() async {
    final dio = ref.read(apiClientProvider);
    await initFcmToken(
      onToken: (token) async {
        if (mounted) {
          setState(() {
            _fcmToken = token;
            _fcmStatus = 'FCM Token dikirim ke backend /devices';
          });
        }
        try {
          await dio.post(
            '/devices',
            data: {
              'fcm_token': token,
              'platform': 'android',
            },
            options: Options(validateStatus: (_) => true),
          );
        } catch (e) {
          debugPrint('Error posting FCM token to backend: $e');
        }
      },
    );
  }

  Future<void> _testApiRefresh() async {
    setState(() {
      _isLoadingApi = true;
      _apiStatus = 'Mengirim request API...';
    });

    final dio = ref.read(apiClientProvider);

    try {
      final response = await dio.get(
        '/protected-data',
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      setState(() {
        _apiStatus = 'Response: ${response.statusCode} - Data diterima';
      });
    } catch (e) {
      setState(() {
        _apiStatus = 'Error: ${getFriendlyErrorMessage(e)}';
      });
    } finally {
      await _loadTokens();
      if (mounted) {
        setState(() {
          _isLoadingApi = false;
        });
      }
    }
  }

  Future<void> _testSimulatedNotification() async {
    await triggerSimulatedNotification(
      title: 'Jadwal Kuliah Berubah',
      body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00 WIB (Ketuk untuk detail).',
      route: AppRoutes.announcementDetail('101'),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi berhasil dipicu! Cek system tray atau ketuk untuk deep link.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatTruncatedToken(String? token) {
    if (token == null || token.isEmpty) return 'Belum tersedia (mock/offline)';
    if (token.length <= 12) return token;
    return '${token.substring(0, 12)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTokens();
          await _setupFcm();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security & Debug Info Card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Status Sesi & Debug FCM',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 4),
                      Text(
                        'Access Token:',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                      SelectableText(
                        _accessToken ?? 'Kosong',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Refresh Token:',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                      SelectableText(
                        _refreshToken ?? 'Kosong',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FCM Device Token (Terpotong 12 Karakter):',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                      SelectableText(
                        _formatTruncatedToken(_fcmToken),
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                      if (_fcmStatus.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _fcmStatus,
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoadingApi ? null : _testApiRefresh,
                            icon: _isLoadingApi
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, size: 18),
                            label: const Text('Uji Refresh Token (Dio)'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _testSimulatedNotification,
                            icon: const Icon(Icons.notifications_active, size: 18),
                            label: const Text('Uji Notifikasi FCM'),
                          ),
                        ],
                      ),
                      if (_apiStatus.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _apiStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pengumuman Terkini',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final item = _announcements[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        item['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  item['category']!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item['date']!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push(AppRoutes.announcementDetail(item['id']!));
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
