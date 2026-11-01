import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_providers.dart';

class ApiKeyDialog extends ConsumerStatefulWidget {
  const ApiKeyDialog({super.key});

  @override
  ConsumerState<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends ConsumerState<ApiKeyDialog> {
  late final TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    final currentKey = ref.read(chatNotifierProvider).apiKey ?? '';
    _controller = TextEditingController(text: currentKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.key, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('Pengaturan API Key'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda. Kunci ini disimpan secara aman menggunakan FlutterSecureStorage dan tidak pernah dicatat dalam log publik.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan: Jika API Key kosong, sistem otomatis menggunakan "Mode Fallback Cerdas" dari database lokal kampus.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_controller.text.isNotEmpty)
          TextButton(
            onPressed: () async {
              await ref.read(chatNotifierProvider.notifier).clearApiKey();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Key berhasil dihapus')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () async {
            final key = _controller.text.trim();
            await ref.read(chatNotifierProvider.notifier).saveApiKey(key);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API Key berhasil disimpan')),
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
