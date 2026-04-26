enum Audience {
  everyone,
  grades;

  String get label {
    switch (this) {
      case Audience.everyone:
        return 'Everyone';
      case Audience.grades:
        return 'Grades';
    }
  }

  factory Audience.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'grades':
        return Audience.grades;
      default:
        return Audience.everyone;
    }
  }
}
