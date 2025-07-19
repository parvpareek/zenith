import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/focus_session.dart';
import '../models/tag.dart';
import '../database/focus_session_dao.dart';
import '../database/tag_dao.dart';
import '../services/audio_service.dart';
import 'providers.dart';

enum TimerState { idle, running, paused, completed }

enum SessionStep { 
  modeSelection, 
  planning, 
  checklist,
  active, 
  earlyExit, 
  reflection, 
  completed 
}

class FocusSessionState {
  final TimerState timerState;
  final SessionStep currentStep;
  final int totalMinutes;
  final int remainingSeconds;
  final SessionMode selectedMode;
  final String? currentGoal;
  final String? detailedPlan;
  final double? preFocusEnergy;
  final double? postFocusEnergy;
  final List<String> distractions;
  final String? exitReason;
  final List<String> keyLearnings;
  final String? reflection;
  final String? learningSummary;
  final List<FocusSession> todaysSessions;
  final bool isLoading;
  final String? error;
  final bool isAppLocked;
  final List<Tag> selectedTags;
  final bool isMuted;
  final DateTime? timerStartTime;
  final DateTime? timerPauseTime;
  final int pausedElapsedSeconds;

  const FocusSessionState({
    this.timerState = TimerState.idle,
    this.currentStep = SessionStep.modeSelection,
    this.totalMinutes = 25,
    this.remainingSeconds = 1500, // 25 minutes
    this.selectedMode = SessionMode.pomodoro,
    this.currentGoal,
    this.detailedPlan,
    this.preFocusEnergy,
    this.postFocusEnergy,
    this.distractions = const [],
    this.exitReason,
    this.keyLearnings = const [],
    this.reflection,
    this.learningSummary,
    this.todaysSessions = const [],
    this.isLoading = false,
    this.error,
    this.isAppLocked = false,
    this.selectedTags = const [],
    this.isMuted = false,
    this.timerStartTime,
    this.timerPauseTime,
    this.pausedElapsedSeconds = 0,
  });

  FocusSessionState copyWith({
    TimerState? timerState,
    SessionStep? currentStep,
    int? totalMinutes,
    int? remainingSeconds,
    SessionMode? selectedMode,
    String? currentGoal,
    String? detailedPlan,
    double? preFocusEnergy,
    double? postFocusEnergy,
    List<String>? distractions,
    String? exitReason,
    List<String>? keyLearnings,
    String? reflection,
    String? learningSummary,
    List<FocusSession>? todaysSessions,
    bool? isLoading,
    String? error,
    bool? isAppLocked,
    List<Tag>? selectedTags,
    bool? isMuted,
    DateTime? timerStartTime,
    DateTime? timerPauseTime,
    int? pausedElapsedSeconds,
  }) {
    return FocusSessionState(
      timerState: timerState ?? this.timerState,
      currentStep: currentStep ?? this.currentStep,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      selectedMode: selectedMode ?? this.selectedMode,
      currentGoal: currentGoal ?? this.currentGoal,
      detailedPlan: detailedPlan ?? this.detailedPlan,
      preFocusEnergy: preFocusEnergy ?? this.preFocusEnergy,
      postFocusEnergy: postFocusEnergy ?? this.postFocusEnergy,
      distractions: distractions ?? this.distractions,
      exitReason: exitReason ?? this.exitReason,
      keyLearnings: keyLearnings ?? this.keyLearnings,
      reflection: reflection ?? this.reflection,
      learningSummary: learningSummary ?? this.learningSummary,
      todaysSessions: todaysSessions ?? this.todaysSessions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAppLocked: isAppLocked ?? this.isAppLocked,
      selectedTags: selectedTags ?? this.selectedTags,
      isMuted: isMuted ?? this.isMuted,
      timerStartTime: timerStartTime ?? this.timerStartTime,
      timerPauseTime: timerPauseTime ?? this.timerPauseTime,
      pausedElapsedSeconds: pausedElapsedSeconds ?? this.pausedElapsedSeconds,
    );
  }

  double get progress {
    final totalSeconds = totalMinutes * 60;
    return (totalSeconds - remainingSeconds) / totalSeconds;
  }

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get totalFocusTimeToday {
    return todaysSessions.fold(0, (total, session) => total + session.durationMinutes);
  }

  int get actualDurationMinutes {
    final totalSeconds = totalMinutes * 60;
    final elapsedSeconds = totalSeconds - remainingSeconds;
    return (elapsedSeconds / 60).ceil();
  }

  bool get canStartSession {
    return currentGoal != null && 
           currentGoal!.trim().isNotEmpty && 
           detailedPlan != null && 
           detailedPlan!.trim().isNotEmpty;
  }
}

