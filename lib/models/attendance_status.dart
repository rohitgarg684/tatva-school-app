enum AttendanceStatus {
  present,
  absent,
  tardy;

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.tardy:
        return 'Tardy';
    }
  }

  String get emoji {
    switch (this) {
      case AttendanceStatus.present:
        return '✓';
      case AttendanceStatus.absent:
        return '✗';
      case AttendanceStatus.tardy:
        return '⏰';
    }
  }

  factory AttendanceStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'absent':
        return AttendanceStatus.absent;
      case 'tardy':
        return AttendanceStatus.tardy;
      default:
        return AttendanceStatus.present;
    }
  }
}
