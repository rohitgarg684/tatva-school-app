import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/class_model.dart';
import '../models/grade_model.dart';
import '../models/announcement_model.dart';
import '../models/homework_model.dart';
import '../models/vote_model.dart';
import '../models/audience.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/class_repository.dart';
import 'grade_service.dart';
import 'homework_service.dart';
import 'announcement_service.dart';
import 'vote_service.dart';

/// Data bundle returned for the student dashboard.
class StudentDashboardData {
  final UserModel user;
  final ClassModel? primaryClass;
  final List<GradeModel> grades;
  final List<AnnouncementModel> announcements;
  final List<HomeworkModel> homework;
  final List<VoteModel> activeVotes;

  const StudentDashboardData({
    required this.user,
    this.primaryClass,
    this.grades = const [],
    this.announcements = const [],
    this.homework = const [],
    this.activeVotes = const [],
  });
}

/// Data bundle returned for the teacher dashboard.
class TeacherDashboardData {
  final UserModel user;
  final List<ClassModel> classes;
  final List<UserModel> studentsInFirstClass;
  final List<UserModel> parentsInFirstClass;
  final List<GradeModel> gradesInFirstClass;
  final List<AnnouncementModel> announcements;
  final List<HomeworkModel> homework;

  const TeacherDashboardData({
    required this.user,
    this.classes = const [],
    this.studentsInFirstClass = const [],
    this.parentsInFirstClass = const [],
    this.gradesInFirstClass = const [],
    this.announcements = const [],
    this.homework = const [],
  });
}

/// Data bundle returned for the parent dashboard.
class ParentDashboardData {
  final UserModel user;
  final ClassModel? childClass;
  final String childUid;
  final List<GradeModel> childGrades;
  final List<AnnouncementModel> announcements;
  final List<VoteModel> activeVotes;

  const ParentDashboardData({
    required this.user,
    this.childClass,
    this.childUid = '',
    this.childGrades = const [],
    this.announcements = const [],
    this.activeVotes = const [],
  });
}

/// Data bundle returned for the principal dashboard.
class PrincipalDashboardData {
  final UserModel user;
  final int teacherCount;
  final int studentCount;
  final int classCount;
  final List<UserModel> teachers;
  final List<ClassModel> allClasses;
  final List<UserModel> parents;
  final List<GradeModel> allGrades;
  final Map<String, double> subjectAverages;
  final List<AnnouncementModel> announcements;
  final List<VoteModel> activeVotes;

  const PrincipalDashboardData({
    required this.user,
    this.teacherCount = 0,
    this.studentCount = 0,
    this.classCount = 0,
    this.teachers = const [],
    this.allClasses = const [],
    this.parents = const [],
    this.allGrades = const [],
    this.subjectAverages = const {},
    this.announcements = const [],
    this.activeVotes = const [],
  });
}

/// Orchestrates data loading for all dashboards.
/// Dashboards call this instead of individual repositories.
class DashboardService {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final ClassRepository _classRepo;
  final GradeService _gradeSvc;
  final HomeworkService _homeworkSvc;
  final AnnouncementService _announcementSvc;
  final VoteService _voteSvc;

  DashboardService({
    AuthRepository? authRepo,
    UserRepository? userRepo,
    ClassRepository? classRepo,
    GradeService? gradeSvc,
    HomeworkService? homeworkSvc,
    AnnouncementService? announcementSvc,
    VoteService? voteSvc,
  })  : _authRepo = authRepo ?? AuthRepository(),
        _userRepo = userRepo ?? UserRepository(),
        _classRepo = classRepo ?? ClassRepository(),
        _gradeSvc = gradeSvc ?? GradeService(),
        _homeworkSvc = homeworkSvc ?? HomeworkService(),
        _announcementSvc = announcementSvc ?? AnnouncementService(),
        _voteSvc = voteSvc ?? VoteService();

  String get _uid => _authRepo.currentUid ?? '';

  Future<StudentDashboardData> loadStudentDashboard({
    String? overrideUid,
  }) async {
    final uid = overrideUid ?? _uid;
    if (uid.isEmpty) {
      return StudentDashboardData(
          user: UserModel(uid: '', name: '', email: '', role: UserRole.student));
    }

    final user = await _userRepo.getUser(uid);
    if (user == null) {
      return StudentDashboardData(
          user: UserModel(uid: uid, name: '', email: '', role: UserRole.student));
    }

    ClassModel? primaryClass;
    if (user.classIds.isNotEmpty) {
      primaryClass = await _classRepo.getClass(user.classIds.first);
    }

    final grades = await _gradeSvc.getStudentGrades(uid);
    final announcements =
        await _announcementSvc.fetchForAudience(Audience.students);
    final homework = await _homeworkSvc.getForClasses(user.classIds);
    final votes = await _voteSvc.fetchActive();

    return StudentDashboardData(
      user: user,
      primaryClass: primaryClass,
      grades: grades,
      announcements: announcements,
      homework: homework,
      activeVotes: votes,
    );
  }

