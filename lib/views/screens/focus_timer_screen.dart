import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../config/app_theme.dart';
import '../../models/focus_session.dart';
import '../../models/tag.dart';
import '../../viewmodels/focus_session_viewmodel.dart';
import '../../widgets/tag_selector.dart';
import 'tag_management_screen.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen> 
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Early exit screen state
  String? _selectedExitReason;
  final _exitReasonController = TextEditingController();
  SessionStep? _previousStep;

  // Reflection text controllers - moved out of StatefulBuilder to prevent recreation
  final TextEditingController _learningController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _learningSummaryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _exitReasonController.dispose();
    _learningController.dispose();
    _reflectionController.dispose();
    _learningSummaryController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(focusSessionProvider);
    final viewModel = ref.read(focusSessionProvider.notifier);

    // Manage full screen mode
    _manageFullScreenMode(sessionState);

    // Start pulse animation when timer is running
    if (sessionState.timerState == TimerState.running) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }

    return WillPopScope(
      onWillPop: () async {
        // Prevent leaving app during active session
        if (sessionState.isAppLocked) {
          _showExitDialog(context, viewModel);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: _buildContent(context, sessionState, viewModel),
      ),
    );
  }

  void _manageFullScreenMode(FocusSessionState sessionState) {
    if (sessionState.currentStep == SessionStep.active) {
      // Enter full screen (hide status bar and navigation)
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    } else {
      // Exit full screen (show status bar and navigation)
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  Widget _buildContent(
    BuildContext context,
    FocusSessionState sessionState,
    FocusSessionNotifier viewModel,
  ) {
    // Reset early exit state when first entering the early exit screen
    if (_previousStep != SessionStep.earlyExit && sessionState.currentStep == SessionStep.earlyExit) {
      _selectedExitReason = null;
      _exitReasonController.clear();
    }
    _previousStep = sessionState.currentStep;

    switch (sessionState.currentStep) {
      case SessionStep.modeSelection:
        return _buildModeSelection(context, sessionState, viewModel);
      case SessionStep.planning:
        return _buildPlanningScreen(context, sessionState, viewModel);
      case SessionStep.checklist:
        return _buildChecklistScreen(context, sessionState, viewModel);
      case SessionStep.active:
        return _buildActiveSession(context, sessionState, viewModel);
      case SessionStep.earlyExit:
        return _buildEarlyExitScreen(context, sessionState, viewModel);
      case SessionStep.reflection:
        return _buildReflectionScreen(context, sessionState, viewModel);
      case SessionStep.completed:
        return _buildCompletedScreen(context, sessionState, viewModel);
    }
  }

  Widget _buildModeSelection(
    BuildContext context,
    FocusSessionState sessionState,
    FocusSessionNotifier viewModel,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Focus Timer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => _showSettingsDialog(context, viewModel),
                  icon: const Icon(
                    Icons.settings,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Mode selection cards
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      'Choose Your Focus Mode',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Pomodoro Mode
                    _buildModeCard(
                      context,
                      SessionMode.pomodoro,
                      Icons.timer,
                      Colors.orange,
                      () => viewModel.selectMode(SessionMode.pomodoro),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Flowmodoro Mode
                    _buildModeCard(
                      context,
                      SessionMode.flowmodoro,
                      Icons.waves,
                      Colors.blue,
                      () => viewModel.selectMode(SessionMode.flowmodoro),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Today's stats
                    _buildTodayStats(context, sessionState),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, FocusSessionNotifier viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Exit Focus Session?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to exit the focus session? This will end your current session.',
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
            onPressed: () {
              Navigator.of(context).pop();
              viewModel.requestEarlyExit();
            },
            child: Text(
              'Exit',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    SessionMode mode,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: AppColors.darkSurface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
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

  Widget _buildTodayStats(BuildContext context, FocusSessionState sessionState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            '${sessionState.todaysSessions.length}',
            'Sessions',
            Icons.play_circle_outline,
          ),
          _buildStatItem(
            context,
            '${sessionState.totalFocusTimeToday}m',
            'Total Time',
            Icons.timer_outlined,
          ),
          _buildStatItem(
            context,
            '${sessionState.todaysSessions.where((s) => s.phase == SessionPhase.completed).length}',
            'Completed',
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanningScreen(
    BuildContext context,
    FocusSessionState sessionState,
    FocusSessionNotifier viewModel,
  ) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => viewModel.resetToModeSelection(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Plan Your Session',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode and Duration
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sessionState.selectedMode.displayName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${sessionState.totalMinutes} minutes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Goal Input
                    Text(
                      'What will you accomplish?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'e.g., Complete chapter 3 of the textbook',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                      onChanged: viewModel.setGoal,
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Detailed Plan
                    Text(
                      'What specific steps will you take?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: '1. Read pages 45-60\n2. Take notes on key concepts\n3. Complete practice exercises',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                      onChanged: viewModel.setDetailedPlan,
                      maxLines: 6,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Energy Level
                    Text(
                      'How energized do you feel? (1-10)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildEnergySlider(
                      sessionState.preFocusEnergy ?? 7.0,
                      viewModel.setPreFocusEnergy,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tag Selection
                    Text(
                      'Select tags for this session',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: TagSelector(
                        selectedTags: sessionState.selectedTags,
                        onTagsChanged: viewModel.setSelectedTags,
                        showCreateButton: true,
                        hintText: 'Search subjects, topics, activities...',
                      ),
                    ),
                    
                    // Bottom padding for keyboard
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            
            // Fixed Bottom Button
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: sessionState.canStartSession
                      ? viewModel.proceedToChecklist
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3478F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.textSecondary,
                  ),
                  child: const Text(
                    'Review Pre-Session Checklist',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergySlider(double value, Function(double) onChanged) {
    return Column(
      children: [
        Slider(
          value: value,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          activeColor: const Color(0xFF3478F4),
          inactiveColor: AppColors.textSecondary,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1 (Low)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${value.round()}',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '10 (High)',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChecklistScreen(
    BuildContext context,
    FocusSessionState sessionState,
    FocusSessionNotifier viewModel,
  ) {
    final checklist = [
      {
        'title': 'Perform a singular task',
        'description': 'Avoid the cognitive penalty of switching and multitasking. It costs more than you can afford.',
      },
      {
        'title': 'Plan to start, not to finish',
        'description': 'Breakdown the task into smallest first task. Accomplish them and then the brain will take care of the rest.',
      },
      {
        'title': 'Ease into the task',
        'description': 'There is strong link between tensing and procrastination. When doing a task we can either tense into it or relax into it. Don\'t force yourself by tensing yourself physically and mentally. Learn to relax, release and surrender into productive tasks.',
      },
      {
        'title': 'You will never always feel like doing it',
        'description': 'Do it tired, do it when you don\'t feel like doing. Act like you want to do it. Think about your love for it. Even when you don\'t feel like it, act like your ideal self. You are reinforcing that identity. Every time you act in alignment with your ideal self, you\'re strengthening that neural pathway. This is how habits are built.',
      },
      {
        'title': 'Remove the friction',
        'description': 'Think about the task you want to accomplish a lot. Front load. Like remove distractions, open books and notebooks in advance etc. way before. Do everything so that all you need to do is have a tiny amount of motivation and you can get started.',
      },
      {
        'title': 'Be engaged during studying',
        'description': 'Use processes like mindmapping to stay actively engaged with the material.',
      },
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => viewModel.resetToModeSelection(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
                Expanded(
                  child: Text(
                    'Pre-Session Checklist',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Motivational Quote
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3478F4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3478F4).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '"Discipline is when your identity is so clear, you stop negotiating with your feelings."',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF3478F4),
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Don\'t be a weakling.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Checklist
            Expanded(
              child: ListView.builder(
                itemCount: checklist.length,
                itemBuilder: (context, index) {
                  final item = checklist[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3478F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']!,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['description']!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Start Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: viewModel.proceedToActiveSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3478F4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I\'m Ready - Start Focus Session',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSession(
    BuildContext context,
    FocusSessionState sessionState,
    FocusSessionNotifier viewModel,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header with lock indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Focus Mode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Mute Button
                    IconButton(
                      onPressed: viewModel.toggleMute,
                      icon: Icon(
                        sessionState.isMuted ? Icons.volume_off : Icons.volume_up,
                        color: sessionState.isMuted ? Colors.grey : AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => viewModel.requestEarlyExit(),
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // Progress Circle
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: sessionState.timerState == TimerState.running
                          ? _pulseAnimation.value
                          : 1.0,
                      child: _buildProgressCircle(sessionState),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Goal Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Goal:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sessionState.currentGoal ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: sessionState.timerState == TimerState.running
                        ? viewModel.pauseTimer
                        : viewModel.startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3478F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      sessionState.timerState == TimerState.running
                          ? 'Pause'
                          : 'Start',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCircle(FocusSessionState sessionState) {
    return Container(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: CircularProgressPainter(
          progress: sessionState.progress,
          backgroundColor: AppColors.darkSurface,
          progressColor: const Color(0xFF3478F4),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                sessionState.formattedTime,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sessionState.selectedMode.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarlyExitScreen(
    BuildContext context,
    FocusSessionState sessionState,
    FocusSessionNotifier viewModel,
  ) {
    final commonReasons = [
      'Phone notification distracted me',
      'Social media urge',
      'Feeling overwhelmed by the task',
      'Need a bathroom break',
      'Hungry or thirsty',
      'Lost focus and motivation',
      'Task completed early',
      'Emergency came up',
      'Too noisy environment',
      'Feeling tired or sleepy',
    ];
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Why do you want to stop?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Understanding your distractions helps you improve focus over time. Please select a reason before ending the session.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Session progress: ${(sessionState.progress * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    sessionState.formattedTime,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick options
            Text(
              'Select a reason:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: commonReasons.length,
                itemBuilder: (context, index) {
                  final reason = commonReasons[index];
                  final isSelected = _selectedExitReason == reason;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        reason,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedExitReason = reason;
                          _exitReasonController.text = reason;
                        });
                      },
                      tileColor: isSelected ? const Color(0xFF3478F4) : AppColors.darkSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Custom reason
            TextField(
              controller: _exitReasonController,
              decoration: InputDecoration(
                hintText: 'Or describe your own reason...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 2,
              onChanged: (value) {
                setState(() {
                  if (value.trim().isNotEmpty) {
                    _selectedExitReason = value.trim();
                  } else {
                    _selectedExitReason = null;
                  }
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: viewModel.cancelEarlyExit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkSurface,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue Session'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedExitReason != null && _selectedExitReason!.trim().isNotEmpty
                        ? () {
                            viewModel.addDistraction(_selectedExitReason!.trim());
                            viewModel.confirmEarlyExit(_selectedExitReason!.trim());
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedExitReason != null && _selectedExitReason!.trim().isNotEmpty
                          ? Colors.red
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('End Session'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReflectionScreen(
    BuildContext context,
    FocusSessionState sessionState,
    FocusSessionNotifier viewModel,
  ) {
    // Initialize controllers with existing data only once
    if (_reflectionController.text.isEmpty && sessionState.reflection != null) {
      _reflectionController.text = sessionState.reflection!;
    }
    if (_learningSummaryController.text.isEmpty && sessionState.learningSummary != null) {
      _learningSummaryController.text = sessionState.learningSummary!;
    }
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Session Reflection',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Take a moment to reflect on your session. This helps consolidate your learning and improve future sessions.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Session Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: ${sessionState.actualDurationMinutes} minutes',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.flag, color: AppColors.textSecondary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Goal: ${sessionState.currentGoal ?? 'No goal set'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Post-session energy
              Text(
                'How do you feel after this session? (1-10)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildEnergySlider(
                sessionState.postFocusEnergy ?? 7.0,
                viewModel.setPostFocusEnergy,
              ),
              
              const SizedBox(height: 24),
              
              // Tag modification
              Text(
                'Modify Session Tags',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update tags to better reflect what you actually worked on.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: TagSelector(
                  selectedTags: sessionState.selectedTags,
                  onTagsChanged: viewModel.setSelectedTags,
                  showCreateButton: true,
                  hintText: 'Search to update tags...',
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Key learnings
              Text(
                'Key Learnings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What insights or lessons did you gain from this session?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Add learning input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _learningController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Breaking tasks into smaller steps helps focus',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          viewModel.addKeyLearning(value.trim());
                          _learningController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (_learningController.text.trim().isNotEmpty) {
                        viewModel.addKeyLearning(_learningController.text.trim());
                        _learningController.clear();
                      }
                    },
                    icon: const Icon(Icons.add, color: Color(0xFF3478F4)),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.darkSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Display existing learnings
              if (sessionState.keyLearnings.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Learnings:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...sessionState.keyLearnings.asMap().entries.map((entry) {
                      final index = entry.key;
                      final learning = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: const Color(0xFF3478F4),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                learning,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => viewModel.removeKeyLearning(index),
                              icon: const Icon(Icons.close, size: 16),
                              color: AppColors.textSecondary,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              
              const SizedBox(height: 24),
              
              // Learning Summary (Brain Dump)
              Text(
                'Learning Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Brain dump everything you learned during this session.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _learningSummaryController,
                decoration: InputDecoration(
                  hintText: 'Write down all the concepts, insights, and knowledge you gained...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 6,
                onChanged: viewModel.setLearningSummary,
              ),
              
              const SizedBox(height: 24),
              
              // Productivity Reflection
              Text(
                'Productivity Reflection',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What went well? What could be improved?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reflectionController,
                decoration: InputDecoration(
                  hintText: 'I found that eliminating distractions helped me focus better. Next time, I should...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 4,
                onChanged: viewModel.setReflection,
              ),
              
              const SizedBox(height: 32),
              
              // Complete button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: viewModel.completeFocusSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3478F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Complete Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedScreen(
    BuildContext context,
    FocusSessionState sessionState,
    FocusSessionNotifier viewModel,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            
            // Success icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.green,
                size: 60,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Session Completed!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Great job on completing your focus session. Your progress has been saved.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const Spacer(),
            
            // New Session Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: viewModel.resetToModeSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3478F4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start New Session',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, FocusSessionNotifier viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timer Duration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pomodoro: 25 minutes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Flowmodoro: Variable duration',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Manage Tags Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Close settings dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TagManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.label_outline, size: 18),
                label: const Text('Manage Tags'),
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
            Text(
              'More settings coming soon...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for circular progress indicator
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 12.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 