abstract class AiRepository {
  Future<String> ask(String question, {bool useFallbackOnFail = true});
  Future<String?> getApiKey();
  Future<void> saveApiKey(String key);
  Future<void> clearApiKey();
  Future<bool> hasApiKey();
  Stream<String> streamResponse(String text);
  String getLocalFallback(String question);
}
