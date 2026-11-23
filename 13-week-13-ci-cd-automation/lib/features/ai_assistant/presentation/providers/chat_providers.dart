import 'dart:async';

import 'package:campus_notify/ai/ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ai_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/send_prompt_usecase.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final service = ref.watch(aiServiceProvider);
  return AiRepositoryImpl(aiService: service);
});

final sendPromptUseCaseProvider = Provider<SendPromptUseCase>((ref) {
  final repo = ref.watch(aiRepositoryProvider);
  return SendPromptUseCase(repo);
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? apiKey;
  final String? errorMessage;
  final List<String> suggestions;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.apiKey,
    this.errorMessage,
    this.suggestions = const [
      'Jadwal kampus hari Senin?',
      'Info beasiswa aktif semester ini?',
      'Prosedur konsultasi KRS online?',
      'Jam operasional perpustakaan?',
    ],
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? apiKey,
    String? errorMessage,
    List<String>? suggestions,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      apiKey: apiKey ?? this.apiKey,
      errorMessage: errorMessage,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    _initialize();
    return const ChatState();
  }

  Future<void> _initialize() async {
    final repo = ref.read(aiRepositoryProvider);
    final key = await repo.getApiKey();
    final welcomeMessage = ChatMessage(
      id: 'welcome-0',
      text:
          'Halo! Saya SobatKampus AI, asisten cerdas Polinema. Anda dapat bertanya tentang jadwal kuliah, beasiswa, KRS, perpustakaan, atau informasi kampus lainnya.\n\n'
          '⚠️ Catatan Keamanan: Jangan mengirimkan NIK, password, atau nomor telepon pribadi.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(apiKey: key, messages: [welcomeMessage]);
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || state.isLoading) return;

    final repo = ref.read(aiRepositoryProvider);
    final useCase = ref.read(sendPromptUseCaseProvider);

    final userMessage = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final result = await useCase.execute(query);

      // Siapkan bot message untuk streaming
      final botMsgId = 'bot-${DateTime.now().millisecondsSinceEpoch}';
      final initialBotMsg = ChatMessage(
        id: botMsgId,
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
        isFallback: result.isFallback,
      );

      state = state.copyWith(
        messages: [...state.messages, initialBotMsg],
        isLoading: false,
        isStreaming: true,
      );

      // Animasi streaming chunk-by-chunk untuk UX mobile interaktif
      await for (final chunk in repo.streamResponse(result.text)) {
        final updatedList = state.messages.map((m) {
          if (m.id == botMsgId) {
            return m.copyWith(text: chunk);
          }
          return m;
        }).toList();

        state = state.copyWith(messages: updatedList);
      }

      // Selesai streaming
      final finalList = state.messages.map((m) {
        if (m.id == botMsgId) {
          return m.copyWith(isStreaming: false);
        }
        return m;
      }).toList();

      state = state.copyWith(messages: finalList, isStreaming: false);
    } catch (e) {
      final errorMsg = ChatMessage(
        id: 'err-${DateTime.now().millisecondsSinceEpoch}',
        text: 'Maaf, terjadi gangguan saat memproses pesan: $e',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
        isStreaming: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> saveApiKey(String key) async {
    final repo = ref.read(aiRepositoryProvider);
    await repo.saveApiKey(key);
    final storedKey = await repo.getApiKey();
    state = state.copyWith(apiKey: storedKey);
  }

  Future<void> clearApiKey() async {
    final repo = ref.read(aiRepositoryProvider);
    await repo.clearApiKey();
    state = state.copyWith(apiKey: null);
  }

  void clearChat() {
    final welcomeMessage = ChatMessage(
      id: 'welcome-${DateTime.now().millisecondsSinceEpoch}',
      text: 'Riwayat percakapan telah dibersihkan. Silakan tanyakan hal baru seputar perkuliahan Polinema!',
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [welcomeMessage]);
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
