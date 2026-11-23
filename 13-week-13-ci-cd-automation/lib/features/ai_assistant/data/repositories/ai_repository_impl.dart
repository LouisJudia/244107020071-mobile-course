import 'dart:async';

import 'package:campus_notify/ai/ai_service.dart';

import '../../domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiService _aiService;

  AiRepositoryImpl({AiService? aiService})
    : _aiService = aiService ?? AiService();

  @override
  Future<String> ask(String question, {bool useFallbackOnFail = true}) async {
    try {
      return await _aiService.ask(question);
    } catch (e) {
      if (useFallbackOnFail) {
        return AiService.getLocalFallback(question);
      }
      rethrow;
    }
  }

  @override
  Future<String?> getApiKey() => _aiService.getApiKey();

  @override
  Future<void> saveApiKey(String key) => _aiService.saveApiKey(key);

  @override
  Future<void> clearApiKey() => _aiService.clearApiKey();

  @override
  Future<bool> hasApiKey() async {
    final key = await _aiService.getApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  @override
  Stream<String> streamResponse(String text) => _aiService.streamResponse(text);

  @override
  String getLocalFallback(String question) =>
      AiService.getLocalFallback(question);
}
