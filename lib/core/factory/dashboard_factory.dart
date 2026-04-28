import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../features/teacher/teacher_dashboard.dart';
import '../../features/parent/parent_dashboard.dart';
import '../../features/principal/principal_dashboard.dart';

class DashboardFactory {
  DashboardFactory._();

  static Widget create(UserRole role) {
    switch (role) {
      case UserRole.student:
        throw StateError('Student role cannot access the app directly');
      case UserRole.teacher:
        return const TeacherDashboard();
      case UserRole.parent:
        return const ParentDashboard();
      case UserRole.principal:
        return const PrincipalDashboard();
    }
  }
}
