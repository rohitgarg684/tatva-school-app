import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/class_model.dart';
import '../models/grade_model.dart';
import '../models/announcement_model.dart';
import '../models/homework_model.dart';
import '../models/vote_model.dart';
import '../models/behavior_point.dart';
import '../models/attendance_record.dart';
import '../models/activity_event.dart';
import '../models/content_item.dart';
import '../models/child_info.dart';
import '../repositories/auth_repository.dart';
import 'api_service.dart';

/// Data bundle returned for the student dashboard.
class StudentDashboardData {
  final UserModel user;
  final ClassModel? primaryClass;
  final List<GradeModel> grades;
  final List<AnnouncementModel> announcements;
  final List<HomeworkModel> homework;
  final List<VoteModel> activeVotes;
  final List<BehaviorPoint> behaviorPoints;
  final int behaviorScore;
  final List<AttendanceRecord> attendance;
  final List<ActivityEvent> activityFeed;
  final List<ContentItem> contentItems;

  const StudentDashboardData({
    required this.user,
    this.primaryClass,
    this.grades = const [],
    this.announcements = const [],
    this.homework = const [],
    this.activeVotes = const [],
    this.behaviorPoints = const [],
    this.behaviorScore = 0,
    this.attendance = const [],
    this.activityFeed = const [],
    this.contentItems = const [],
  });

  StudentDashboardData copyWithPhotoUrl(String url) => StudentDashboardData(
        user: user.copyWith(photoUrl: url),
        primaryClass: primaryClass,
        grades: grades,
        announcements: announcements,
        homework: homework,
        activeVotes: activeVotes,
        behaviorPoints: behaviorPoints,
        behaviorScore: behaviorScore,
        attendance: attendance,
        activityFeed: activityFeed,
        contentItems: contentItems,
      );
}

/// Data bundle returned for the teacher dashboard.
class TeacherDashboardData {
  final UserModel user;
  final List<ClassModel> classes;
  final List<UserModel> studentsInFirstClass;
  final List<UserModel> parentsInFirstClass;
  final List<GradeModel> gradesInFirstClass;
  final List<GradeModel> allTeacherGrades;
  final List<Map<String, dynamic>> testTitles;
  final List<AnnouncementModel> announcements;
  final List<HomeworkModel> homework;
  final List<BehaviorPoint> classBehavior;
  final List<AttendanceRecord> todayAttendance;
  final List<ActivityEvent> activityFeed;
  final List<UserModel> allStudents;
  final List<ContentItem> contentItems;

  const TeacherDashboardData({
    required this.user,
    this.classes = const [],
    this.studentsInFirstClass = const [],
    this.parentsInFirstClass = const [],
    this.gradesInFirstClass = const [],
    this.allTeacherGrades = const [],
    this.testTitles = const [],
    this.announcements = const [],
    this.homework = const [],
    this.classBehavior = const [],
    this.todayAttendance = const [],
    this.activityFeed = const [],
    this.allStudents = const [],
    this.contentItems = const [],
  });

  TeacherDashboardData copyWithPhotoUrl(String url) => TeacherDashboardData(
        user: user.copyWith(photoUrl: url),
        classes: classes,
        studentsInFirstClass: studentsInFirstClass,
        parentsInFirstClass: parentsInFirstClass,
        gradesInFirstClass: gradesInFirstClass,
        allTeacherGrades: allTeacherGrades,
        testTitles: testTitles,
        announcements: announcements,
        homework: homework,
        classBehavior: classBehavior,
        todayAttendance: todayAttendance,
        activityFeed: activityFeed,
        allStudents: allStudents,
        contentItems: contentItems,
      );
}

/// Data for a single child, used in multi-child parent dashboard.
class ChildDashboardData {
  final ChildInfo info;
  final String childUid;
  final ClassModel? childClass;
  final List<GradeModel> grades;
  final List<BehaviorPoint> behaviorPoints;
  final int behaviorScore;
  final List<AttendanceRecord> attendance;

  const ChildDashboardData({
    required this.info,
    this.childUid = '',
    this.childClass,
    this.grades = const [],
    this.behaviorPoints = const [],
    this.behaviorScore = 0,
    this.attendance = const [],
  });
}

/// Data bundle returned for the parent dashboard.
class ParentDashboardData {
  final UserModel user;
  final List<ChildDashboardData> childrenData;
  final List<AnnouncementModel> announcements;
  final List<VoteModel> activeVotes;
  final List<ActivityEvent> activityFeed;
  final List<ContentItem> contentItems;

