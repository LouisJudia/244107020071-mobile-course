import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_providers.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showPrivacyBanner = true;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) {
    final query = text ?? _textController.text;
    if (query.trim().isEmpty) return;

    ref.read(chatNotifierProvider.notifier).sendMessage(query);
    if (text == null) {
      _textController.clear();
    }
    _scrollToBottom();
  }

  void _showPrivacyInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.green),
            SizedBox(width: 8),
            Text('Privasi & Keamanan AI'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prinsip Keamanan Mobile Codelab Minggu 10:\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '1. Zero Sensitive Data: Jangan pernah kirim NIK, password, atau nomor telepon ke LLM cloud.',
            ),
            SizedBox(height: 6),
            Text(
              '2. Local Filtering: Input pengguna otomatis disaring dengan regular expressions sebelum dikirim ke API.',
            ),
            SizedBox(height: 6),
            Text(
              '3. Secure Storage: Kunci API disimpan terenkripsi di keychain perangkat.',
            ),
            SizedBox(height: 6),
            Text(
              '4. Cost Control: Kuota request harian dibatasi untuk menghindari lonjakan biaya API.',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final theme = Theme.of(context);

    // Auto scroll saat pesan baru datang atau saat streaming
    ref.listen<ChatState>(chatNotifierProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          next.isStreaming) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SobatKampus AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        chatState.apiKey != null && chatState.apiKey!.isNotEmpty
                        ? Colors.greenAccent
                        : Colors.amberAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  chatState.apiKey != null && chatState.apiKey!.isNotEmpty
                      ? 'Gemini 1.5 Flash Aktif'
                      : 'Mode Cadangan Lokal',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('chat_api_key_button'),
            icon: const Icon(Icons.key),
            tooltip: 'Konfigurasi API Key',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ApiKeyDialog(),
              );
            },
          ),
          PopupMenuButton<String>(
            key: const Key('chat_more_menu'),
            onSelected: (value) {
              if (value == 'clear') {
                ref.read(chatNotifierProvider.notifier).clearChat();
              } else if (value == 'privacy') {
                _showPrivacyInfoDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Bersihkan Percakapan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Kebijakan Privasi & Kuota'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner Privasi & Penghematan Biaya
            if (_showPrivacyBanner)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Privasi Terjaga: NIK, nomor HP, & sandi otomatis disaring sebelum dikirim ke AI API.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _showPrivacyBanner = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Daftar Percakapan
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount:
                    chatState.messages.length + (chatState.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < chatState.messages.length) {
                    return RepaintBoundary(
                      child: ChatBubble(message: chatState.messages[index]),
                    );
                  }
                  return const RepaintBoundary(child: TypingIndicator());
                },
              ),
            ),

            // Saran Pertanyaan Cepat (Quick Prompt Chips)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: chatState.suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = chatState.suggestions[index];
                  return ActionChip(
                    avatar: const Icon(Icons.flash_on, size: 14),
                    label: Text(prompt, style: const TextStyle(fontSize: 12)),
                    onPressed: chatState.isLoading || chatState.isStreaming
                        ? null
                        : () => _sendMessage(prompt),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chat_input_field'),
                      controller: _textController,
                      enabled: !chatState.isLoading,
                      decoration: InputDecoration(
                        hintText: 'Tanyakan info kampus / jadwal...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('chat_send_button'),
                    icon: chatState.isLoading || chatState.isStreaming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    onPressed: chatState.isLoading || chatState.isStreaming
                        ? null
                        : () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