  Future<TeacherDashboardData> loadTeacherDashboard({
    String? overrideUid,
  }) async {
    final uid = overrideUid ?? _uid;
    if (uid.isEmpty) {
      return TeacherDashboardData(
          user: UserModel(uid: '', name: '', email: '', role: UserRole.teacher));
    }

    final user = await _userRepo.getUser(uid);
    if (user == null) {
      return TeacherDashboardData(
          user: UserModel(uid: uid, name: '', email: '', role: UserRole.teacher));
    }

    final classes = user.classIds.isNotEmpty
        ? await _classRepo.getClassesByIds(user.classIds)
        : <ClassModel>[];

    List<UserModel> students = [];
    List<UserModel> parents = [];
    List<GradeModel> grades = [];
    if (classes.isNotEmpty) {
      final first = classes.first;
      students = await _userRepo.getUsersByIds(first.studentUids);
      parents = await _userRepo.getUsersByIds(first.parentUids);
      grades = await _gradeSvc.getClassGrades(first.id);
    }

    final announcements = await _announcementSvc.fetchAll();
    final homework = await _homeworkSvc.getByTeacher(uid);

    return TeacherDashboardData(
      user: user,
      classes: classes,
      studentsInFirstClass: students,
      parentsInFirstClass: parents,
      gradesInFirstClass: grades,
      announcements: announcements,
      homework: homework,
    );
  }

  Future<ParentDashboardData> loadParentDashboard({
    String? overrideUid,
  }) async {
    final uid = overrideUid ?? _uid;
    if (uid.isEmpty) {
      return ParentDashboardData(
          user: UserModel(uid: '', name: '', email: '', role: UserRole.parent));
    }

    final user = await _userRepo.getUser(uid);
    if (user == null) {
      return ParentDashboardData(
          user: UserModel(uid: uid, name: '', email: '', role: UserRole.parent));
    }

    ClassModel? childClass;
    String childUid = '';
    List<GradeModel> childGrades = [];

    if (user.children.isNotEmpty) {
      final childInfo = user.children.first;
      if (childInfo.classId.isNotEmpty) {
        childClass = await _classRepo.getClass(childInfo.classId);
      }

      // Find child's UID by name among students
      final allStudents = await _userRepo.getAllByRole(UserRole.student);
      final match =
          allStudents.where((s) => s.name == childInfo.childName).toList();
      if (match.isNotEmpty) {
        childUid = match.first.uid;
        childGrades = await _gradeSvc.getStudentGrades(childUid);
      }
    }

    final announcements =
        await _announcementSvc.fetchForAudience(Audience.parents);
    final votes = await _voteSvc.fetchActive();

    return ParentDashboardData(
      user: user,
      childClass: childClass,
      childUid: childUid,
      childGrades: childGrades,
      announcements: announcements,
      activeVotes: votes,
    );
  }

  Future<PrincipalDashboardData> loadPrincipalDashboard({
    String? overrideUid,
  }) async {
    final uid = overrideUid ?? _uid;
    if (uid.isEmpty) {
      return PrincipalDashboardData(
          user: UserModel(
              uid: '', name: '', email: '', role: UserRole.principal));
    }

    final user = await _userRepo.getUser(uid);
    if (user == null) {
      return PrincipalDashboardData(
          user: UserModel(
              uid: uid, name: '', email: '', role: UserRole.principal));
    }

    final teacherCount = await _userRepo.countByRole(UserRole.teacher);
    final studentCount = await _userRepo.countByRole(UserRole.student);
    final allClasses = await _classRepo.getAllClasses();
    final teachers = await _userRepo.getAllByRole(UserRole.teacher);
    final parents = await _userRepo.getAllByRole(UserRole.parent);
    final allGrades = await _gradeSvc.getAllGrades();
    final subjectAverages = _gradeSvc.computeSubjectAverages(allGrades);
    final announcements = await _announcementSvc.fetchAll();
    final votes = await _voteSvc.fetchActive();

    return PrincipalDashboardData(
      user: user,
      teacherCount: teacherCount,
      studentCount: studentCount,
      classCount: allClasses.length,
      teachers: teachers,
      allClasses: allClasses,
      parents: parents,
      allGrades: allGrades,
      subjectAverages: subjectAverages,
      announcements: announcements,
      activeVotes: votes,
    );
  }
}
