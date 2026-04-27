import 'package:flutter/material.dart';

class Holiday {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String type;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Holiday({
    this.id = '',
    required this.name,
    required this.startDate,
    required this.endDate,
    this.type = 'custom',
    this.description = '',
    this.createdBy = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Holiday.fromJson(Map<String, dynamic> data) {
    return Holiday(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      startDate: data['startDate'] as String? ?? '',
      endDate: data['endDate'] as String? ?? '',
      type: data['type'] as String? ?? 'custom',
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Holiday copyWith({
    String? id,
    String? name,
    String? startDate,
    String? endDate,
    String? type,
    String? description,
  }) {
    return Holiday(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      description: description ?? this.description,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isMultiDay => startDate != endDate;

  int get durationDays {
    final s = DateTime.tryParse(startDate);
    final e = DateTime.tryParse(endDate);
    if (s == null || e == null) return 1;
    return e.difference(s).inDays + 1;
  }

  bool coversDate(String dateStr) {
    return dateStr.compareTo(startDate) >= 0 && dateStr.compareTo(endDate) <= 0;
  }

  String get typeLabel => typeLabels[type] ?? 'Holiday';
  Color get typeColor => typeColors[type] ?? const Color(0xFF6366F1);
  IconData get typeIcon => typeIcons[type] ?? Icons.event;

  static const typeLabels = {
    'federal': 'Federal Holiday',
    'summer_break': 'Summer Break',
    'spring_break': 'Spring Break',
    'winter_break': 'Winter Break',
    'teacher_workday': 'Teacher Workday',
    'custom': 'School Holiday',
  };

  static const typeColors = {
    'federal': Color(0xFFEF4444),
    'summer_break': Color(0xFFF59E0B),
    'spring_break': Color(0xFF10B981),
    'winter_break': Color(0xFF3B82F6),
    'teacher_workday': Color(0xFF8B5CF6),
    'custom': Color(0xFF6366F1),
  };

  static const typeIcons = {
    'federal': Icons.flag_outlined,
    'summer_break': Icons.wb_sunny_outlined,
    'spring_break': Icons.local_florist_outlined,
    'winter_break': Icons.ac_unit_outlined,
    'teacher_workday': Icons.school_outlined,
    'custom': Icons.event_outlined,
  };

  static const typeKeys = ['federal', 'summer_break', 'spring_break', 'winter_break', 'teacher_workday', 'custom'];
}
