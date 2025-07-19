import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../config/app_theme.dart';
import '../../models/log_entry.dart';
import '../../viewmodels/log_entry_viewmodel.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCategorySelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Text(
              'Choose Entry Type',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
          ),
            
            const SizedBox(height: 24),
            
            // Daily Log option
            _buildCategoryOption(
              icon: Icons.today,
              title: 'Daily Log',
              description: 'Record your daily thoughts and activities',
              category: LogEntryCategory.dailyLog,
              onTap: () {
                Navigator.pop(context);
                _showEntryCreationScreen(LogEntryCategory.dailyLog);
              },
          ),
            
            const SizedBox(height: 16),
            
            // Strategy/Notes option
            _buildCategoryOption(
              icon: Icons.lightbulb_outline,
              title: 'Strategy & Notes',
              description: 'Plan strategies and capture important insights',
              category: LogEntryCategory.strategy,
              onTap: () {
                Navigator.pop(context);
                _showEntryCreationScreen(LogEntryCategory.strategy);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption({
    required IconData icon,
    required String title,
    required String description,
    required LogEntryCategory category,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.darkBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                      ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryCreationScreen(LogEntryCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EntryCreationScreen(category: category),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(filteredLogEntriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Daily Log',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search entries or #tags',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                onChanged: (query) {
                  ref.read(searchQueryProvider.notifier).state = query;
                },
              ),
            ),
            
            // Filter chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All',
                    isSelected: selectedCategory == null,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Daily Log',
                    isSelected: selectedCategory == LogEntryCategory.dailyLog,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = LogEntryCategory.dailyLog;
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Strategy',
                    isSelected: selectedCategory == LogEntryCategory.strategy,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = LogEntryCategory.strategy;
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Entries list
            Expanded(
              child: entriesAsync.when(
                data: (entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                          Icons.note_add,
              size: 64,
                          color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
                          selectedCategory == null 
                            ? 'No entries yet'
                            : 'No ${selectedCategory!.displayName.toLowerCase()} entries yet',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                          'Tap the + button to create your first entry',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
                    return _buildEntryCard(entry);
      },
    );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCategorySelectionModal,
        backgroundColor: AppColors.lightGrey,
        child: const Icon(
          Icons.add,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightGrey : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(LogEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EntryEditScreen(entry: entry),
              ),
            );
          },
          child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Entry header with date, category, and actions
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                child: Row(
                  children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                    child: Text(
                                entry.category.displayName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM dd, yyyy').format(entry.timestamp),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
              Row(
                          children: [
                  Text(
                    DateFormat('HH:mm').format(entry.timestamp),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteConfirmDialog(entry),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
                
              const SizedBox(height: 12),
                
                // Entry title (if not empty)
                if (entry.title.isNotEmpty) ...[
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Entry content (markdown rendered)
                SizedBox(
                  height: 200, // Constrain height to prevent overflow
                  child: Markdown(
                    data: entry.content,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                      h1: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      strong: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      em: const TextStyle(
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                      code: const TextStyle(
                        color: AppColors.textPrimary,
                        backgroundColor: AppColors.darkBackground,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      a: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                    ),
                  ),
                  ),
              ),
                
                // Tags (if any)
                if (entry.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                Wrap(
                    spacing: 8,
                  runSpacing: 4,
                    children: entry.hashtags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                            fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(LogEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(logEntryProvider.notifier).deleteEntry(entry);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry deleted'),
                  backgroundColor: AppColors.darkSurface,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// Entry Creation Screen
class EntryCreationScreen extends ConsumerStatefulWidget {
  final LogEntryCategory category;

  const EntryCreationScreen({Key? key, required this.category}) : super(key: key);

  @override
  ConsumerState<EntryCreationScreen> createState() => _EntryCreationScreenState();
}

class _EntryCreationScreenState extends ConsumerState<EntryCreationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    // Populate title with today's date by default
    _titleController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    // Auto-focus on title field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _saveEntry() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(logEntryProvider.notifier).addEntry(
      _titleController.text.trim(),
      _contentController.text.trim(),
      widget.category,
    );

    Navigator.of(context).pop();
  }

  Widget _buildEditMode() {
    return TextField(
      controller: _contentController,
      focusNode: _contentFocusNode,
      decoration: const InputDecoration(
        hintText: 'What\'s on your mind?',
        border: InputBorder.none,
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: EdgeInsets.all(16),
      ),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
    );
  }

  Widget _buildPreviewMode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_titleController.text.trim().isNotEmpty) ...[
            Text(
              _titleController.text.trim(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: _contentController.text.trim().isEmpty
                ? const Center(
                    child: Text(
                      'No content to preview yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : Markdown(
                    data: _contentController.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      h1: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      strong: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      em: const TextStyle(
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                      code: const TextStyle(
                        color: AppColors.textPrimary,
                        backgroundColor: AppColors.darkBackground,
                        fontFamily: 'monospace',
                      ),
                      a: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'New ${widget.category.displayName}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPreviewMode ? Icons.edit : Icons.preview,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
          ),
          TextButton(
            onPressed: _saveEntry,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: const InputDecoration(
                hintText: 'Enter a heading (e.g., 15/07/2025)',
                border: InputBorder.none,
                filled: true,
                fillColor: AppColors.darkSurface,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _contentFocusNode.requestFocus(),
            ),
            
            const SizedBox(height: 12),
            
            // Content field or preview
            Expanded(
              child: _isPreviewMode ? _buildPreviewMode() : _buildEditMode(),
            ),
            
            const SizedBox(height: 16),
            
            // Helper text
            Text(
              _isPreviewMode 
                ? 'Preview mode - tap the edit icon to continue editing'
                : 'Supports **bold**, *italic*, #tags, and [links](url). Use preview to see formatting.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Entry Edit Screen
class EntryEditScreen extends ConsumerStatefulWidget {
  final LogEntry entry;

  const EntryEditScreen({Key? key, required this.entry}) : super(key: key);

  @override
  ConsumerState<EntryEditScreen> createState() => _EntryEditScreenState();
}

class _EntryEditScreenState extends ConsumerState<EntryEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing entry data
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    
    // Auto-focus on title field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _updateEntry() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some content'),
          backgroundColor: AppColors.darkSurface,
        ),
      );
      return;
    }

    ref.read(logEntryProvider.notifier).updateEntry(
      widget.entry,
      _titleController.text.trim(),
      _contentController.text.trim(),
      widget.entry.category,
    );
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry updated successfully'),
        backgroundColor: AppColors.darkSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Entry',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              _isPreviewMode ? 'Edit' : 'Preview',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
          ),
          TextButton(
            onPressed: _updateEntry,
            child: const Text(
              'Update',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: const InputDecoration(
                hintText: 'Enter a heading (e.g., 15/07/2025)',
                border: InputBorder.none,
                filled: true,
                fillColor: AppColors.darkSurface,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content area
            Expanded(
              child: _isPreviewMode 
                ? _buildPreviewMode()
                : _buildEditMode(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    return TextField(
      controller: _contentController,
      focusNode: _contentFocusNode,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: const InputDecoration(
        hintText: 'Write your thoughts, experiences, or strategies...\n\nYou can use:\n**bold text**\n*italic text*\n#hashtags\n[links](https://example.com)',
        border: InputBorder.none,
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: EdgeInsets.all(16),
      ),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
    );
  }

  Widget _buildPreviewMode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Markdown(
              data: _contentController.text.isEmpty ? '*No content*' : _contentController.text,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.5,
                ),
                h1: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                h2: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                h3: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                strong: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                em: const TextStyle(
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
                code: const TextStyle(
                  color: AppColors.textPrimary,
                  backgroundColor: AppColors.darkBackground,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                a: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap "Edit" to continue editing, or "Update" to save changes.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 