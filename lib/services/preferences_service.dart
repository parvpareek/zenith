import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _geminiApiKeyKey = 'gemini_api_key';
  
  static PreferencesService? _instance;
  static PreferencesService get instance => _instance ??= PreferencesService._();
  PreferencesService._();
  
  SharedPreferences? _prefs;
  
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  Future<void> setGeminiApiKey(String apiKey) async {
    await initialize();
    await _prefs!.setString(_geminiApiKeyKey, apiKey);
  }
  
  Future<String?> getGeminiApiKey() async {
    await initialize();
    return _prefs!.getString(_geminiApiKeyKey);
  }
  
  Future<void> clearGeminiApiKey() async {
    await initialize();
    await _prefs!.remove(_geminiApiKeyKey);
  }
  
  Future<bool> hasGeminiApiKey() async {
    final apiKey = await getGeminiApiKey();
    return apiKey != null && apiKey.trim().isNotEmpty;
  }
} 