  const ParentDashboardData({
    required this.user,
    this.childrenData = const [],
    this.announcements = const [],
    this.activeVotes = const [],
    this.activityFeed = const [],
    this.contentItems = const [],
  });
}

/// Data bundle returned for the principal dashboard.
class PrincipalDashboardData {
  final UserModel user;
  final int teacherCount;
  final int studentCount;
  final int classCount;
  final List<UserModel> teachers;
  final List<UserModel> students;
  final List<ClassModel> allClasses;
  final List<UserModel> parents;
  final List<GradeModel> allGrades;
  final Map<String, double> subjectAverages;
  final List<AnnouncementModel> announcements;
  final List<VoteModel> activeVotes;
  final List<ActivityEvent> activityFeed;
  final int totalBehaviorPoints;
  final int attendanceRate;

  const PrincipalDashboardData({
    required this.user,
    this.teacherCount = 0,
    this.studentCount = 0,
    this.classCount = 0,
    this.teachers = const [],
    this.students = const [],
    this.allClasses = const [],
    this.parents = const [],
    this.allGrades = const [],
    this.subjectAverages = const {},
    this.announcements = const [],
    this.activeVotes = const [],
    this.activityFeed = const [],
    this.totalBehaviorPoints = 0,
    this.attendanceRate = 0,
  });
}

// ─── Deserialization helpers ────────────────────────────────────────────────

List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw == null) return [];
  return (raw as List<dynamic>)
      .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

T? _parseNullable<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw == null) return null;
  return fromJson(Map<String, dynamic>.from(raw as Map));
}

/// Orchestrates data loading for all dashboards via a single Cloud Function
/// call per dashboard. All Firestore queries happen server-side.
class DashboardService {
  final AuthRepository _authRepo;
  final ApiService _api;

  StudentDashboardData? _cachedStudentData;
  TeacherDashboardData? _cachedTeacherData;
  ParentDashboardData? _cachedParentData;
  PrincipalDashboardData? _cachedPrincipalData;

  DashboardService({
    AuthRepository? authRepo,
    ApiService? api,
  })  : _authRepo = authRepo ?? AuthRepository(),
        _api = api ?? ApiService();

  String get _uid => _authRepo.currentUid ?? '';

  void invalidateCache() {
    _cachedStudentData = null;
    _cachedTeacherData = null;
    _cachedParentData = null;
    _cachedPrincipalData = null;
  }

  // ─── Student ────────────────────────────────────────────────────────────

  Future<StudentDashboardData> loadStudentDashboard({
    String? overrideUid,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedStudentData != null) {
      return _cachedStudentData!;
    }

    final uid = overrideUid ?? _uid;
    if (uid.isEmpty) {
      return StudentDashboardData(
          user: UserModel(uid: '', name: '', email: '', role: UserRole.student));
    }

    final json = await _api.getStudentDashboard(uid);

    final data = StudentDashboardData(
      user: UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      primaryClass: _parseNullable(json['primaryClass'], ClassModel.fromJson),
      grades: _parseList(json['grades'], GradeModel.fromJson),
      announcements:
          _parseList(json['announcements'], AnnouncementModel.fromJson),
      homework: _parseList(json['homework'], HomeworkModel.fromJson),
      activeVotes: _parseList(json['activeVotes'], VoteModel.fromJson),
      behaviorPoints:
          _parseList(json['behaviorPoints'], BehaviorPoint.fromJson),
      behaviorScore: (json['behaviorScore'] as num?)?.toInt() ?? 0,
      attendance: _parseList(json['attendance'], AttendanceRecord.fromJson),
      activityFeed: _parseList(json['activityFeed'], ActivityEvent.fromJson),
      contentItems: _parseList(json['contentItems'], ContentItem.fromJson),
    );

    _cachedStudentData = data;
    return data;
  }

  // ─── Teacher ────────────────────────────────────────────────────────────

