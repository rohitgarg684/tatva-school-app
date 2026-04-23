enum UserRole {
  student,
  teacher,
  parent,
  principal;

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.parent:
        return 'Parent';
      case UserRole.principal:
        return 'Principal';
    }
  }

  factory UserRole.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'teacher':
        return UserRole.teacher;
      case 'parent':
        return UserRole.parent;
      case 'principal':
        return UserRole.principal;
      default:
        return UserRole.student;
    }
  }
}
