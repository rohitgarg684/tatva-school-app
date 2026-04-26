class ScheduleEvent {
  final String id;
  final String title;
  final String description;
  final String date; // YYYY-MM-DD
  final String startTime; // "09:00"
  final String endTime; // "10:00"
  final String type; // 'ptm', 'holiday', 'event', 'override'
  final String createdBy;
  final List<String> affectedGrades; // empty = school-wide
  final bool cancelsRegularSchedule;
  final DateTime? createdAt;

  const ScheduleEvent({
    this.id = '',
    required this.title,
    this.description = '',
    required this.date,
    this.startTime = '',
    this.endTime = '',
    this.type = 'event',
    this.createdBy = '',
    this.affectedGrades = const [],
    this.cancelsRegularSchedule = false,
    this.createdAt,
  });

  factory ScheduleEvent.fromJson(Map<String, dynamic> data) {
    return ScheduleEvent(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      date: data['date'] as String? ?? '',
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      type: data['type'] as String? ?? 'event',
      createdBy: data['createdBy'] as String? ?? '',
      affectedGrades: List<String>.from(data['affectedGrades'] ?? []),
      cancelsRegularSchedule: data['cancelsRegularSchedule'] == true,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'type': type,
        'createdBy': createdBy,
        'affectedGrades': affectedGrades,
        'cancelsRegularSchedule': cancelsRegularSchedule,
      };

  static const typeLabels = {
    'ptm': 'Parent-Teacher Meeting',
    'holiday': 'Holiday / No School',
    'event': 'Special Event',
    'override': 'Schedule Override',
  };

  static const typeIcons = {
    'ptm': 0xe530, // Icons.people_outline
    'holiday': 0xe560, // Icons.wb_sunny_outlined
    'event': 0xe55b, // Icons.star_outline
    'override': 0xe8b5, // Icons.swap_horiz
  };

  String get typeLabel => typeLabels[type] ?? 'Event';
}
