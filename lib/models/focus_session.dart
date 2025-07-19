import 'tag.dart';

enum SessionMode {
  pomodoro,
  flowmodoro,
}

enum SessionPhase {
  planning,
  active,
  completed,
  abandoned,
}

class FocusSession {
  final int? id;
  final String goal;
  final String? detailedPlan; // Steps and outcomes planned
  final String? summary; // Productivity reflection - what went well, what could be improved
  final String? learningSummary; // Brain dump of what was learned during the session
  final DateTime timestamp;
  final int durationMinutes;
  final SessionMode mode;
  final SessionPhase phase;
  final double? preFocusEnergy; // 1-10 scale
  final double? postFocusEnergy; // 1-10 scale
  final List<String> distractions; // What made user want to leave
  final String? exitReason; // Why they stopped early (if applicable)
  final int? actualDurationMinutes; // Actual time spent if different from planned
  final List<String> keyLearnings; // Main points learned for LLM context
  final List<Tag> tags; // Tags associated with this session (loaded separately)

  const FocusSession({
    this.id,
    required this.goal,
    this.detailedPlan,
    this.summary,
    this.learningSummary,
    required this.timestamp,
    required this.durationMinutes,
    this.mode = SessionMode.pomodoro,
    this.phase = SessionPhase.planning,
    this.preFocusEnergy,
    this.postFocusEnergy,
    this.distractions = const [],
    this.exitReason,
    this.actualDurationMinutes,
    this.keyLearnings = const [],
    this.tags = const [],
  });

  FocusSession copyWith({
    int? id,
    String? goal,
    String? detailedPlan,
    String? summary,
    String? learningSummary,
    DateTime? timestamp,
    int? durationMinutes,
    SessionMode? mode,
    SessionPhase? phase,
    double? preFocusEnergy,
    double? postFocusEnergy,
    List<String>? distractions,
    String? exitReason,
    int? actualDurationMinutes,
    List<String>? keyLearnings,
    List<Tag>? tags,
  }) {
    return FocusSession(
      id: id ?? this.id,
      goal: goal ?? this.goal,
      detailedPlan: detailedPlan ?? this.detailedPlan,
      summary: summary ?? this.summary,
      learningSummary: learningSummary ?? this.learningSummary,
      timestamp: timestamp ?? this.timestamp,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      mode: mode ?? this.mode,
      phase: phase ?? this.phase,
      preFocusEnergy: preFocusEnergy ?? this.preFocusEnergy,
      postFocusEnergy: postFocusEnergy ?? this.postFocusEnergy,
      distractions: distractions ?? this.distractions,
      exitReason: exitReason ?? this.exitReason,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      keyLearnings: keyLearnings ?? this.keyLearnings,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal': goal,
      'detailedPlan': detailedPlan,
      'summary': summary,
      'learningSummary': learningSummary,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'mode': mode.index,
      'phase': phase.index,
      'preFocusEnergy': preFocusEnergy,
      'postFocusEnergy': postFocusEnergy,
      'distractions': distractions.join('|'), // Store as pipe-separated string
      'exitReason': exitReason,
      'actualDurationMinutes': actualDurationMinutes,
      'keyLearnings': keyLearnings.join('|'), // Store as pipe-separated string
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map, {List<Tag>? tags}) {
    return FocusSession(
      id: map['id']?.toInt(),
      goal: map['goal'] ?? '',
      detailedPlan: map['detailedPlan'],
      summary: map['summary'],
      learningSummary: map['learningSummary'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      durationMinutes: map['durationMinutes']?.toInt() ?? 25,
      mode: SessionMode.values[map['mode'] ?? 0],
      phase: SessionPhase.values[map['phase'] ?? 0],
      preFocusEnergy: map['preFocusEnergy']?.toDouble(),
      postFocusEnergy: map['postFocusEnergy']?.toDouble(),
      distractions: map['distractions'] != null && map['distractions'].isNotEmpty
          ? map['distractions'].split('|')
          : [],
      exitReason: map['exitReason'],
      actualDurationMinutes: map['actualDurationMinutes']?.toInt(),
      keyLearnings: map['keyLearnings'] != null && map['keyLearnings'].isNotEmpty
          ? map['keyLearnings'].split('|')
          : [],
      tags: tags ?? [],
    );
  }

  // LLM-friendly context format
  Map<String, dynamic> toLLMContext() {
    return {
      'session_id': id,
      'goal': goal,
      'detailed_plan': detailedPlan,
      'session_mode': mode.name,
      'planned_duration_minutes': durationMinutes,
      'actual_duration_minutes': actualDurationMinutes ?? durationMinutes,
      'completion_status': phase.name,
      'timestamp': timestamp.toIso8601String(),
      'energy_before': preFocusEnergy,
      'energy_after': postFocusEnergy,
      'distractions_encountered': distractions,
      'exit_reason': exitReason,
      'key_learnings': keyLearnings,
      'reflection_summary': summary,
      'tags': tags.map((tag) => {
        'id': tag.id,
        'name': tag.name,
        'category': tag.parentId != null ? 'subcategory' : 'main_category',
        'color': tag.color,
      }).toList(),
    };
  }

  @override
  String toString() {
    return 'FocusSession(id: $id, goal: $goal, mode: $mode, phase: $phase, duration: $durationMinutes min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FocusSession &&
        other.id == id &&
        other.goal == goal &&
        other.detailedPlan == detailedPlan &&
        other.summary == summary &&
        other.timestamp == timestamp &&
        other.durationMinutes == durationMinutes &&
        other.mode == mode &&
        other.phase == phase;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      goal,
      detailedPlan,
      summary,
      timestamp,
      durationMinutes,
      mode,
      phase,
    );
  }
}

extension SessionModeExtension on SessionMode {
  String get displayName {
    switch (this) {
      case SessionMode.pomodoro:
        return 'Pomodoro';
      case SessionMode.flowmodoro:
        return 'Flowmodoro';
    }
  }

  String get description {
    switch (this) {
      case SessionMode.pomodoro:
        return 'Fixed 25-minute sessions with 5-minute breaks';
      case SessionMode.flowmodoro:
        return 'Flexible sessions based on your natural flow';
    }
  }
}

extension SessionPhaseExtension on SessionPhase {
  String get displayName {
    switch (this) {
      case SessionPhase.planning:
        return 'Planning';
      case SessionPhase.active:
        return 'Active';
      case SessionPhase.completed:
        return 'Completed';
      case SessionPhase.abandoned:
        return 'Abandoned';
    }
  }
} 