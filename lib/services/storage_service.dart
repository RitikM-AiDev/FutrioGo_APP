import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/api_keys.dart';
class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyGemini = 'gemini_api_key';
  static const String _keyTavily = 'tavily_api_key';
  static const String _keySerper = 'serper_api_key';
  static const String _keyGroq = 'groq_api_key';

  static Future<ApiKeys> loadKeys() async {
    try {
      final gemini = await _storage.read(key: _keyGemini) ?? '';
      final tavily = await _storage.read(key: _keyTavily) ?? '';
      final serper = await _storage.read(key: _keySerper) ?? '';
      final groq = await _storage.read(key: _keyGroq) ?? '';

      return ApiKeys(
        gemini: gemini.trim(),
        tavily: tavily.trim(),
        serper: serper.trim(),
        groq: groq.trim(),
      );
    } catch (e) {
      return const ApiKeys();
    }
  }

  static Future<void> saveKeys({
    String? gemini,
    String? tavily,
    String? serper,
    String? groq,
  }) async {
    if (gemini != null && gemini.trim().isNotEmpty) {
      await _storage.write(key: _keyGemini, value: gemini.trim());
    }
    if (tavily != null && tavily.trim().isNotEmpty) {
      await _storage.write(key: _keyTavily, value: tavily.trim());
    }
    if (serper != null && serper.trim().isNotEmpty) {
      await _storage.write(key: _keySerper, value: serper.trim());
    }
    if (groq != null && groq.trim().isNotEmpty) {
      await _storage.write(key: _keyGroq, value: groq.trim());
    }
  }

  static Future<void> clearKeys() async {
    await _storage.deleteAll();
  }
}

