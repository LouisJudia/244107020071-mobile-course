import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:campus_notify/ai/ai_service.dart';
import 'package:campus_notify/core/errors/failures.dart';
import 'package:campus_notify/features/ai_assistant/data/repositories/ai_repository_impl.dart';
import 'package:campus_notify/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:campus_notify/features/ai_assistant/domain/usecases/send_prompt_usecase.dart';

class MockHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) handler;
  MockHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request as http.Request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class FakeAiRepository implements AiRepository {
  String? apiKey;
  bool shouldThrow = false;
  String customResponse = 'Respon simulasi AI asisten';

  @override
  Future<String> ask(String question, {bool useFallbackOnFail = true}) async {
    if (shouldThrow) {
      if (useFallbackOnFail) {
        return getLocalFallback(question);
      }
      throw Exception('Network timeout / simulated failure');
    }
    return customResponse;
  }

  @override
  Future<String?> getApiKey() async => apiKey;

  @override
  Future<void> saveApiKey(String key) async => apiKey = key;

  @override
  Future<void> clearApiKey() async => apiKey = null;

  @override
  Future<bool> hasApiKey() async => apiKey != null && apiKey!.isNotEmpty;

  @override
  Stream<String> streamResponse(String text) async* {
    yield text;
  }

  @override
  String getLocalFallback(String question) =>
      AiService.getLocalFallback(question);
}

