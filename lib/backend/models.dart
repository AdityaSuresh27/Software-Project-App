/// Models - Core Data Structures for ClassFlow
/// 
/// This file defines the main models used throughout the app:
/// - Event: Class, exam, assignment, meeting, personal event
/// - VoiceNote: Audio recording attached to an event
/// - Category: User-defined grouping for events
/// 
/// All models support serialization to JSON for persistent storage

// ========== EVENT MODEL ==========
/// Event - Represents any calendar event
/// 
/// Types: 'class', 'exam', 'assignment', 'meeting', 'other'
/// Priorities: 'low', 'medium', 'high', 'critical'
/// 
class Event {
  final String id;
  String title;
  /// Classification determines event type: class, exam, assignment, or meeting
  String classification; // 'class', 'exam', 'assignment', 'deadline', 'meeting', 'personal', 'other'
  /// Category used for filtering and organization (e.g., 'Math', 'Biology')
  String? category; // Subject/Course name
  /// Start time of the event
  DateTime startTime;
  /// End time - optional for tasks/deadlines
  DateTime? endTime; // Optional for tasks/deadlines
  /// Event location (classroom, online, etc.)
  String? location;
  /// Text notes attached to event
  String? notes;
  /// File attachments (not yet implemented)
  List<String> attachments;
  /// Audio recordings attached to event
  List<VoiceNote> voiceNotes;
  /// Whether event has been completed/done
  bool isCompleted;
  /// Whether event was missed
  bool isMissed;
  /// Whether event was cancelled
  bool isCancelled;
  String? completionColor;
  /// Priority level affects notification urgency
  String priority; // 'low', 'medium', 'high', 'critical'
  /// Estimated time to complete (for assignments)
  String? estimatedDuration; // For assignments
  /// Flag for important/starred events - triggers priority notifications
  bool isImportant; // Star/flag for emphasis
  /// Custom reminder times - can have multiple reminders per event
  List<DateTime> reminders;
  String? color; // Custom color override
  int periodCount; // How many periods/classes this event counts for (default 1)
  Map<String, dynamic>? metadata; // Flexible field for future extensions

  Event({
    required this.id,
    required this.title,
    required this.classification,
    required this.startTime,
    this.category,
    this.endTime,
    this.location,
    this.notes,
    this.attachments = const [],
    this.voiceNotes = const [],
    this.isCompleted = false,
    this.isMissed = false,
    this.isCancelled = false,
    this.completionColor,
    this.priority = 'medium',
    this.estimatedDuration,
    this.isImportant = false,
    this.reminders = const [],
    this.color,
    this.periodCount = 1,
    this.metadata,
  });

  // Helper to check if this is a task-type event
  bool get isTask => classification == 'assignment' || 
                     classification == 'deadline' || 
                     classification == 'exam';

  // Helper to check if this has a specific end time
  bool get hasEndTime => endTime != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'classification': classification,
    'category': category,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'location': location,
    'notes': notes,
    'attachments': attachments,
    'voiceNotes': voiceNotes.map((v) => v.toJson()).toList(),
    'isCompleted': isCompleted,
    'isMissed': isMissed,
    'isCancelled': isCancelled,
    'completionColor': completionColor,
    'priority': priority,
    'estimatedDuration': estimatedDuration,
    'isImportant': isImportant,
    'reminders': reminders.map((r) => r.toIso8601String()).toList(),
    'color': color,
    'periodCount': periodCount,
    'metadata': metadata,
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'],
    title: json['title'],
    classification: json['classification'],
    category: json['category'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    location: json['location'],
    notes: json['notes'],
    attachments: List<String>.from(json['attachments'] ?? []),
    voiceNotes: (json['voiceNotes'] as List?)?.map((v) => VoiceNote.fromJson(v)).toList() ?? [],
    isCompleted: json['isCompleted'] ?? false,
    isMissed: json['isMissed'] ?? false,
    isCancelled: json['isCancelled'] ?? false,
    completionColor: json['completionColor'],
    priority: json['priority'] ?? 'medium',
    estimatedDuration: json['estimatedDuration'],
    isImportant: json['isImportant'] ?? false,
    reminders: (json['reminders'] as List?)?.map((r) => DateTime.parse(r as String)).toList() ?? [],
    color: json['color'],
    periodCount: json['periodCount'] ?? 1,
    metadata: json['metadata'],
  );

  Event duplicate() {
    return Event(
      id: '${id}_copy_${DateTime.now().millisecondsSinceEpoch}',
      title: '$title (Copy)',
      classification: classification,
      category: category,
      startTime: startTime,
      endTime: endTime,
      location: location,
      notes: notes,
      attachments: List.from(attachments),
      voiceNotes: List.from(voiceNotes),
      isCompleted: false,
      isMissed: false,
      isCancelled: false,
      completionColor: null,
      priority: priority,
      estimatedDuration: estimatedDuration,
      isImportant: isImportant,
      reminders: List.from(reminders),
      color: color,
      periodCount: periodCount,
      metadata: metadata != null ? Map.from(metadata!) : null,
    );
  }
}