class FocusSessionNotifier extends StateNotifier<FocusSessionState> with WidgetsBindingObserver {
  final FocusSessionDAO _focusSessionDAO;
  final TagDAO _tagDAO;
  Timer? _timer;

  FocusSessionNotifier(this._focusSessionDAO, this._tagDAO) : super(const FocusSessionState()) {
    loadTodaysSessions();
    _initializeTags();
    WidgetsBinding.instance.addObserver(this);
  }

  // Initialize default tags on first launch
  Future<void> _initializeTags() async {
    try {
      await _tagDAO.initializeDefaultTags();
    } catch (error) {
      // Ignore errors during initialization
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    
    // Disable wakelock on dispose
    WakelockPlus.disable();
    
    // Cancel running timer notification
    AudioService.instance.cancelRunningTimerNotification();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _handleAppPaused() {
    if (state.timerState == TimerState.running) {
      // Store current time when app goes to background
      final currentTime = DateTime.now();
      state = state.copyWith(timerPauseTime: currentTime);
    }
  }

  void _handleAppResumed() {
    if (state.timerState == TimerState.running && state.timerPauseTime != null) {
      // Calculate elapsed time while app was in background
      final resumeTime = DateTime.now();
      final backgroundElapsedSeconds = resumeTime.difference(state.timerPauseTime!).inSeconds;
      
      // Update remaining time
      final newRemainingSeconds = (state.remainingSeconds - backgroundElapsedSeconds).clamp(0, state.totalMinutes * 60);
      
      state = state.copyWith(
        remainingSeconds: newRemainingSeconds,
        timerPauseTime: null,
      );
      
      // Check if timer should complete
      if (newRemainingSeconds <= 0) {
        _completeTimer();
      }
    }
  }

  int _calculateCurrentRemainingSeconds() {
    if (state.timerState != TimerState.running || state.timerStartTime == null) {
      return state.remainingSeconds;
    }
    
    final currentTime = DateTime.now();
    final elapsedSeconds = currentTime.difference(state.timerStartTime!).inSeconds;
    final totalElapsedSeconds = state.pausedElapsedSeconds + elapsedSeconds;
    final totalSeconds = state.totalMinutes * 60;
    
    return (totalSeconds - totalElapsedSeconds).clamp(0, totalSeconds);
  }

  Future<void> loadTodaysSessions() async {
    try {
      state = state.copyWith(isLoading: true);
      final sessions = await _focusSessionDAO.getTodaysSessions();
      state = state.copyWith(
        todaysSessions: sessions,
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

  // Step 1: Mode Selection
  void selectMode(SessionMode mode) {
    int duration = mode == SessionMode.pomodoro ? 25 : 45; // Default durations
    state = state.copyWith(
      selectedMode: mode,
      totalMinutes: duration,
      remainingSeconds: duration * 60,
      currentStep: SessionStep.planning,
    );
  }

  // Step 2: Planning Phase
  void setGoal(String goal) {
    state = state.copyWith(currentGoal: goal);
  }

  void setDetailedPlan(String plan) {
    state = state.copyWith(detailedPlan: plan);
  }

  void setPreFocusEnergy(double energy) {
    state = state.copyWith(preFocusEnergy: energy);
  }

  void setDuration(int minutes) {
    if (state.timerState == TimerState.idle) {
      state = state.copyWith(
        totalMinutes: minutes,
        remainingSeconds: minutes * 60,
      );
    }
  }

  void proceedToChecklist() {
    if (state.canStartSession) {
      state = state.copyWith(
        currentStep: SessionStep.checklist,
      );
    }
  }

  void proceedToActiveSession() {
    state = state.copyWith(
      currentStep: SessionStep.active,
      isAppLocked: true,
    );
  }

  // Step 3: Active Session
  void startTimer() {
    final currentTime = DateTime.now();
    state = state.copyWith(
      timerState: TimerState.running,
      timerStartTime: currentTime,
      timerPauseTime: null,
      error: null,
    );

    // Enable wakelock to prevent device from sleeping
    WakelockPlus.enable();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remainingSeconds = _calculateCurrentRemainingSeconds();
      
      if (remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: remainingSeconds);
        
        // Update running timer notification
        if (state.currentGoal != null) {
          AudioService.instance.showRunningTimerNotification(
            state.formattedTime,
            state.currentGoal!,
          );
        }
      } else {
        _completeTimer();
      }
    });
  }

  void pauseTimer() {
    if (state.timerState == TimerState.running) {
      _timer?.cancel();
      
      // Disable wakelock when timer is paused
      WakelockPlus.disable();
      
      // Calculate elapsed time and store it
      final currentTime = DateTime.now();
      final elapsedSeconds = currentTime.difference(state.timerStartTime!).inSeconds;
      final totalElapsedSeconds = state.pausedElapsedSeconds + elapsedSeconds;
      
      state = state.copyWith(
        timerState: TimerState.paused,
        pausedElapsedSeconds: totalElapsedSeconds,
        timerStartTime: null,
      );
      
      // Cancel running timer notification
      AudioService.instance.cancelRunningTimerNotification();
    }
  }

  void resumeTimer() {
    if (state.timerState == TimerState.paused) {
      startTimer();
    }
  }

  // Step 4: Early Exit Handling
  void requestEarlyExit() {
    _timer?.cancel();
    
    // Disable wakelock when exiting early
    WakelockPlus.disable();
    
    // Cancel running timer notification
    AudioService.instance.cancelRunningTimerNotification();
    
    // Calculate elapsed time and store it
    if (state.timerState == TimerState.running && state.timerStartTime != null) {
      final currentTime = DateTime.now();
      final elapsedSeconds = currentTime.difference(state.timerStartTime!).inSeconds;
      final totalElapsedSeconds = state.pausedElapsedSeconds + elapsedSeconds;
      
      state = state.copyWith(
        currentStep: SessionStep.earlyExit,
        timerState: TimerState.paused,
        pausedElapsedSeconds: totalElapsedSeconds,
        timerStartTime: null,
      );
    } else {
      state = state.copyWith(
        currentStep: SessionStep.earlyExit,
        timerState: TimerState.paused,
      );
    }
  }

  void addDistraction(String distraction) {
    final updatedDistractions = [...state.distractions, distraction];
    state = state.copyWith(distractions: updatedDistractions);
  }

  void confirmEarlyExit(String reason) {
    // Cancel running timer notification
    AudioService.instance.cancelRunningTimerNotification();
    
    state = state.copyWith(
      exitReason: reason,
      currentStep: SessionStep.reflection,
    );
  }

  void cancelEarlyExit() {
    state = state.copyWith(
      currentStep: SessionStep.active,
    );
    resumeTimer();
  }

  // Step 5: Natural Completion
  void _completeTimer() {
    _timer?.cancel();
    
    // Disable wakelock when timer completes
    WakelockPlus.disable();
    
    state = state.copyWith(
      timerState: TimerState.completed,
      currentStep: SessionStep.reflection,
      isAppLocked: false,
      remainingSeconds: 0,
    );
    
    // Cancel running timer notification
    AudioService.instance.cancelRunningTimerNotification();
    
    // Play sound and show notification if not muted
    if (!state.isMuted) {
      AudioService.instance.playTimerCompleteSound();
    }
    AudioService.instance.showTimerCompleteNotification();
  }

  // Step 6: Reflection Phase
  void setPostFocusEnergy(double energy) {
    state = state.copyWith(postFocusEnergy: energy);
  }

  void addKeyLearning(String learning) {
    final updatedLearnings = [...state.keyLearnings, learning];
    state = state.copyWith(keyLearnings: updatedLearnings);
  }

  void removeKeyLearning(int index) {
    final updatedLearnings = [...state.keyLearnings];
    updatedLearnings.removeAt(index);
    state = state.copyWith(keyLearnings: updatedLearnings);
  }

  void setReflection(String reflection) {
    state = state.copyWith(reflection: reflection);
  }

  void setLearningSummary(String learningSummary) {
    state = state.copyWith(learningSummary: learningSummary);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  // Tag management methods
  void addTag(Tag tag) {
    final updatedTags = [...state.selectedTags, tag];
    state = state.copyWith(selectedTags: updatedTags);
  }

  void removeTag(Tag tag) {
    final updatedTags = state.selectedTags.where((t) => t.id != tag.id).toList();
    state = state.copyWith(selectedTags: updatedTags);
  }

  void clearTags() {
    state = state.copyWith(selectedTags: []);
  }

  void setSelectedTags(List<Tag> tags) {
    state = state.copyWith(selectedTags: tags);
  }

  // Step 7: Save Session
  Future<void> completeFocusSession() async {
    if (state.currentGoal?.trim().isEmpty ?? true) return;

    try {
      final session = FocusSession(
        goal: state.currentGoal!,
        detailedPlan: state.detailedPlan,
        summary: state.reflection,
        learningSummary: state.learningSummary,
        timestamp: DateTime.now(),
        durationMinutes: state.actualDurationMinutes ?? state.totalMinutes, // Use actual duration
        mode: state.selectedMode,
        phase: state.exitReason != null ? SessionPhase.abandoned : SessionPhase.completed,
        preFocusEnergy: state.preFocusEnergy,
        postFocusEnergy: state.postFocusEnergy,
        distractions: state.distractions,
        exitReason: state.exitReason,
        actualDurationMinutes: state.actualDurationMinutes,
        keyLearnings: state.keyLearnings,
        tags: state.selectedTags,
      );

      // Get tag IDs for saving
      final tagIds = state.selectedTags.map((tag) => tag.id!).toList();
      await _focusSessionDAO.insert(session, tagIds: tagIds);
      await loadTodaysSessions(); // Reload to get updated list
      
      // Reset for next session
      resetToModeSelection();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // Reset and Navigation
  void resetToModeSelection() {
    _timer?.cancel();
    
    // Disable wakelock when resetting to mode selection
    WakelockPlus.disable();
    
    // Cancel running timer notification
    AudioService.instance.cancelRunningTimerNotification();
    
    state = const FocusSessionState();
    loadTodaysSessions();
  }

  void resetTimer() {
    _timer?.cancel();
    
    // Disable wakelock when timer is reset
    WakelockPlus.disable();
    
    state = state.copyWith(
      timerState: TimerState.idle,
      remainingSeconds: state.totalMinutes * 60,
      timerStartTime: null,
      timerPauseTime: null,
      pausedElapsedSeconds: 0,
      error: null,
    );
    
    // Cancel running timer notification
    AudioService.instance.cancelRunningTimerNotification();
  }

  // Utility methods
  void updateTotalMinutes(int minutes) {
    if (state.timerState == TimerState.idle) {
      state = state.copyWith(
        totalMinutes: minutes,
        remainingSeconds: minutes * 60,
      );
    }
  }

  void updateSelectedMode(SessionMode mode) {
    state = state.copyWith(selectedMode: mode);
  }

  void updateCurrentStep(SessionStep step) {
    state = state.copyWith(currentStep: step);
  }

  void updateTimerState(TimerState timerState) {
    state = state.copyWith(timerState: timerState);
  }

  void updateRemainingSeconds(int seconds) {
    state = state.copyWith(remainingSeconds: seconds);
  }

  void updateIsAppLocked(bool isLocked) {
    state = state.copyWith(isAppLocked: isLocked);
  }

  void updateError(String? error) {
    state = state.copyWith(error: error);
  }

  void updateIsLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void updateTodaysSessions(List<FocusSession> sessions) {
    state = state.copyWith(todaysSessions: sessions);
  }

  void updateCurrentGoal(String? goal) {
    state = state.copyWith(currentGoal: goal);
  }

  void updateDetailedPlan(String? plan) {
    state = state.copyWith(detailedPlan: plan);
  }

  void updatePreFocusEnergy(double? energy) {
    state = state.copyWith(preFocusEnergy: energy);
  }

  void updatePostFocusEnergy(double? energy) {
    state = state.copyWith(postFocusEnergy: energy);
  }

  void updateDistractions(List<String> distractions) {
    state = state.copyWith(distractions: distractions);
  }

  void updateExitReason(String? reason) {
    state = state.copyWith(exitReason: reason);
  }

  void updateKeyLearnings(List<String> learnings) {
    state = state.copyWith(keyLearnings: learnings);
  }

  void updateReflection(String? reflection) {
    state = state.copyWith(reflection: reflection);
  }

  void updateLearningSummary(String? summary) {
    state = state.copyWith(learningSummary: summary);
  }

  void updateSelectedTags(List<Tag> tags) {
    state = state.copyWith(selectedTags: tags);
  }

  void updateIsMuted(bool isMuted) {
    state = state.copyWith(isMuted: isMuted);
  }
}

// Provider for focus session state
final focusSessionProvider = StateNotifierProvider<FocusSessionNotifier, FocusSessionState>((ref) {
  final focusSessionDAO = ref.watch(focusSessionDAOProvider);
  final tagDAO = ref.watch(tagDAOProvider);
  return FocusSessionNotifier(focusSessionDAO, tagDAO);
});

// Provider for getting focus sessions in date range (for AI Coach context)
final focusSessionsInRangeProvider = FutureProvider.family<List<FocusSession>, DateRange>((ref, dateRange) async {
  final focusSessionDAO = ref.watch(focusSessionDAOProvider);
  return await focusSessionDAO.getSessionsInDateRange(dateRange.start, dateRange.end);
});

// Provider for getting last N days focus sessions (for AI Coach context)
final lastNDaysFocusSessionsProvider = FutureProvider.family<List<FocusSession>, int>((ref, days) async {
  final focusSessionDAO = ref.watch(focusSessionDAOProvider);
  return await focusSessionDAO.getLastNDaysSessions(days);
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