import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/task.dart';
import '../models/focus_session.dart';
import '../models/log_entry.dart';
import '../database/chat_message_dao.dart';
import '../services/llm_service.dart';
import 'providers.dart';
import 'task_viewmodel.dart';
import 'focus_session_viewmodel.dart';
import 'log_entry_viewmodel.dart';

class AICoachState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final ContextOptions contextOptions;

  const AICoachState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.contextOptions = const ContextOptions(),
  });

  AICoachState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    ContextOptions? contextOptions,
  }) {
    return AICoachState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      contextOptions: contextOptions ?? this.contextOptions,
    );
  }
}

class AICoachNotifier extends StateNotifier<AICoachState> {
  final ChatMessageDAO _chatMessageDAO;
  final Ref _ref;

  AICoachNotifier(this._chatMessageDAO, this._ref) : super(const AICoachState()) {
    loadChatHistory();
  }

  Future<void> loadChatHistory() async {
    try {
      state = state.copyWith(isLoading: true);
      final messages = await _chatMessageDAO.getAllMessages();
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  void updateContextOptions(ContextOptions options) {
    state = state.copyWith(contextOptions: options);
  }

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    try {
      // Add user message to the chat
      final userChatMessage = ChatMessage(
        content: userMessage.trim(),
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );

      await _chatMessageDAO.insert(userChatMessage);
      
      // Update state with user message
      final updatedMessages = [...state.messages, userChatMessage];
      state = state.copyWith(
        messages: updatedMessages,
        isLoading: true,
        error: null,
      );

      // Get LLM service
      final llmServiceAsync = await _ref.read(llmServiceProvider.future);
      if (llmServiceAsync == null) {
        // No API key configured
        final errorMessage = ChatMessage(
          content: 'Please configure your Gemini API key first. You can get a free API key from Google AI Studio: https://makersuite.google.com/app/apikey',
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        );
        await _chatMessageDAO.insert(errorMessage);
        final finalMessages = [...updatedMessages, errorMessage];
        state = state.copyWith(
          messages: finalMessages,
          isLoading: false,
        );
        return;
      }

      // Build context string if any context is selected
      String? contextString;
      if (state.contextOptions.hasAnyContextSelected) {
        contextString = await _buildContextString();
      }

      // Send to LLM
      final response = await llmServiceAsync.sendMessage(userMessage, contextString: contextString);

      // Add assistant response to chat
      final assistantMessage = ChatMessage(
        content: response,
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
      );

      await _chatMessageDAO.insert(assistantMessage);
      
      // Update state with assistant response
      final finalMessages = [...updatedMessages, assistantMessage];
      state = state.copyWith(
        messages: finalMessages,
        isLoading: false,
      );

    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<String> _buildContextString() async {
    final options = state.contextOptions;
    
    List<Task>? todaysTasks;
    List<Task>? yesterdaysTasks;
    List<FocusSession>? todaysFocusSessions;
    List<FocusSession>? last3DaysFocusSessions;
    List<LogEntry>? todaysLogEntries;
    List<LogEntry>? last3DaysLogEntries;
    List<LogEntry>? hashtaggedEntries;

    // Gather task data
    if (options.includeTodaysTasks) {
      final taskNotifier = _ref.read(taskProvider.notifier);
      todaysTasks = taskNotifier.state.when(
        data: (tasks) => tasks,
        loading: () => <Task>[],
        error: (_, __) => <Task>[],
      );
    }

    if (options.includeYesterdaysTasks) {
      try {
        yesterdaysTasks = await _ref.read(yesterdaysTasksProvider.future);
      } catch (_) {
        yesterdaysTasks = <Task>[];
      }
    }

    // Gather focus session data
    if (options.includeTodaysFocusSessions) {
      final focusSessionState = _ref.read(focusSessionProvider);
      todaysFocusSessions = focusSessionState.todaysSessions;
    }

    if (options.includeLast3DaysFocusSessions) {
      try {
        last3DaysFocusSessions = await _ref.read(lastNDaysFocusSessionsProvider(3).future);
      } catch (_) {
        last3DaysFocusSessions = <FocusSession>[];
      }
    }

    // Gather log entry data
    if (options.includeTodaysLogEntries) {
      try {
        todaysLogEntries = await _ref.read(todaysLogEntriesProvider.future);
      } catch (_) {
        todaysLogEntries = <LogEntry>[];
      }
    }

    if (options.includeLast3DaysLogEntries) {
      try {
        last3DaysLogEntries = await _ref.read(lastNDaysLogEntriesProvider(3).future);
      } catch (_) {
        last3DaysLogEntries = <LogEntry>[];
      }
    }

    // Gather hashtag-specific entries
    if (options.specificHashtag?.isNotEmpty == true) {
      try {
        hashtaggedEntries = await _ref.read(entriesWithHashtagProvider(options.specificHashtag!).future);
      } catch (_) {
        hashtaggedEntries = <LogEntry>[];
      }
    }

    // Get LLM service for building context
    final llmServiceAsync = await _ref.read(llmServiceProvider.future);
    if (llmServiceAsync == null) {
      return '';
    }

    return llmServiceAsync.buildContextString(
      todaysTasks: todaysTasks,
      yesterdaysTasks: yesterdaysTasks,
      todaysFocusSessions: todaysFocusSessions,
      last3DaysFocusSessions: last3DaysFocusSessions,
      todaysLogEntries: todaysLogEntries,
      last3DaysLogEntries: last3DaysLogEntries,
      hashtaggedEntries: hashtaggedEntries,
      specificHashtag: options.specificHashtag,
    );
  }

  Future<void> clearChatHistory() async {
    try {
      await _chatMessageDAO.deleteAllMessages();
      state = state.copyWith(messages: []);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> deleteMessage(ChatMessage message) async {
    try {
      if (message.id != null) {
        await _chatMessageDAO.delete(message.id!);
        await loadChatHistory(); // Reload to get updated list
      }
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for AI Coach state
final aiCoachProvider = StateNotifierProvider<AICoachNotifier, AICoachState>((ref) {
  final chatMessageDAO = ref.watch(chatMessageDAOProvider);
  return AICoachNotifier(chatMessageDAO, ref);
});

// Provider for getting unique hashtags for context selection
final availableHashtagsProvider = FutureProvider<List<String>>((ref) async {
  try {
    return await ref.read(uniqueHashtagsProvider.future);
  } catch (_) {
    return <String>[];
  }
}); 