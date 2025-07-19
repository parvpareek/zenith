import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/focus_session.dart';
import '../models/log_entry.dart';

class ContextOptions {
  final bool includeTodaysTasks;
  final bool includeYesterdaysTasks;
  final bool includeTodaysFocusSessions;
  final bool includeLast3DaysFocusSessions;
  final bool includeTodaysLogEntries;
  final bool includeLast3DaysLogEntries;
  final String? specificHashtag;

  const ContextOptions({
    this.includeTodaysTasks = false,
    this.includeYesterdaysTasks = false,
    this.includeTodaysFocusSessions = false,
    this.includeLast3DaysFocusSessions = false,
    this.includeTodaysLogEntries = false,
    this.includeLast3DaysLogEntries = false,
    this.specificHashtag,
  });

  ContextOptions copyWith({
    bool? includeTodaysTasks,
    bool? includeYesterdaysTasks,
    bool? includeTodaysFocusSessions,
    bool? includeLast3DaysFocusSessions,
    bool? includeTodaysLogEntries,
    bool? includeLast3DaysLogEntries,
    String? specificHashtag,
  }) {
    return ContextOptions(
      includeTodaysTasks: includeTodaysTasks ?? this.includeTodaysTasks,
      includeYesterdaysTasks: includeYesterdaysTasks ?? this.includeYesterdaysTasks,
      includeTodaysFocusSessions: includeTodaysFocusSessions ?? this.includeTodaysFocusSessions,
      includeLast3DaysFocusSessions: includeLast3DaysFocusSessions ?? this.includeLast3DaysFocusSessions,
      includeTodaysLogEntries: includeTodaysLogEntries ?? this.includeTodaysLogEntries,
      includeLast3DaysLogEntries: includeLast3DaysLogEntries ?? this.includeLast3DaysLogEntries,
      specificHashtag: specificHashtag ?? this.specificHashtag,
    );
  }

  bool get hasAnyContextSelected {
    return includeTodaysTasks ||
        includeYesterdaysTasks ||
        includeTodaysFocusSessions ||
        includeLast3DaysFocusSessions ||
        includeTodaysLogEntries ||
        includeLast3DaysLogEntries ||
        specificHashtag?.isNotEmpty == true;
  }
}

class LLMService {
  static const String _defaultApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  static const String _defaultModel = 'gemini-1.5-flash';
  
  final String apiUrl;
  final String apiKey;
  final String model;

  LLMService({
    this.apiUrl = _defaultApiUrl,
    required this.apiKey,
    this.model = _defaultModel,
  });

  String buildContextString({
    List<Task>? todaysTasks,
    List<Task>? yesterdaysTasks,
    List<FocusSession>? todaysFocusSessions,
    List<FocusSession>? last3DaysFocusSessions,
    List<LogEntry>? todaysLogEntries,
    List<LogEntry>? last3DaysLogEntries,
    List<LogEntry>? hashtaggedEntries,
    String? specificHashtag,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('CONTEXT:');
    buffer.writeln();

    // Tasks context
    if (todaysTasks?.isNotEmpty == true) {
      buffer.writeln('=== TODAY\'S TASKS ===');
      for (final task in todaysTasks!) {
        final status = task.isCompleted ? '[COMPLETED]' : '[PENDING]';
        buffer.writeln('$status ${task.description}');
      }
      buffer.writeln();
    }

    if (yesterdaysTasks?.isNotEmpty == true) {
      buffer.writeln('=== YESTERDAY\'S TASKS ===');
      for (final task in yesterdaysTasks!) {
        final status = task.isCompleted ? '[COMPLETED]' : '[PENDING]';
        buffer.writeln('$status ${task.description}');
      }
      buffer.writeln();
    }

    // Focus sessions context
    if (todaysFocusSessions?.isNotEmpty == true) {
      buffer.writeln('=== TODAY\'S FOCUS SESSIONS ===');
      for (final session in todaysFocusSessions!) {
        buffer.writeln('Goal: ${session.goal}');
        buffer.writeln('Duration: ${session.durationMinutes} minutes');
        if (session.summary?.isNotEmpty == true) {
          buffer.writeln('Summary: ${session.summary}');
        }
        buffer.writeln('---');
      }
      buffer.writeln();
    }

    if (last3DaysFocusSessions?.isNotEmpty == true) {
      buffer.writeln('=== LAST 3 DAYS\' FOCUS SESSIONS ===');
      for (final session in last3DaysFocusSessions!) {
        final date = session.timestamp.toString().split(' ')[0];
        buffer.writeln('Date: $date');
        buffer.writeln('Goal: ${session.goal}');
        buffer.writeln('Duration: ${session.durationMinutes} minutes');
        if (session.summary?.isNotEmpty == true) {
          buffer.writeln('Summary: ${session.summary}');
        }
        buffer.writeln('---');
      }
      buffer.writeln();
    }

    // Log entries context
    if (todaysLogEntries?.isNotEmpty == true) {
      buffer.writeln('=== TODAY\'S LOG ENTRIES ===');
      for (final entry in todaysLogEntries!) {
        final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
        buffer.writeln('[$time] ${entry.content}');
      }
      buffer.writeln();
    }

    if (last3DaysLogEntries?.isNotEmpty == true) {
      buffer.writeln('=== LAST 3 DAYS\' LOG ENTRIES ===');
      for (final entry in last3DaysLogEntries!) {
        final date = entry.timestamp.toString().split(' ')[0];
        final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
        buffer.writeln('[$date $time] ${entry.content}');
      }
      buffer.writeln();
    }

    if (hashtaggedEntries?.isNotEmpty == true && specificHashtag?.isNotEmpty == true) {
      buffer.writeln('=== ENTRIES WITH $specificHashtag ===');
      for (final entry in hashtaggedEntries!) {
        final date = entry.timestamp.toString().split(' ')[0];
        final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}';
        buffer.writeln('[$date $time] ${entry.content}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<String> sendMessage(String userMessage, {String? contextString}) async {
    try {
      // Build the prompt for Gemini
      final systemPrompt = '''You are a helpful AI coach for a productivity app called Zenith. Your role is to help users improve their productivity, reflect on their progress, and provide actionable insights based on their tasks, focus sessions, and journal entries.

Be encouraging, insightful, and practical in your responses. Help users see patterns in their behavior and suggest improvements. Keep responses concise but meaningful.

If context is provided, analyze it to give personalized advice. If no context is provided, give general productivity guidance.''';

      String fullPrompt = systemPrompt + '\n\n';
      
      if (contextString?.isNotEmpty == true) {
        fullPrompt += contextString! + '\n\n';
      }
      
      fullPrompt += 'User: $userMessage\n\nAssistant:';

      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': fullPrompt,
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 500,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        
        if (candidates?.isNotEmpty == true) {
          final content = candidates!.first['content'];
          final parts = content['parts'] as List?;
          
          if (parts?.isNotEmpty == true) {
            return parts!.first['text']?.toString().trim() ?? 'No response received.';
          }
        }
        
        return 'No response received from Gemini.';
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? response.reasonPhrase;
        return 'Error: ${response.statusCode} - $errorMessage';
      }
    } catch (e) {
      return 'Error: Failed to send message. Please check your internet connection and API key, then try again.';
    }
  }
} 