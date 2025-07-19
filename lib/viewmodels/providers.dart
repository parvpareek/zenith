import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../database/task_dao.dart';
import '../database/focus_session_dao.dart';
import '../database/log_entry_dao.dart';
import '../database/chat_message_dao.dart';
import '../database/tag_dao.dart';
import '../services/llm_service.dart';
import '../services/preferences_service.dart';

// Database providers
final databaseProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper());

final taskDAOProvider = Provider<TaskDAO>((ref) => TaskDAO());

final focusSessionDAOProvider = Provider<FocusSessionDAO>((ref) => FocusSessionDAO());

final logEntryDAOProvider = Provider<LogEntryDAO>((ref) => LogEntryDAO());

final chatMessageDAOProvider = Provider<ChatMessageDAO>((ref) => ChatMessageDAO());

final tagDAOProvider = Provider<TagDAO>((ref) => TagDAO());

// Preferences Service provider
final preferencesServiceProvider = Provider<PreferencesService>((ref) => PreferencesService.instance);

// LLM Service provider - now uses stored API key
final llmServiceProvider = FutureProvider<LLMService?>((ref) async {
  final prefsService = ref.watch(preferencesServiceProvider);
  final apiKey = await prefsService.getGeminiApiKey();
  
  if (apiKey == null || apiKey.trim().isEmpty) {
    return null; // No API key configured
  }
  
  return LLMService(apiKey: apiKey);
});

// API Key status provider
final apiKeyConfiguredProvider = FutureProvider<bool>((ref) async {
  final prefsService = ref.watch(preferencesServiceProvider);
  return await prefsService.hasGeminiApiKey();
});

// Current page provider for navigation
final currentPageProvider = StateProvider<int>((ref) => 0); // Start with Action Board (index 0) 