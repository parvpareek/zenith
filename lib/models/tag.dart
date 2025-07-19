class Tag {
  final int? id;
  final String name;
  final int? parentId; // null for root categories
  final String color; // hex color for visual distinction
  final DateTime createdAt;
  final List<Tag>? children; // populated when needed for hierarchical display

  const Tag({
    this.id,
    required this.name,
    this.parentId,
    required this.color,
    required this.createdAt,
    this.children,
  });

  // Helper to check if this is a root category
  bool get isRootCategory => parentId == null;

  // Helper to check if this is a subcategory
  bool get isSubcategory => parentId != null;

  Tag copyWith({
    int? id,
    String? name,
    int? parentId,
    String? color,
    DateTime? createdAt,
    List<Tag>? children,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      children: children ?? this.children,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['name'],
      parentId: map['parent_id'],
      color: map['color'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, parentId: $parentId, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Helper class for tag analytics
class TagAnalytics {
  final Tag tag;
  final int totalSessions;
  final int totalMinutes;
  final int totalActualMinutes;
  final double averageEnergy;
  final int completedSessions;
  final int abandonedSessions;
  final List<String> commonDistractions;

  const TagAnalytics({
    required this.tag,
    required this.totalSessions,
    required this.totalMinutes,
    required this.totalActualMinutes,
    required this.averageEnergy,
    required this.completedSessions,
    required this.abandonedSessions,
    required this.commonDistractions,
  });

  double get completionRate => 
    totalSessions > 0 ? completedSessions / totalSessions : 0.0;

  double get efficiencyRate => 
    totalMinutes > 0 ? totalActualMinutes / totalMinutes : 0.0;

  int get abandonedRate => totalSessions - completedSessions;
}

// Predefined common tags for quick setup
class CommonTags {
  static const List<Map<String, dynamic>> defaultTags = [
    // Academic subjects
    {'name': 'Mathematics', 'color': '#FF6B6B', 'children': [
      {'name': 'Calculus', 'color': '#FF6B6B'},
      {'name': 'Algebra', 'color': '#FF6B6B'},
      {'name': 'Geometry', 'color': '#FF6B6B'},
      {'name': 'Statistics', 'color': '#FF6B6B'},
    ]},
    {'name': 'Physics', 'color': '#4ECDC4', 'children': [
      {'name': 'Mechanics', 'color': '#4ECDC4'},
      {'name': 'Thermodynamics', 'color': '#4ECDC4'},
      {'name': 'Optics', 'color': '#4ECDC4'},
      {'name': 'Electricity', 'color': '#4ECDC4'},
    ]},
    {'name': 'Chemistry', 'color': '#45B7D1', 'children': [
      {'name': 'Organic', 'color': '#45B7D1'},
      {'name': 'Inorganic', 'color': '#45B7D1'},
      {'name': 'Physical', 'color': '#45B7D1'},
    ]},
    {'name': 'Computer Science', 'color': '#96CEB4', 'children': [
      {'name': 'Programming', 'color': '#96CEB4'},
      {'name': 'Algorithms', 'color': '#96CEB4'},
      {'name': 'Data Structures', 'color': '#96CEB4'},
      {'name': 'Databases', 'color': '#96CEB4'},
    ]},
    
    // Activity types
    {'name': 'Study Activity', 'color': '#FFEAA7', 'children': [
      {'name': 'Theory Reading', 'color': '#FFEAA7'},
      {'name': 'Practice Problems', 'color': '#FFEAA7'},
      {'name': 'Mock Tests', 'color': '#FFEAA7'},
      {'name': 'Revision', 'color': '#FFEAA7'},
      {'name': 'Note Taking', 'color': '#FFEAA7'},
    ]},
    
    // Project types
    {'name': 'Projects', 'color': '#DDA0DD', 'children': [
      {'name': 'Personal Project', 'color': '#DDA0DD'},
      {'name': 'Work Project', 'color': '#DDA0DD'},
      {'name': 'Research', 'color': '#DDA0DD'},
    ]},
  ];
} 