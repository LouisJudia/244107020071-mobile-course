import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:campus_notify/features/ai_assistant/domain/usecases/send_prompt_usecase.dart';
import 'package:campus_notify/features/ai_assistant/presentation/pages/chat_screen.dart';
import 'package:campus_notify/features/ai_assistant/presentation/providers/chat_providers.dart';
import 'package:campus_notify/features/ai_assistant/presentation/widgets/api_key_dialog.dart';

class MockAiRepo implements AiRepository {
  String? _key = 'fake-gemini-key';

  @override
  Future<String> ask(String question, {bool useFallbackOnFail = true}) async {
    return 'Halo mahasiswa, ini respon pengujian AI untuk: $question';
  }

  @override
  Future<String?> getApiKey() async => _key;

  @override
  Future<void> saveApiKey(String key) async => _key = key;

  @override
  Future<void> clearApiKey() async => _key = null;

  @override
  Future<bool> hasApiKey() async => _key != null;

  @override
  Stream<String> streamResponse(String text) async* {
    yield text;
  }

  @override
  String getLocalFallback(String question) =>
      AiService.getLocalFallback(question);
}

void main() {
  Widget createWidgetUnderTest() {
    final mockRepo = MockAiRepo();
    final useCase = SendPromptUseCase(mockRepo);

    return ProviderScope(
      overrides: [
        aiRepositoryProvider.overrideWithValue(mockRepo),
        sendPromptUseCaseProvider.overrideWithValue(useCase),
      ],
      child: const MaterialApp(home: ChatScreen()),
    );
  }

  testWidgets(
    'ChatScreen renders correctly with header, input, chips and banner',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // flush initialization

      expect(find.text('SobatKampus AI'), findsOneWidget);
      expect(find.byKey(const Key('chat_api_key_button')), findsOneWidget);
      expect(find.byKey(const Key('chat_input_field')), findsOneWidget);
      expect(find.byKey(const Key('chat_send_button')), findsOneWidget);
      expect(find.textContaining('Privasi Terjaga'), findsOneWidget);

      // Initial greeting
      expect(find.textContaining('Halo! Saya SobatKampus AI'), findsOneWidget);

      // Quick suggestion chips
      expect(find.text('Jadwal kampus hari Senin?'), findsOneWidget);
    },
  );

  testWidgets('Tapping suggestion chip sends message and receives response', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Tap first suggestion chip
    final suggestionFinder = find.text('Jadwal kampus hari Senin?');
    expect(suggestionFinder, findsOneWidget);
    await tester.tap(suggestionFinder);
    await tester.pumpAndSettle();

    // Verifikasi pesan user dan respon bot tampil
    expect(find.text('Jadwal kampus hari Senin?'), findsWidgets);
    expect(
      find.textContaining('Halo mahasiswa, ini respon pengujian AI'),
      findsOneWidget,
    );
  });

  testWidgets('Tapping API Key button opens ApiKeyDialog', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byKey(const Key('chat_api_key_button')));
    await tester.pumpAndSettle();

    expect(find.byType(ApiKeyDialog), findsOneWidget);
    expect(find.text('Pengaturan API Key'), findsOneWidget);

    // Tutup dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.byType(ApiKeyDialog), findsNothing);
  });
}
