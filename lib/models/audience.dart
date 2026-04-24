/// Strongly-typed audience for announcements.
enum Audience {
  everyone,
  students,
  parents,
  teachers;

  String get label {
    switch (this) {
      case Audience.everyone:
        return 'Everyone';
      case Audience.students:
        return 'Students';
      case Audience.parents:
        return 'Parents';
      case Audience.teachers:
        return 'Teachers';
    }
  }

  factory Audience.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'students':
        return Audience.students;
      case 'parents':
        return Audience.parents;
      case 'teachers':
        return Audience.teachers;
      default:
        return Audience.everyone;
    }
  }

  /// Whether this audience should be visible to a given role audience.
  bool isVisibleTo(Audience roleAudience) {
    return this == Audience.everyone || this == roleAudience;
  }
}