void main() {
  group('AiService Unit Tests', () {
    test('Throws Exception when API Key is missing or empty', () async {
      final storage = <String, String>{};
      final service = AiService(inMemoryStorage: storage);

      expect(
        () => service.ask('Jadwal kuliah?'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API key tidak tersedia'),
          ),
        ),
      );
    });

    test(
      'Posts request to Gemini endpoint and parses 200 OK candidate text',
      () async {
        final storage = {'ai_api_key': 'test-secret-key-123'};
        var capturedUri = '';
        var capturedBody = '';

        final mockClient = MockHttpClient((req) async {
          capturedUri = req.url.toString();
          capturedBody = req.body;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Jadwal hari Senin adalah Pemrograman Mobile.'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        });

        final service = AiService(inMemoryStorage: storage, client: mockClient);

        final response = await service.ask('Jadwal hari Senin apa saja?');

        expect(response, 'Jadwal hari Senin adalah Pemrograman Mobile.');
        expect(capturedUri, contains('key=test-secret-key-123'));
        expect(capturedBody, contains('systemInstruction'));
        expect(capturedBody, contains('Jadwal hari Senin apa saja?'));
      },
    );

    test('Handles 403 / 400 (Invalid API key or quota exceeded)', () async {
      final storage = {'ai_api_key': 'invalid-key'};
      final mockClient = MockHttpClient((req) async {
        return http.Response('Forbidden', 403);
      });

      final service = AiService(inMemoryStorage: storage, client: mockClient);

      expect(
        () => service.ask('Halo'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Kunci API tidak valid atau kuota habis'),
          ),
        ),
      );
    });

    test('Handles 429 Rate Limit Exceeded', () async {
      final storage = {'ai_api_key': 'valid-key'};
      final mockClient = MockHttpClient((req) async {
        return http.Response('Too Many Requests', 429);
      });

      final service = AiService(inMemoryStorage: storage, client: mockClient);

      expect(
        () => service.ask('Halo'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Rate limit tercapai'),
          ),
        ),
      );
    });

    test('sanitizePrompt removes sensitive 16-digit NIK and Indonesian phone numbers', () {
      const input =
          'Halo NIK saya 3507041234567890 dan no WA saya 081234567890 tolong cek status beasiswa';
      final cleaned = AiService.sanitizePrompt(input);

      expect(cleaned, isNot(contains('3507041234567890')));
      expect(cleaned, isNot(contains('081234567890')));
      expect(cleaned, contains('[DATA NIK DISENSOR]'));
      expect(cleaned, contains('[NOMOR HP DISENSOR]'));
    });

    test('getLocalFallback returns domain-appropriate campus data', () {
      final scheduleAnswer = AiService.getLocalFallback(
        'Kapan jadwal kuliah Senin?',
      );
      expect(scheduleAnswer, contains('Pemrograman Mobile'));

      final scholarshipAnswer = AiService.getLocalFallback(
        'Info beasiswa apa saja?',
      );
      expect(scholarshipAnswer, contains('KIP-Kuliah'));

      final krsAnswer = AiService.getLocalFallback(
        'Batas waktu konsultasi KRS?',
      );
      expect(krsAnswer, contains('KRS online'));

      final libraryAnswer = AiService.getLocalFallback(
        'Jam buka perpustakaan pusat?',
      );
      expect(libraryAnswer, contains('Perpustakaan Pusat Polinema'));
    });

    test(
      'streamResponse splits text into progressive cumulative chunks',
      () async {
        final service = AiService(inMemoryStorage: {});
        final chunks = await service
            .streamResponse('Halo mahasiswa Polinema')
            .toList();

        expect(chunks.first, 'Halo');
        expect(chunks.last, 'Halo mahasiswa Polinema');
        expect(chunks.length, 3);
      },
    );

    test('saveApiKey and clearApiKey modify storage correctly', () async {
      final storage = <String, String>{};
      final service = AiService(inMemoryStorage: storage);

      await service.saveApiKey('key-xyz');
      expect(await service.getApiKey(), 'key-xyz');

      await service.clearApiKey();
      expect(await service.getApiKey(), isNull);
    });
  });

  group('SendPromptUseCase Unit Tests', () {
    late FakeAiRepository fakeRepo;
    late SendPromptUseCase useCase;

    setUp(() {
      fakeRepo = FakeAiRepository();
      useCase = SendPromptUseCase(fakeRepo);
    });

    test(
      'Throws ValidationFailure when prompt is empty or spaces only',
      () async {
        expect(() => useCase.execute('   '), throwsA(isA<ValidationFailure>()));
      },
    );

    test('Sanitizes personal info and receives normal AI response', () async {
      fakeRepo.customResponse = 'Status beasiswa terverifikasi.';
      final result = await useCase.execute(
        'Cek beasiswa untuk NIK 3507041234567890 sekarang',
      );

      expect(result.wasSanitized, isTrue);
      expect(result.sanitizedPrompt, contains('[DATA NIK DISENSOR]'));
      expect(result.isFallback, isFalse);
      expect(result.text, 'Status beasiswa terverifikasi.');
    });

    test(
      'Enforces cost control rate limiting (max 30 daily requests)',
      () async {
        for (int i = 0; i < SendPromptUseCase.maxDailyRequests; i++) {
          await useCase.execute('Pertanyaan ke-$i');
        }

        expect(useCase.requestCountToday, SendPromptUseCase.maxDailyRequests);

        // Request ke-31 harus dialihkan ke fallback dengan peringatan biaya
        final overLimitResult = await useCase.execute(
          'Pertanyaan melebihi kuota',
        );
        expect(overLimitResult.isFallback, isTrue);
        expect(overLimitResult.text, contains('Batas kuota gratis harian'));
      },
    );

    test(
      'Automatically falls back to local data if AI repository throws',
      () async {
        fakeRepo.shouldThrow = true;
        final result = await useCase.execute('Jadwal kuliah hari Senin?');

        expect(result.isFallback, isTrue);
        expect(result.text, contains('Pemrograman Mobile'));
      },
    );
  });

  group('AiRepositoryImpl Unit Tests', () {
    test('Delegates to AiService and returns fallback on failure', () async {
      final storage = <String, String>{}; // No API key -> will fail
      final service = AiService(inMemoryStorage: storage);
      final repo = AiRepositoryImpl(aiService: service);

      final fallbackAnswer = await repo.ask('Info beasiswa polinema');
      expect(fallbackAnswer, contains('KIP-Kuliah'));

      expect(
        () => repo.ask('Info beasiswa', useFallbackOnFail: false),
        throwsA(isA<Exception>()),
      );
    });
  });
}
