import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:campus_notify/features/ai_assistant/domain/usecases/send_prompt_usecase.dart';
import 'package:campus_notify/features/ai_assistant/presentation/pages/chat_screen.dart';
import 'package:campus_notify/features/ai_assistant/presentation/providers/chat_providers.dart';
import 'package:campus_notify/features/ai_assistant/presentation/widgets/api_key_dialog.dart';
import 'package:campus_notify/features/announcements/presentation/pages/home_page.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_providers.dart';

class ScreenshotAiRepository implements AiRepository {
  @override
  Future<String> ask(String question, {bool useFallbackOnFail = true}) async {
    return 'Jadwal kuliah Senin: Pemrograman Mobile (07.00 - 10.30 WIB di Lab RPL) dan Basis Data Lanjut (11.00 - 13.30 WIB). Selalu pantau portal SIAKAD Polinema untuk info ruangan terbaru.';
  }

  @override
  Future<String?> getApiKey() async => 'AIzaSyA8B9C0-sample-secure-key';

  @override
  Future<void> saveApiKey(String key) async {}

  @override
  Future<void> clearApiKey() async {}

  @override
  Future<bool> hasApiKey() async => true;

  @override
  Stream<String> streamResponse(String text) async* {
    yield text;
  }

  @override
  String getLocalFallback(String question) =>
      AiService.getLocalFallback(question);
}

Future<void> saveScreenshot(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary != null) {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        final dir = Directory('screenshots');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        File('screenshots/$filename').writeAsBytesSync(bytes);
      }
      image.dispose();
    });
  }
}

Future<void> loadRealFonts() async {
  final fontFile = File(r'C:\Windows\Fonts\segoeui.ttf');
  if (fontFile.existsSync()) {
    final bytes = fontFile.readAsBytesSync();
    for (final family in ['Roboto', 'sans-serif', '.SF Pro Text']) {
      final fontLoader = FontLoader(family);
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();
    }
  }

  final boldFontFile = File(r'C:\Windows\Fonts\segoeuib.ttf');
  if (boldFontFile.existsSync()) {
    final bytes = boldFontFile.readAsBytesSync();
    final fontLoader = FontLoader('Roboto');
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    await loadRealFonts();
  });

  testWidgets('01 Generate Screenshot Chat Screen Initial', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = ScreenshotAiRepository();
    final useCase = SendPromptUseCase(mockRepo);
    final key = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            aiRepositoryProvider.overrideWithValue(mockRepo),
            sendPromptUseCaseProvider.overrideWithValue(useCase),
          ],
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
            ),
            home: const ChatScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await saveScreenshot(tester, key, '01_chat_screen_initial.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('02 Generate Screenshot Chat Screen Conversation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = ScreenshotAiRepository();
    final useCase = SendPromptUseCase(mockRepo);
    final key = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            aiRepositoryProvider.overrideWithValue(mockRepo),
            sendPromptUseCaseProvider.overrideWithValue(useCase),
          ],
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
            ),
            home: const ChatScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap first suggestion
    await tester.tap(find.text('Jadwal kampus hari Senin?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await saveScreenshot(tester, key, '02_chat_screen_conversation.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('03 Generate Screenshot API Key Dialog', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = ScreenshotAiRepository();
    final useCase = SendPromptUseCase(mockRepo);
    final key = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            aiRepositoryProvider.overrideWithValue(mockRepo),
            sendPromptUseCaseProvider.overrideWithValue(useCase),
          ],
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
            ),
            home: const Scaffold(body: Center(child: ApiKeyDialog())),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await saveScreenshot(tester, key, '03_api_key_dialog.png');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('04 Generate Screenshot Home Dashboard With AI Card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            savedSessionProvider.overrideWith(
              (ref) async => const AuthSession(
                access: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_access',
                refresh: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_refresh',
                email: 'louis.judia@polinema.ac.id',
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
            ),
            home: const HomePage(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await saveScreenshot(tester, key, '04_home_dashboard_ai_card.png');
    await tester.pumpWidget(const SizedBox());
  });
}
