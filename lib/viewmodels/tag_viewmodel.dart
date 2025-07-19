import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import '../database/tag_dao.dart';
import 'providers.dart';

class TagState {
  final List<Tag> hierarchicalTags;
  final List<Tag> mostUsedTags;
  final List<Tag> searchResults;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const TagState({
    this.hierarchicalTags = const [],
    this.mostUsedTags = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  TagState copyWith({
    List<Tag>? hierarchicalTags,
    List<Tag>? mostUsedTags,
    List<Tag>? searchResults,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return TagState(
      hierarchicalTags: hierarchicalTags ?? this.hierarchicalTags,
      mostUsedTags: mostUsedTags ?? this.mostUsedTags,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TagNotifier extends StateNotifier<TagState> {
  final TagDAO _tagDAO;

  TagNotifier(this._tagDAO) : super(const TagState()) {
    loadHierarchicalTags();
    loadMostUsedTags();
  }

  // Load hierarchical tags (categories with children)
  Future<void> loadHierarchicalTags() async {
    try {
      state = state.copyWith(isLoading: true);
      final tags = await _tagDAO.getHierarchicalTags();
      state = state.copyWith(
        hierarchicalTags: tags,
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

  // Load most used tags for quick access
  Future<void> loadMostUsedTags() async {
    try {
      final tags = await _tagDAO.getMostUsedTags();
      state = state.copyWith(mostUsedTags: tags);
    } catch (error) {
      // Ignore errors for most used tags
    }
  }

  // Search tags
  Future<void> searchTags(String query) async {
    try {
      state = state.copyWith(searchQuery: query);
      
      if (query.trim().isEmpty) {
        state = state.copyWith(searchResults: []);
        return;
      }
      
      final results = await _tagDAO.searchTags(query);
      state = state.copyWith(searchResults: results);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // Create a new tag
  Future<Tag?> createTag({
    required String name,
    int? parentId,
    required String color,
  }) async {
    try {
      final tag = Tag(
        name: name,
        parentId: parentId,
        color: color,
        createdAt: DateTime.now(),
      );
      
      final id = await _tagDAO.insert(tag);
      final newTag = tag.copyWith(id: id);
      
      // Reload hierarchical tags to include the new tag
      await loadHierarchicalTags();
      
      return newTag;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    }
  }

  // Update a tag
  Future<bool> updateTag(Tag tag) async {
    try {
      await _tagDAO.update(tag);
      await loadHierarchicalTags();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  // Delete a tag
  Future<bool> deleteTag(int tagId) async {
    try {
      await _tagDAO.delete(tagId);
      await loadHierarchicalTags();
      return true;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return false;
    }
  }

  // Get tag by ID
  Future<Tag?> getTagById(int id) async {
    try {
      return await _tagDAO.getTagById(id);
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    }
  }

  // Get children of a tag
  Future<List<Tag>> getChildrenOfTag(int parentId) async {
    try {
      return await _tagDAO.getChildrenOfTag(parentId);
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return [];
    }
  }

  // Get root categories
  Future<List<Tag>> getRootCategories() async {
    try {
      return await _tagDAO.getRootCategories();
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return [];
    }
  }

  // Clear search results
  void clearSearch() {
    state = state.copyWith(searchQuery: '', searchResults: []);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get all tags flat list
  List<Tag> get allTagsFlat {
    List<Tag> allTags = [];
    for (final rootTag in state.hierarchicalTags) {
      allTags.add(rootTag);
      if (rootTag.children != null) {
        allTags.addAll(rootTag.children!);
      }
    }
    return allTags;
  }

  // Get suggestions based on search query
  List<Tag> getSuggestions(String query) {
    if (query.trim().isEmpty) {
      return state.mostUsedTags;
    }
    
    final allTags = allTagsFlat;
    return allTags.where((tag) => 
      tag.name.toLowerCase().contains(query.toLowerCase())
    ).take(10).toList();
  }
}

// Provider for tag state
final tagProvider = StateNotifierProvider<TagNotifier, TagState>((ref) {
  final tagDAO = ref.watch(tagDAOProvider);
  return TagNotifier(tagDAO);
});

// Provider for tag analytics
final tagAnalyticsProvider = FutureProvider.family<List<TagAnalytics>, DateRange?>((ref, dateRange) async {
  final tagDAO = ref.watch(tagDAOProvider);
  return await tagDAO.getTagAnalytics(
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});

class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}