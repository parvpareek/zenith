import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import '../viewmodels/tag_viewmodel.dart';
import '../config/app_theme.dart';

class TagSelector extends ConsumerStatefulWidget {
  final List<Tag> selectedTags;
  final Function(List<Tag>) onTagsChanged;
  final bool showCreateButton;
  final String? hintText;

  const TagSelector({
    Key? key,
    required this.selectedTags,
    required this.onTagsChanged,
    this.showCreateButton = false,
    this.hintText,
  }) : super(key: key);

  @override
  ConsumerState<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends ConsumerState<TagSelector> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Search tags...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                        size: 20,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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

        const SizedBox(height: 16),

        // Create Tag Button
        if (widget.showCreateButton) ...[
          SizedBox(
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
          const SizedBox(height: 16),
        ],

        // Selected tags display
        if (widget.selectedTags.isNotEmpty) ...[
          Text(
            'Selected Tags',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildSelectedTags(),
          const SizedBox(height: 16),
        ],

        // Tag list
        Expanded(
          child: _isSearching
              ? _buildSearchResults(tagState)
              : _buildHierarchicalTags(tagState),
        ),
      ],
    );
  }

  Widget _buildSelectedTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.selectedTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(int.parse(tag.color.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _removeTag(tag),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
            if (widget.showCreateButton) ...[
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
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tagState.searchResults.length,
      itemBuilder: (context, index) {
        final tag = tagState.searchResults[index];
        return _buildTagTile(tag);
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
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          if (rootTag.children != null && rootTag.children!.isNotEmpty)
            ...rootTag.children!.map((child) => _buildTagTile(child)).toList(),
        ],
      ),
    );
  }

  Widget _buildTagTile(Tag tag) {
    final isSelected = widget.selectedTags.any((t) => t.id == tag.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: const Color(0xFF3478F4),
                size: 20,
              )
            : Icon(
                Icons.circle_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
        onTap: () {
          if (isSelected) {
            _removeTag(tag);
          } else {
            _addTag(tag);
          }
        },
        tileColor: isSelected
            ? const Color(0xFF3478F4).withOpacity(0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _addTag(Tag tag) {
    final updatedTags = [...widget.selectedTags, tag];
    widget.onTagsChanged(updatedTags);
  }

  void _removeTag(Tag tag) {
    final updatedTags = widget.selectedTags.where((t) => t.id != tag.id).toList();
    widget.onTagsChanged(updatedTags);
  }

  void _showCreateTagDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTagDialog(
        onTagCreated: (tag) {
          if (tag != null) {
            _addTag(tag);
          }
        },
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
    final tagNotifier = ref.read(tagProvider.notifier);

    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Tag',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Name field
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
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
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
            ),
          ],
        ),
      ),
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