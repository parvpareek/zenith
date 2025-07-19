import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_entry.dart';
import '../database/log_entry_dao.dart';
import 'providers.dart';

// State notifier for log entries
class LogEntryNotifier extends StateNotifier<AsyncValue<List<LogEntry>>> {
  final LogEntryDAO _logEntryDAO;

  LogEntryNotifier(this._logEntryDAO) : super(const AsyncValue.loading()) {
    loadAllEntries();
  }

  Future<void> loadAllEntries() async {
    try {
      state = const AsyncValue.loading();
      final entries = await _logEntryDAO.getAllEntries();
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadEntriesByCategory(LogEntryCategory category) async {
    try {
      state = const AsyncValue.loading();
      final entries = await _logEntryDAO.getEntriesByCategory(category);
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addEntry(String title, String content, LogEntryCategory category) async {
    if (content.trim().isEmpty) return;

    try {
      final entry = LogEntry(
        title: title.trim(),
        content: content.trim(),
        category: category,
        timestamp: DateTime.now(),
      );
      
      await _logEntryDAO.insert(entry);
      await loadAllEntries(); // Reload to get updated list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateEntry(LogEntry entry, String newTitle, String newContent, LogEntryCategory newCategory) async {
    if (newContent.trim().isEmpty) return;

    try {
      final updatedEntry = entry.copyWith(
        title: newTitle.trim(),
        content: newContent.trim(),
        category: newCategory,
      );
      await _logEntryDAO.update(updatedEntry);
      await loadAllEntries(); // Reload to get updated list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteEntry(LogEntry entry) async {
    try {
      if (entry.id != null) {
        await _logEntryDAO.delete(entry.id!);
        await loadAllEntries(); // Reload to get updated list
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchEntries(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      await loadAllEntries();
      return;
    }

    try {
      state = const AsyncValue.loading();
      final entries = await _logEntryDAO.searchEntries(searchTerm.trim());
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchEntriesByCategory(String searchTerm, LogEntryCategory category) async {
    if (searchTerm.trim().isEmpty) {
      await loadEntriesByCategory(category);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final entries = await _logEntryDAO.searchEntriesByCategory(searchTerm.trim(), category);
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> filterByHashtag(String hashtag) async {
    try {
      state = const AsyncValue.loading();
      final entries = await _logEntryDAO.getEntriesWithHashtag(hashtag);
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<LogEntry> get todaysEntries {
    return state.when(
      data: (entries) {
        final today = DateTime.now();
        return entries.where((entry) => 
          entry.timestamp.year == today.year &&
          entry.timestamp.month == today.month &&
          entry.timestamp.day == today.day
        ).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  int get totalEntries => state.when(
    data: (entries) => entries.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
}

// Provider for log entry state
final logEntryProvider = StateNotifierProvider<LogEntryNotifier, AsyncValue<List<LogEntry>>>((ref) {
  final logEntryDAO = ref.watch(logEntryDAOProvider);
  return LogEntryNotifier(logEntryDAO);
});

// Provider for selected category filter
final selectedCategoryProvider = StateProvider<LogEntryCategory?>((ref) => null);

// Provider for getting today's entries (for AI Coach context)
final todaysLogEntriesProvider = FutureProvider<List<LogEntry>>((ref) async {
  final logEntryDAO = ref.watch(logEntryDAOProvider);
  return await logEntryDAO.getTodaysEntries();
});

// Provider for getting last N days entries (for AI Coach context)
final lastNDaysLogEntriesProvider = FutureProvider.family<List<LogEntry>, int>((ref, days) async {
  final logEntryDAO = ref.watch(logEntryDAOProvider);
  return await logEntryDAO.getLastNDaysEntries(days);
});

// Provider for getting entries with specific hashtag (for AI Coach context)
final entriesWithHashtagProvider = FutureProvider.family<List<LogEntry>, String>((ref, hashtag) async {
  final logEntryDAO = ref.watch(logEntryDAOProvider);
  return await logEntryDAO.getEntriesWithHashtag(hashtag);
});

// Provider for getting unique hashtags
final uniqueHashtagsProvider = FutureProvider<List<String>>((ref) async {
  final logEntryDAO = ref.watch(logEntryDAOProvider);
  return await logEntryDAO.getUniqueHashtags();
});

// Provider for search functionality
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider for filtered entries based on search and category
final filteredLogEntriesProvider = Provider<AsyncValue<List<LogEntry>>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final allEntries = ref.watch(logEntryProvider);
  
  return allEntries.when(
    data: (entries) {
      var filtered = entries;
      
      // Filter by category if selected
      if (selectedCategory != null) {
        filtered = filtered.where((entry) => entry.category == selectedCategory).toList();
      }
      
      // Filter by search query if provided
      if (searchQuery.trim().isNotEmpty) {
        filtered = filtered.where((entry) => 
        entry.containsText(searchQuery) || 
        entry.hashtags.any((hashtag) => hashtag.toLowerCase().contains(searchQuery.toLowerCase()))
      ).toList();
      }
      
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

// Provider for entries by category
final entriesByCategoryProvider = FutureProvider.family<List<LogEntry>, LogEntryCategory>((ref, category) async {
  final logEntryDAO = ref.watch(logEntryDAOProvider);
  return await logEntryDAO.getEntriesByCategory(category);
}); 