class VoiceNote {
  final String id;
  final String filePath;
  final DateTime recordedAt;
  final Duration duration;
  final List<String> tags;

  VoiceNote({
    required this.id,
    required this.filePath,
    required this.recordedAt,
    required this.duration,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'recordedAt': recordedAt.toIso8601String(),
    'duration': duration.inSeconds,
    'tags': tags,
  };

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
    id: json['id'],
    filePath: json['filePath'],
    recordedAt: DateTime.parse(json['recordedAt']),
    duration: Duration(seconds: json['duration']),
    tags: List<String>.from(json['tags'] ?? []),
  );
}

// Category model for organizing events
class Category {
  final String id;
  String name;
  String? color;
  String? icon;
  
  Category({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'icon': icon,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    color: json['color'],
    icon: json['icon'],
  );
}

// ========== AVATAR MODEL ==========
/// Avatar - Customizable user avatar with game-like features
/// 
/// Stores avatar customization including body style, colors, accessories
/// and animation preferences. Renders as a simple geometric character.
class Avatar {
  /// Avatar body style: 'circle', 'square', 'rounded'
  String bodyStyle;
  /// Base color of the avatar (as hex string)
  String bodyColor;
  /// Accent color for details (as hex string)
  String accentColor;
  /// Eyes style: 'round', 'square', 'x_eyes'
  String eyesStyle;
  /// Eyes color (as hex string) - affects pupil color, not eye whites
  String eyesColor;
  /// Mouth style: 'smile', 'neutral', 'surprised', 'box'
  String mouthStyle;
  /// Whether avatar has glasses
  bool hasGlasses;

  Avatar({
    this.bodyStyle = 'rounded',
    this.bodyColor = '#45B7D1',
    this.accentColor = '#FFC75F',
    this.eyesStyle = 'square',
    this.eyesColor = '#3366FF',
    this.mouthStyle = 'box',
    this.hasGlasses = false,
  });

  /// Create a random avatar
  factory Avatar.random() {
    const bodyStyles = ['circle', 'square', 'rounded'];
    const eyesStyles = ['round', 'square', 'x_eyes'];
    const mouthStyles = ['smile', 'neutral', 'surprised', 'box'];
    const colors = [
      '#FF6B9D', '#FF6B9D', '#4ECDC4', '#45B7D1', '#FFA07A', 
      '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E2', '#3366FF', '#FF69B4', '#00CED1'
    ];
    const eyeColors = ['#000000', '#3366FF', '#FF0000', '#00AA00', '#FFB6C1', '#4B0082'];
    final random = DateTime.now().microsecond;

    return Avatar(
      bodyStyle: bodyStyles[random % bodyStyles.length],
      bodyColor: colors[random % colors.length],
      accentColor: colors[(random + 1) % colors.length],
      eyesStyle: eyesStyles[(random + 2) % eyesStyles.length],
      eyesColor: eyeColors[(random + 3) % eyeColors.length],
      mouthStyle: mouthStyles[(random + 4) % mouthStyles.length],
      hasGlasses: random % 3 == 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'bodyStyle': bodyStyle,
    'bodyColor': bodyColor,
    'accentColor': accentColor,
    'eyesStyle': eyesStyle,
    'eyesColor': eyesColor,
    'mouthStyle': mouthStyle,
    'hasGlasses': hasGlasses,
  };

  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
    bodyStyle: json['bodyStyle'] ?? 'rounded',
    bodyColor: json['bodyColor'] ?? '#45B7D1',
    accentColor: json['accentColor'] ?? '#FFC75F',
    eyesStyle: json['eyesStyle'] ?? 'square',
    eyesColor: json['eyesColor'] ?? '#3366FF',
    mouthStyle: json['mouthStyle'] ?? 'box',
    hasGlasses: json['hasGlasses'] ?? false,
  );

  Avatar copyWith({
    String? bodyStyle,
    String? bodyColor,
    String? accentColor,
    String? eyesStyle,
    String? eyesColor,
    String? mouthStyle,
    bool? hasGlasses,
  }) => Avatar(
    bodyStyle: bodyStyle ?? this.bodyStyle,
    bodyColor: bodyColor ?? this.bodyColor,
    accentColor: accentColor ?? this.accentColor,
    eyesStyle: eyesStyle ?? this.eyesStyle,
    eyesColor: eyesColor ?? this.eyesColor,
    mouthStyle: mouthStyle ?? this.mouthStyle,
    hasGlasses: hasGlasses ?? this.hasGlasses,
  );
}