  Future<TeacherDashboardData> loadTeacherDashboard({
    String? overrideUid,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedTeacherData != null) {
      return _cachedTeacherData!;
    }

    final uid = overrideUid ?? _uid;
    if (uid.isEmpty) {
      return TeacherDashboardData(
          user: UserModel(uid: '', name: '', email: '', role: UserRole.teacher));
    }

    final json = await _api.getTeacherDashboard(uid);

    final data = TeacherDashboardData(
      user: UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      classes: _parseList(json['classes'], ClassModel.fromJson),
      studentsInFirstClass:
          _parseList(json['studentsInFirstClass'], UserModel.fromJson),
      parentsInFirstClass:
          _parseList(json['parentsInFirstClass'], UserModel.fromJson),
      gradesInFirstClass:
          _parseList(json['gradesInFirstClass'], GradeModel.fromJson),
      allTeacherGrades:
          _parseList(json['allTeacherGrades'], GradeModel.fromJson),
      testTitles: (json['testTitles'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [],
      announcements:
          _parseList(json['announcements'], AnnouncementModel.fromJson),
      homework: _parseList(json['homework'], HomeworkModel.fromJson),
      classBehavior:
          _parseList(json['classBehavior'], BehaviorPoint.fromJson),
      todayAttendance:
          _parseList(json['todayAttendance'], AttendanceRecord.fromJson),
      activityFeed: _parseList(json['activityFeed'], ActivityEvent.fromJson),
      allStudents: _parseList(json['allStudents'], UserModel.fromJson),
      contentItems: _parseList(json['contentItems'], ContentItem.fromJson),
    );

    _cachedTeacherData = data;
    return data;
  }

  // ─── Parent ─────────────────────────────────────────────────────────────

  Future<ParentDashboardData> loadParentDashboard({
    String? overrideUid,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedParentData != null) {
      return _cachedParentData!;
    }

    final uid = overrideUid ?? _uid;
    if (uid.isEmpty) {
      return ParentDashboardData(
          user: UserModel(uid: '', name: '', email: '', role: UserRole.parent));
    }

    final json = await _api.getParentDashboard(uid);

    final childrenRaw = json['childrenData'] as List<dynamic>? ?? [];
    final childrenData = childrenRaw.map((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      final infoMap = Map<String, dynamic>.from(m['info'] as Map? ?? {});
      return ChildDashboardData(
        info: ChildInfo.fromJson(infoMap),
        childUid: m['childUid'] as String? ?? '',
        childClass: _parseNullable(m['childClass'], ClassModel.fromJson),
        grades: _parseList(m['grades'], GradeModel.fromJson),
        behaviorPoints: _parseList(m['behaviorPoints'], BehaviorPoint.fromJson),
        behaviorScore: (m['behaviorScore'] as num?)?.toInt() ?? 0,
        attendance: _parseList(m['attendance'], AttendanceRecord.fromJson),
      );
    }).toList();

    final data = ParentDashboardData(
      user: UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      childrenData: childrenData,
      announcements:
          _parseList(json['announcements'], AnnouncementModel.fromJson),
      activeVotes: _parseList(json['activeVotes'], VoteModel.fromJson),
      activityFeed: _parseList(json['activityFeed'], ActivityEvent.fromJson),
      contentItems: _parseList(json['contentItems'], ContentItem.fromJson),
    );

    _cachedParentData = data;
    return data;
  }

  // ─── Principal ──────────────────────────────────────────────────────────

  Future<PrincipalDashboardData> loadPrincipalDashboard({
    String? overrideUid,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedPrincipalData != null) {
      return _cachedPrincipalData!;
    }

    final uid = overrideUid ?? _uid;
    if (uid.isEmpty) {
      return PrincipalDashboardData(
          user: UserModel(
              uid: '', name: '', email: '', role: UserRole.principal));
    }

    final json = await _api.getPrincipalDashboard(uid);

    final subjectAvgRaw =
        json['subjectAverages'] as Map<dynamic, dynamic>? ?? {};
    final subjectAverages = subjectAvgRaw.map<String, double>(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    );

    final data = PrincipalDashboardData(
      user: UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
      teacherCount: (json['teacherCount'] as num?)?.toInt() ?? 0,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      classCount: (json['classCount'] as num?)?.toInt() ?? 0,
      teachers: _parseList(json['teachers'], UserModel.fromJson),
      students: _parseList(json['students'], UserModel.fromJson),
      allClasses: _parseList(json['allClasses'], ClassModel.fromJson),
      parents: _parseList(json['parents'], UserModel.fromJson),
      allGrades: _parseList(json['allGrades'], GradeModel.fromJson),
      subjectAverages: subjectAverages,
      announcements:
          _parseList(json['announcements'], AnnouncementModel.fromJson),
      activeVotes: _parseList(json['activeVotes'], VoteModel.fromJson),
      activityFeed: _parseList(json['activityFeed'], ActivityEvent.fromJson),
    );

    _cachedPrincipalData = data;
    return data;
  }
}
