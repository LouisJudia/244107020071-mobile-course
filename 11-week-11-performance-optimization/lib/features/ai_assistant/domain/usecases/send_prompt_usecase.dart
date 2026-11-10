import 'package:campus_notify/ai/ai_service.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/ai_repository.dart';

class SendPromptResult {
  final String text;
  final bool isFallback;
  final bool wasSanitized;
  final String sanitizedPrompt;

  const SendPromptResult({
    required this.text,
    required this.isFallback,
    required this.wasSanitized,
    required this.sanitizedPrompt,
  });
}

class SendPromptUseCase {
  final AiRepository _repository;
  static const int maxDailyRequests = 30;
  int _requestCountToday = 0;
  DateTime _lastResetDate = DateTime.now();

  SendPromptUseCase(this._repository);

  int get requestCountToday => _requestCountToday;

  void resetDailyCounter() {
    _requestCountToday = 0;
    _lastResetDate = DateTime.now();
  }

  Future<SendPromptResult> execute(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      throw const ValidationFailure('Pertanyaan tidak boleh kosong.');
    }

    // Cek reset hari untuk rate limiting
    final now = DateTime.now();
    if (now.day != _lastResetDate.day || now.month != _lastResetDate.month) {
      _requestCountToday = 0;
      _lastResetDate = now;
    }

    // Mitigasi Biaya: Batasi kuota request harian (Cost Control)
    if (_requestCountToday >= maxDailyRequests) {
      final fallbackAnswer = _repository.getLocalFallback(trimmed);
      return SendPromptResult(
        text:
            'Batas kuota gratis harian ($maxDailyRequests pesan) telah tercapai demi penghematan kuota API. '
            'Berikut informasi alternatif dari pangkalan data lokal:\n\n$fallbackAnswer',
        isFallback: true,
        wasSanitized: false,
        sanitizedPrompt: trimmed,
      );
    }

    // Mitigasi Privasi: Sanitasi data sensitif sebelum dikirim ke API luar
    final sanitized = AiService.sanitizePrompt(trimmed);
    final wasSanitized = sanitized != trimmed;

    _requestCountToday++;

    try {
      final response = await _repository.ask(
        sanitized,
        useFallbackOnFail: false,
      );
      return SendPromptResult(
        text: response,
        isFallback: false,
        wasSanitized: wasSanitized,
        sanitizedPrompt: sanitized,
      );
    } catch (_) {
      // Mitigasi Downtime/Network Failure: Fallback ke basis pengetahuan lokal
      final fallbackResponse = _repository.getLocalFallback(sanitized);
      return SendPromptResult(
        text: fallbackResponse,
        isFallback: true,
        wasSanitized: wasSanitized,
        sanitizedPrompt: sanitized,
      );
    }
  }
}
