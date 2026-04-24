import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/class_model.dart';
import '../models/grade_model.dart';
import '../models/announcement_model.dart';
import '../models/homework_model.dart';
import '../models/vote_model.dart';
import '../models/audience.dart';
import '../models/behavior_point.dart';
import '../models/attendance_record.dart';
import '../models/story_post.dart';
import '../models/activity_event.dart';
import '../models/content_item.dart';
import '../models/child_info.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/class_repository.dart';
import 'grade_service.dart';
import 'homework_service.dart';
import 'announcement_service.dart';
import 'vote_service.dart';
import 'behavior_service.dart';
import 'attendance_service.dart';
import 'story_service.dart';
import 'activity_service.dart';
import 'content_service.dart';

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
  final List<StoryPost> storyPosts;
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
    this.storyPosts = const [],
    this.activityFeed = const [],
    this.contentItems = const [],
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
  final List<BehaviorPoint> classBehavior;
  final List<AttendanceRecord> todayAttendance;
  final List<StoryPost> classStory;
  final List<ActivityEvent> activityFeed;

  const TeacherDashboardData({
    required this.user,
    this.classes = const [],
    this.studentsInFirstClass = const [],
    this.parentsInFirstClass = const [],
    this.gradesInFirstClass = const [],
    this.announcements = const [],
    this.homework = const [],
    this.classBehavior = const [],
    this.todayAttendance = const [],
    this.classStory = const [],
    this.activityFeed = const [],
  });
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
  final List<StoryPost> storyPosts;
  final List<ActivityEvent> activityFeed;
  final List<ContentItem> contentItems;

  const ParentDashboardData({
    required this.user,
    this.childrenData = const [],
    this.announcements = const [],
    this.activeVotes = const [],
    this.storyPosts = const [],
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

/// Orchestrates data loading for all dashboards.
class DashboardService {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final ClassRepository _classRepo;
  final GradeService _gradeSvc;
  final HomeworkService _homeworkSvc;
  final AnnouncementService _announcementSvc;
  final VoteService _voteSvc;
  final BehaviorService _behaviorSvc;
  final AttendanceService _attendanceSvc;
  final StoryService _storySvc;
  final ActivityService _activitySvc;
  final ContentService _contentSvc;

  DashboardService({
    AuthRepository? authRepo,
    UserRepository? userRepo,
    ClassRepository? classRepo,
    GradeService? gradeSvc,
    HomeworkService? homeworkSvc,
    AnnouncementService? announcementSvc,
    VoteService? voteSvc,
    BehaviorService? behaviorSvc,
    AttendanceService? attendanceSvc,
    StoryService? storySvc,
    ActivityService? activitySvc,
    ContentService? contentSvc,
  })  : _authRepo = authRepo ?? AuthRepository(),
        _userRepo = userRepo ?? UserRepository(),
        _classRepo = classRepo ?? ClassRepository(),
        _gradeSvc = gradeSvc ?? GradeService(),
        _homeworkSvc = homeworkSvc ?? HomeworkService(),
        _announcementSvc = announcementSvc ?? AnnouncementService(),
        _voteSvc = voteSvc ?? VoteService(),
        _behaviorSvc = behaviorSvc ?? BehaviorService(),
        _attendanceSvc = attendanceSvc ?? AttendanceService(),
        _storySvc = storySvc ?? StoryService(),
        _activitySvc = activitySvc ?? ActivityService(),
        _contentSvc = contentSvc ?? ContentService();

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
    final behaviorPoints = await _behaviorSvc.getStudentPoints(uid);
    final behaviorScore = _behaviorSvc.computeScore(behaviorPoints);
    final attendance = await _attendanceSvc.getStudentAttendance(uid);
    final storyPosts = await _storySvc.getStoriesForClasses(user.classIds);
    final activityFeed = await _activitySvc.getUserFeed(uid);
    final contentItems = await _contentSvc.fetchAll();

    return StudentDashboardData(
      user: user,
      primaryClass: primaryClass,
      grades: grades,
      announcements: announcements,
      homework: homework,
      activeVotes: votes,
      behaviorPoints: behaviorPoints,
      behaviorScore: behaviorScore,
      attendance: attendance,
      storyPosts: storyPosts,
      activityFeed: activityFeed,
      contentItems: contentItems,
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
    List<BehaviorPoint> classBehavior = [];
    List<AttendanceRecord> todayAttendance = [];
    List<StoryPost> classStory = [];
    if (classes.isNotEmpty) {
      final first = classes.first;
      students = await _userRepo.getUsersByIds(first.studentUids);
      parents = await _userRepo.getUsersByIds(first.parentUids);
      grades = await _gradeSvc.getClassGrades(first.id);
      classBehavior = await _behaviorSvc.getClassPoints(first.id);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      todayAttendance =
          await _attendanceSvc.getClassAttendance(first.id, today);
      classStory = await _storySvc.getClassStory(first.id);
    }

    final announcements = await _announcementSvc.fetchAll();
    final homework = await _homeworkSvc.getByTeacher(uid);
    final activityFeed = classes.isNotEmpty
        ? await _activitySvc.getClassFeed(classes.first.id)
        : <ActivityEvent>[];

    return TeacherDashboardData(
      user: user,
      classes: classes,
      studentsInFirstClass: students,
      parentsInFirstClass: parents,
      gradesInFirstClass: grades,
      announcements: announcements,
      homework: homework,
      classBehavior: classBehavior,
      todayAttendance: todayAttendance,
      classStory: classStory,
      activityFeed: activityFeed,
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

    // Build data for each child (multi-child support)
    final allStudents = await _userRepo.getAllByRole(UserRole.student);
    final childrenData = <ChildDashboardData>[];
    final classIds = <String>{};

    for (final childInfo in user.children) {
      ClassModel? childClass;
      if (childInfo.classId.isNotEmpty) {
        childClass = await _classRepo.getClass(childInfo.classId);
        classIds.add(childInfo.classId);
      }

      String childUid = '';
      List<GradeModel> childGrades = [];
      List<BehaviorPoint> childBehavior = [];
      List<AttendanceRecord> childAttendance = [];
      int behaviorScore = 0;

      final match =
          allStudents.where((s) => s.name == childInfo.childName).toList();
      if (match.isNotEmpty) {
        childUid = match.first.uid;
        childGrades = await _gradeSvc.getStudentGrades(childUid);
        childBehavior = await _behaviorSvc.getStudentPoints(childUid);
        behaviorScore = _behaviorSvc.computeScore(childBehavior);
        childAttendance = await _attendanceSvc.getStudentAttendance(childUid);
      }

      childrenData.add(ChildDashboardData(
        info: childInfo,
        childUid: childUid,
        childClass: childClass,
        grades: childGrades,
        behaviorPoints: childBehavior,
        behaviorScore: behaviorScore,
        attendance: childAttendance,
      ));
    }

    final announcements =
        await _announcementSvc.fetchForAudience(Audience.parents);
    final votes = await _voteSvc.fetchActive();
    final storyPosts =
        await _storySvc.getStoriesForClasses(classIds.toList());
    final activityFeed = childrenData.isNotEmpty && childrenData.first.childUid.isNotEmpty
        ? await _activitySvc.getUserFeed(childrenData.first.childUid)
        : <ActivityEvent>[];
    final contentItems = await _contentSvc.fetchAll();

    return ParentDashboardData(
      user: user,
      childrenData: childrenData,
      announcements: announcements,
      activeVotes: votes,
      storyPosts: storyPosts,
      activityFeed: activityFeed,
      contentItems: contentItems,
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
    final activityFeed = await _activitySvc.getSchoolFeed();

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
      activityFeed: activityFeed,
    );
  }
}
