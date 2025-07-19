import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/chat_message.dart';
import '../../models/focus_session.dart';
import '../../models/log_entry.dart';
import '../../viewmodels/ai_coach_viewmodel.dart';
import '../../viewmodels/focus_session_viewmodel.dart';
import '../../viewmodels/log_entry_viewmodel.dart';
import '../../viewmodels/providers.dart';
import '../../services/preferences_service.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _showContextPanel = false;
  bool _showApiKeyInput = false;
  bool _isObscureApiKey = true;
  
  // Context selection state
  DateTimeRange? _selectedDateRange;
  Set<String> _selectedNotes = {};
  Set<String> _selectedReflections = {};
  List<FocusSession> _availableSessions = [];
  List<LogEntry> _availableLogEntries = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      ref.read(aiCoachProvider.notifier).sendMessage(_messageController.text.trim());
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      await PreferencesService.instance.setGeminiApiKey(apiKey);
      ref.invalidate(apiKeyConfiguredProvider);
      ref.invalidate(llmServiceProvider);
      setState(() {
        _showApiKeyInput = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearApiKey() async {
    await PreferencesService.instance.clearGeminiApiKey();
    _apiKeyController.clear();
    ref.invalidate(apiKeyConfiguredProvider);
    ref.invalidate(llmServiceProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key cleared.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadContextData() async {
    final focusSessionState = ref.read(focusSessionProvider);
    final logEntryState = ref.read(logEntryProvider);
    
    // Load sessions from last 30 days
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    
    setState(() {
      _availableSessions = focusSessionState.todaysSessions;
      _availableLogEntries = logEntryState.when(
        data: (entries) => entries.where((entry) => 
          entry.timestamp.isAfter(startDate) && entry.timestamp.isBefore(endDate)
        ).toList(),
        loading: () => [],
        error: (_, __) => [],
      );
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF3478F4),
              onPrimary: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      await _loadContextData();
    }
  }

  void _toggleContextPanel() {
    setState(() {
      _showContextPanel = !_showContextPanel;
    });
    if (_showContextPanel) {
      _loadContextData();
    }
  }

  String _getContextSummary() {
    int contextCount = 0;
    if (_selectedDateRange != null) contextCount++;
    if (_selectedNotes.isNotEmpty) contextCount += _selectedNotes.length;
    if (_selectedReflections.isNotEmpty) contextCount += _selectedReflections.length;
    
    return contextCount > 0 ? '$contextCount items selected' : 'No context selected';
  }

  @override
  Widget build(BuildContext context) {
    final aiCoachState = ref.watch(aiCoachProvider);
    final apiKeyConfigured = ref.watch(apiKeyConfiguredProvider);
    final messages = aiCoachState.messages;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and context/settings button
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'AI Coach',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Settings/API Key button
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showApiKeyInput = !_showApiKeyInput;
                        _showContextPanel = false;
                      });
                    },
                    icon: Icon(
                      Icons.settings,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  // Context button
                  IconButton(
                    onPressed: _toggleContextPanel,
                    icon: Icon(
                      _showContextPanel ? Icons.close : Icons.add_circle_outline,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // API Key Configuration Panel
            if (_showApiKeyInput)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  border: Border(bottom: BorderSide(color: AppColors.textSecondary.withOpacity(0.2))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini API Key Configuration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Get your free API key from Google AI Studio: https://makersuite.google.com/app/apikey',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // API Key Input Field
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _isObscureApiKey,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter your Gemini API key',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.darkBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isObscureApiKey = !_isObscureApiKey;
                                });
                              },
                              icon: Icon(
                                _isObscureApiKey ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            IconButton(
                              onPressed: _saveApiKey,
                              icon: const Icon(
                                Icons.save,
                                color: Color(0xFF3478F4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Status and Clear Button
                    Row(
                      children: [
                        Expanded(
                          child: apiKeyConfigured.when(
                            data: (isConfigured) => Text(
                              isConfigured ? '✓ API Key configured' : '⚠ No API Key configured',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isConfigured ? Colors.green : Colors.orange,
                              ),
                            ),
                            loading: () => const Text('Checking...', style: TextStyle(color: AppColors.textSecondary)),
                            error: (_, __) => const Text('Error checking API key', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearApiKey,
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          
          // Context selection panel
          if (_showContextPanel)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(bottom: BorderSide(color: AppColors.textSecondary.withOpacity(0.2))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Context for AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date range selection
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(_selectedDateRange == null 
                            ? 'Select Date Range' 
                            : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedDateRange != null ? const Color(0xFF3478F4) : AppColors.darkBackground,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedDateRange = null;
                            });
                          },
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Notes selection
                  if (_availableLogEntries.isNotEmpty) ...[
                    Text(
                      'Select Notes:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        itemCount: _availableLogEntries.length,
                        itemBuilder: (context, index) {
                          final entry = _availableLogEntries[index];
                          final isSelected = _selectedNotes.contains(entry.id.toString());
                          
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedNotes.add(entry.id.toString());
                                } else {
                                  _selectedNotes.remove(entry.id.toString());
                                }
                              });
                            },
                            title: Text(
                              entry.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('MMM d, yyyy').format(entry.timestamp),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: const Color(0xFF3478F4),
                            checkColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Reflections selection
                  if (_availableSessions.isNotEmpty) ...[
                    Text(
                      'Select Reflections:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        itemCount: _availableSessions.length,
                        itemBuilder: (context, index) {
                          final session = _availableSessions[index];
                          final hasReflection = session.summary != null || session.learningSummary != null;
                          
                          if (!hasReflection) return const SizedBox.shrink();
                          
                          final isSelected = _selectedReflections.contains(session.id.toString());
                          
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedReflections.add(session.id.toString());
                                } else {
                                  _selectedReflections.remove(session.id.toString());
                                }
                              });
                            },
                            title: Text(
                              session.goal,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('MMM d, yyyy').format(session.timestamp),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            activeColor: const Color(0xFF3478F4),
                            checkColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Context summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          _getContextSummary(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Start a conversation with your AI Coach',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to add context from your notes and reflections',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: aiCoachState.isLoading 
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3478F4)),
                              ),
                            ),
                          )
                        : null,
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                    enabled: !aiCoachState.isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed: aiCoachState.isLoading ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlack,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // AI message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zenith AI',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message.content,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // User message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'You',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
          Container(
                    padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                      color: AppColors.accentBlack,
                      borderRadius: BorderRadius.circular(8),
            ),
                    child: Text(
                      message.content,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // User avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 