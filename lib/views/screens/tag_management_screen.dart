import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tag.dart';
import '../../viewmodels/tag_viewmodel.dart';
import '../../config/app_theme.dart';

class TagManagementScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends ConsumerState<TagManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagState = ref.watch(tagProvider);
    final tagNotifier = ref.read(tagProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Manage Tags'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showCreateTagDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Create Tag',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tags...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                          });
                          tagNotifier.clearSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
                tagNotifier.searchTags(value);
              },
            ),
          ),

          // Create Tag Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateTagDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create New Tag'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3478F4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Tags List
          Expanded(
            child: _isSearching
                ? _buildSearchResults(tagState)
                : _buildHierarchicalTags(tagState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(TagState tagState) {
    if (tagState.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No tags found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _showCreateTagDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Tag'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3478F4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tagState.searchResults.length,
      itemBuilder: (context, index) {
        final tag = tagState.searchResults[index];
        return _buildTagManagementTile(tag);
      },
    );
  }

  Widget _buildHierarchicalTags(TagState tagState) {
    if (tagState.hierarchicalTags.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3478F4),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tagState.hierarchicalTags.length,
      itemBuilder: (context, index) {
        final rootTag = tagState.hierarchicalTags[index];
        return _buildCategoryExpansionTile(rootTag);
      },
    );
  }

  Widget _buildCategoryExpansionTile(Tag rootTag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(int.parse(rootTag.color.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          rootTag.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showEditTagDialog(rootTag),
              icon: const Icon(Icons.edit, size: 18),
              color: AppColors.textSecondary,
            ),
            IconButton(
              onPressed: () => _showDeleteConfirmation(rootTag),
              icon: const Icon(Icons.delete, size: 18),
              color: Colors.red,
            ),
            const Icon(Icons.expand_more, color: AppColors.textSecondary),
          ],
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          if (rootTag.children != null && rootTag.children!.isNotEmpty)
            ...rootTag.children!.map((child) => _buildTagManagementTile(child)).toList(),
        ],
      ),
    );
  }

  Widget _buildTagManagementTile(Tag tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          tag.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showEditTagDialog(tag),
              icon: const Icon(Icons.edit, size: 16),
              color: AppColors.textSecondary,
            ),
            IconButton(
              onPressed: () => _showDeleteConfirmation(tag),
              icon: const Icon(Icons.delete, size: 16),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTagDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTagDialog(
        onTagCreated: (tag) {
          if (tag != null) {
            // Refresh the tag list
            ref.read(tagProvider.notifier).loadHierarchicalTags();
          }
        },
      ),
    );
  }

  void _showEditTagDialog(Tag tag) {
    showDialog(
      context: context,
      builder: (context) => EditTagDialog(
        tag: tag,
        onTagUpdated: (updatedTag) {
          if (updatedTag != null) {
            // Refresh the tag list
            ref.read(tagProvider.notifier).loadHierarchicalTags();
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(Tag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Delete Tag',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${tag.name}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(tagProvider.notifier).deleteTag(tag.id!);
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

class CreateTagDialog extends ConsumerStatefulWidget {
  final Function(Tag?) onTagCreated;

  const CreateTagDialog({
    Key? key,
    required this.onTagCreated,
  }) : super(key: key);

  @override
  ConsumerState<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends ConsumerState<CreateTagDialog> {
  final _nameController = TextEditingController();
  Tag? _selectedParent;
  String _selectedColor = '#3478F4';
  bool _isLoading = false;

  final List<String> _colors = [
    '#3478F4', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FFEAA7', '#DDA0DD', '#F39C12', '#E74C3C', '#9B59B6',
    '#1ABC9C', '#2ECC71', '#3498DB', '#34495E', '#95A5A6',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagState = ref.watch(tagProvider);

    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      title: Text(
        'Create New Tag',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag name
            Text(
              'Tag Name',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter tag name',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            
            const SizedBox(height: 20),
            
            // Parent category
            Text(
              'Category (Optional)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Tag?>(
              value: _selectedParent,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: AppColors.darkSurface,
              items: [
                DropdownMenuItem<Tag?>(
                  value: null,
                  child: Text(
                    'No category (root level)',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ...tagState.hierarchicalTags.map((tag) {
                  return DropdownMenuItem<Tag?>(
                    value: tag,
                    child: Text(
                      tag.name,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedParent = value;
                });
              },
            ),
            
            const SizedBox(height: 20),
            
            // Color selection
            Text(
              'Color',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createTag,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3478F4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createTag() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final tagNotifier = ref.read(tagProvider.notifier);
    final newTag = await tagNotifier.createTag(
      name: _nameController.text.trim(),
      parentId: _selectedParent?.id,
      color: _selectedColor,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onTagCreated(newTag);
    }
  }
}

class EditTagDialog extends ConsumerStatefulWidget {
  final Tag tag;
  final Function(Tag?) onTagUpdated;

  const EditTagDialog({
    Key? key,
    required this.tag,
    required this.onTagUpdated,
  }) : super(key: key);

  @override
  ConsumerState<EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends ConsumerState<EditTagDialog> {
  late TextEditingController _nameController;
  Tag? _selectedParent;
  late String _selectedColor;
  bool _isLoading = false;

  final List<String> _colors = [
    '#3478F4', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FFEAA7', '#DDA0DD', '#F39C12', '#E74C3C', '#9B59B6',
    '#1ABC9C', '#2ECC71', '#3498DB', '#34495E', '#95A5A6',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag.name);
    _selectedColor = widget.tag.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagState = ref.watch(tagProvider);

    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      title: Text(
        'Edit Tag',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag name
            Text(
              'Tag Name',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter tag name',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            
            const SizedBox(height: 20),
            
            // Color selection
            Text(
              'Color',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateTag,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3478F4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateTag() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final tagNotifier = ref.read(tagProvider.notifier);
    
    // Create updated tag object
    final updatedTag = widget.tag.copyWith(
      name: _nameController.text.trim(),
      color: _selectedColor,
    );
    
    final success = await tagNotifier.updateTag(updatedTag);

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onTagUpdated(success ? updatedTag : null);
    }
  }
} 