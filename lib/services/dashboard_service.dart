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
/// Uses Future.wait for parallel queries to minimize Firestore round-trips.
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

  // In-memory cache to avoid redundant loads within the same session
  StudentDashboardData? _cachedStudentData;
  TeacherDashboardData? _cachedTeacherData;
  ParentDashboardData? _cachedParentData;
  PrincipalDashboardData? _cachedPrincipalData;

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

  /// Forces fresh data on next load.
  void invalidateCache() {
    _cachedStudentData = null;
    _cachedTeacherData = null;
    _cachedParentData = null;
    _cachedPrincipalData = null;
  }

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

    final user = await _userRepo.getUser(uid);
    if (user == null) {
      return StudentDashboardData(
          user: UserModel(uid: uid, name: '', email: '', role: UserRole.student));
    }

    // Kick off class fetch (needed before homework)
    final classFuture = user.classIds.isNotEmpty
        ? _classRepo.getClass(user.classIds.first)
        : Future.value(null);

    // Fire ALL independent queries in parallel (single round-trip batch)
    final results = await Future.wait([
      classFuture,                                                // 0
      _gradeSvc.getStudentGrades(uid),                            // 1
      _announcementSvc.fetchForAudience(Audience.students),       // 2
      _homeworkSvc.getForClasses(user.classIds),                  // 3
      _voteSvc.fetchActive(),                                     // 4
      _behaviorSvc.getStudentPoints(uid),                         // 5
      _attendanceSvc.getStudentAttendance(uid),                   // 6
      _storySvc.getStoriesForClasses(user.classIds),              // 7
      _activitySvc.getUserFeed(uid, limit: 10),                   // 8
      _contentSvc.fetchAll(),                                     // 9
    ]);

    final behaviorPoints = results[5] as List<BehaviorPoint>;

    final data = StudentDashboardData(
      user: user,
      primaryClass: results[0] as ClassModel?,
      grades: results[1] as List<GradeModel>,
      announcements: results[2] as List<AnnouncementModel>,
      homework: results[3] as List<HomeworkModel>,
      activeVotes: results[4] as List<VoteModel>,
      behaviorPoints: behaviorPoints,
      behaviorScore: _behaviorSvc.computeScore(behaviorPoints),
      attendance: results[6] as List<AttendanceRecord>,
      storyPosts: results[7] as List<StoryPost>,
      activityFeed: results[8] as List<ActivityEvent>,
      contentItems: results[9] as List<ContentItem>,
    );

    _cachedStudentData = data;
    return data;
  }

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

    final user = await _userRepo.getUser(uid);
    if (user == null) {
      return TeacherDashboardData(
          user: UserModel(uid: uid, name: '', email: '', role: UserRole.teacher));
    }

    final classes = user.classIds.isNotEmpty
        ? await _classRepo.getClassesByIds(user.classIds)
        : <ClassModel>[];

    if (classes.isEmpty) {
      // Only fetch announcements and homework — no class-dependent data
      final results = await Future.wait([
        _announcementSvc.fetchAll(),
        _homeworkSvc.getByTeacher(uid),
      ]);
      final data = TeacherDashboardData(
        user: user,
        announcements: results[0] as List<AnnouncementModel>,
        homework: results[1] as List<HomeworkModel>,
      );
      _cachedTeacherData = data;
      return data;
    }

    final first = classes.first;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // All queries in parallel
    final results = await Future.wait([
      _userRepo.getUsersByIds(first.studentUids),                 // 0
      _userRepo.getUsersByIds(first.parentUids),                  // 1
      _gradeSvc.getClassGrades(first.id),                         // 2
      _behaviorSvc.getClassPoints(first.id),                      // 3
      _attendanceSvc.getClassAttendance(first.id, today),         // 4
      _storySvc.getClassStory(first.id),                          // 5
      _announcementSvc.fetchAll(),                                // 6
      _homeworkSvc.getByTeacher(uid),                             // 7
      _activitySvc.getClassFeed(first.id, limit: 10),            // 8
    ]);

    final data = TeacherDashboardData(
      user: user,
      classes: classes,
      studentsInFirstClass: results[0] as List<UserModel>,
      parentsInFirstClass: results[1] as List<UserModel>,
      gradesInFirstClass: results[2] as List<GradeModel>,
      announcements: results[6] as List<AnnouncementModel>,
      homework: results[7] as List<HomeworkModel>,
      classBehavior: results[3] as List<BehaviorPoint>,
      todayAttendance: results[4] as List<AttendanceRecord>,
      classStory: results[5] as List<StoryPost>,
      activityFeed: results[8] as List<ActivityEvent>,
    );

    _cachedTeacherData = data;
    return data;
  }

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

    final user = await _userRepo.getUser(uid);
    if (user == null) {
      return ParentDashboardData(
          user: UserModel(uid: uid, name: '', email: '', role: UserRole.parent));
    }

    // Build child data — each child's UID should be stored on the parent doc
    // but as a fallback we search by name. Use a single query for all children.
    final childrenData = <ChildDashboardData>[];
    final classIds = <String>{};

    // Batch all child class fetches in parallel
    final classFutures = <Future<ClassModel?>>[];
    for (final childInfo in user.children) {
      if (childInfo.classId.isNotEmpty) {
        classFutures.add(_classRepo.getClass(childInfo.classId));
        classIds.add(childInfo.classId);
      } else {
        classFutures.add(Future.value(null));
      }
    }
    final childClasses = await Future.wait(classFutures);

    // Fetch all students once (not per child) to resolve names → UIDs
    List<UserModel>? allStudents;
    if (user.children.isNotEmpty) {
      allStudents = await _userRepo.getAllByRole(UserRole.student);
    }

    // For each child, fire grades + behavior + attendance in parallel
    for (int i = 0; i < user.children.length; i++) {
      final childInfo = user.children[i];
      final childClass = childClasses[i];
      String childUid = '';

      if (allStudents != null) {
        final match = allStudents.where((s) => s.name == childInfo.childName);
        if (match.isNotEmpty) childUid = match.first.uid;
      }

      if (childUid.isNotEmpty) {
        final childResults = await Future.wait([
          _gradeSvc.getStudentGrades(childUid),
          _behaviorSvc.getStudentPoints(childUid),
          _attendanceSvc.getStudentAttendance(childUid),
        ]);
        final bp = childResults[1] as List<BehaviorPoint>;
        childrenData.add(ChildDashboardData(
          info: childInfo,
          childUid: childUid,
          childClass: childClass,
          grades: childResults[0] as List<GradeModel>,
          behaviorPoints: bp,
          behaviorScore: _behaviorSvc.computeScore(bp),
          attendance: childResults[2] as List<AttendanceRecord>,
        ));
      } else {
        childrenData.add(ChildDashboardData(
          info: childInfo,
          childClass: childClass,
        ));
      }
    }

    // Shared data — all in parallel
    final sharedResults = await Future.wait([
      _announcementSvc.fetchForAudience(Audience.parents),
      _voteSvc.fetchActive(),
      _storySvc.getStoriesForClasses(classIds.toList()),
      childrenData.isNotEmpty && childrenData.first.childUid.isNotEmpty
          ? _activitySvc.getUserFeed(childrenData.first.childUid, limit: 10)
          : Future.value(<ActivityEvent>[]),
      _contentSvc.fetchAll(),
    ]);

    final data = ParentDashboardData(
      user: user,
      childrenData: childrenData,
      announcements: sharedResults[0] as List<AnnouncementModel>,
      activeVotes: sharedResults[1] as List<VoteModel>,
      storyPosts: sharedResults[2] as List<StoryPost>,
      activityFeed: sharedResults[3] as List<ActivityEvent>,
      contentItems: sharedResults[4] as List<ContentItem>,
    );

    _cachedParentData = data;
    return data;
  }

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

    final user = await _userRepo.getUser(uid);
    if (user == null) {
      return PrincipalDashboardData(
          user: UserModel(
              uid: uid, name: '', email: '', role: UserRole.principal));
    }

    // All independent queries in parallel
    final results = await Future.wait([
      _userRepo.getAllByRole(UserRole.teacher),    // 0 - also gives count
      _userRepo.getAllByRole(UserRole.student),     // 1 - also gives count
      _classRepo.getAllClasses(),                   // 2
      _userRepo.getAllByRole(UserRole.parent),      // 3
      _gradeSvc.getAllGrades(),                     // 4
      _announcementSvc.fetchAll(),                  // 5
      _voteSvc.fetchActive(),                       // 6
      _activitySvc.getSchoolFeed(limit: 20),        // 7
    ]);

    final teachers = results[0] as List<UserModel>;
    final students = results[1] as List<UserModel>;
    final allClasses = results[2] as List<ClassModel>;
    final allGrades = results[4] as List<GradeModel>;

    final data = PrincipalDashboardData(
      user: user,
      teacherCount: teachers.length,
      studentCount: students.length,
      classCount: allClasses.length,
      teachers: teachers,
      allClasses: allClasses,
      parents: results[3] as List<UserModel>,
      allGrades: allGrades,
      subjectAverages: _gradeSvc.computeSubjectAverages(allGrades),
      announcements: results[5] as List<AnnouncementModel>,
      activeVotes: results[6] as List<VoteModel>,
      activityFeed: results[7] as List<ActivityEvent>,
    );

    _cachedPrincipalData = data;
    return data;
  }
}
