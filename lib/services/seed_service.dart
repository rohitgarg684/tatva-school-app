import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds Firestore with demo data for all collections.
/// Designed to be idempotent: checks if data already exists before seeding.
class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isAlreadySeeded() async {
    final snap = await _db.collection('users').limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<void> seedAll() async {
    await _seedUsers();
    await _seedClasses();
    await _seedStudents();
    await _seedGrades();
    await _seedHomework();
    await _seedAnnouncements();
    await _seedVotes();
    await _seedMessages();
  }

  // ─── USERS ─────────────────────────────────────────────────────────────────

  Future<void> _seedUsers() async {
    final users = [
      {
        'uid': 'teacher_priya',
        'name': 'Mrs. Priya Sharma',
        'email': 'priya.sharma@tatva.edu',
        'role': 'Teacher',
        'classIds': ['class_math8a', 'class_math9b', 'class_math7a'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'teacher_rahul',
        'name': 'Mr. Rahul Verma',
        'email': 'rahul.verma@tatva.edu',
        'role': 'Teacher',
        'classIds': ['class_sci8a', 'class_sci9b'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'teacher_anita',
        'name': 'Ms. Anita Desai',
        'email': 'anita.desai@tatva.edu',
        'role': 'Teacher',
        'classIds': ['class_eng8a', 'class_eng9b'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'teacher_vikram',
        'name': 'Mr. Vikram Rao',
        'email': 'vikram.rao@tatva.edu',
        'role': 'Teacher',
        'classIds': ['class_hist8a'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'student_arjun',
        'name': 'Arjun Mehta',
        'email': 'arjun.mehta@tatva.edu',
        'role': 'Student',
        'classIds': ['class_math8a', 'class_sci8a', 'class_eng8a', 'class_hist8a'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'student_sneha',
        'name': 'Sneha Agarwal',
        'email': 'sneha.agarwal@tatva.edu',
        'role': 'Student',
        'classIds': ['class_math8a', 'class_sci8a', 'class_eng8a'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'student_ravi',
        'name': 'Ravi Kumar',
        'email': 'ravi.kumar@tatva.edu',
        'role': 'Student',
        'classIds': ['class_math8a', 'class_sci8a'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'student_divya',
        'name': 'Divya Pillai',
        'email': 'divya.pillai@tatva.edu',
        'role': 'Student',
        'classIds': ['class_math9b', 'class_sci9b', 'class_eng9b'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'student_karan',
        'name': 'Karan Singh',
        'email': 'karan.singh@tatva.edu',
        'role': 'Student',
        'classIds': ['class_math9b', 'class_sci9b'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'parent_suresh',
        'name': 'Mr. Suresh Mehta',
        'email': 'suresh.mehta@tatva.edu',
        'role': 'Parent',
        'classIds': ['class_math8a'],
        'children': [
          {
            'childName': 'Arjun Mehta',
            'classId': 'class_math8a',
            'className': 'Grade 8 — Section A',
            'subject': 'Mathematics',
            'teacherName': 'Mrs. Priya Sharma',
            'teacherUid': 'teacher_priya',
            'teacherEmail': 'priya.sharma@tatva.edu',
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'parent_kavitha',
        'name': 'Mrs. Kavitha Agarwal',
        'email': 'kavitha.agarwal@tatva.edu',
        'role': 'Parent',
        'classIds': ['class_math8a'],
        'children': [
          {
            'childName': 'Sneha Agarwal',
            'classId': 'class_math8a',
            'className': 'Grade 8 — Section A',
            'subject': 'Mathematics',
            'teacherName': 'Mrs. Priya Sharma',
            'teacherUid': 'teacher_priya',
            'teacherEmail': 'priya.sharma@tatva.edu',
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'parent_deepak',
        'name': 'Mr. Deepak Kumar',
        'email': 'deepak.kumar@tatva.edu',
        'role': 'Parent',
        'classIds': ['class_math8a'],
        'children': [
          {
            'childName': 'Ravi Kumar',
            'classId': 'class_math8a',
            'className': 'Grade 8 — Section A',
            'subject': 'Mathematics',
            'teacherName': 'Mrs. Priya Sharma',
            'teacherUid': 'teacher_priya',
            'teacherEmail': 'priya.sharma@tatva.edu',
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'parent_nisha',
        'name': 'Mrs. Nisha Pillai',
        'email': 'nisha.pillai@tatva.edu',
        'role': 'Parent',
        'classIds': ['class_math9b'],
        'children': [
          {
            'childName': 'Divya Pillai',
            'classId': 'class_math9b',
            'className': 'Grade 9 — Section B',
            'subject': 'Mathematics',
            'teacherName': 'Mrs. Priya Sharma',
            'teacherUid': 'teacher_priya',
            'teacherEmail': 'priya.sharma@tatva.edu',
          }
        ],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'principal_anjali',
        'name': 'Dr. Anjali Nair',
        'email': 'principal@tatva.edu',
        'role': 'Principal',
        'classIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _db.batch();
    for (final u in users) {
      batch.set(_db.collection('users').doc(u['uid'] as String), u);
    }
    await batch.commit();
  }

  // ─── CLASSES ───────────────────────────────────────────────────────────────

  Future<void> _seedClasses() async {
    final classes = [
      {
        'id': 'class_math8a',
        'name': 'Grade 8 — Section A',
        'subject': 'Mathematics',
        'teacherUid': 'teacher_priya',
        'teacherName': 'Mrs. Priya Sharma',
        'teacherEmail': 'priya.sharma@tatva.edu',
        'classCode': 'MATH312',
        'studentUids': ['student_arjun', 'student_sneha', 'student_ravi'],
        'parentUids': ['parent_suresh', 'parent_kavitha', 'parent_deepak'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'class_math9b',
        'name': 'Grade 9 — Section B',
        'subject': 'Mathematics',
        'teacherUid': 'teacher_priya',
        'teacherName': 'Mrs. Priya Sharma',
        'teacherEmail': 'priya.sharma@tatva.edu',
        'classCode': 'MATH498',
        'studentUids': ['student_divya', 'student_karan'],
        'parentUids': ['parent_nisha'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'class_math7a',
        'name': 'Grade 7 — Section A',
        'subject': 'Mathematics',
        'teacherUid': 'teacher_priya',
        'teacherName': 'Mrs. Priya Sharma',
        'teacherEmail': 'priya.sharma@tatva.edu',
        'classCode': 'MATH201',
        'studentUids': [],
        'parentUids': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'class_sci8a',
        'name': 'Grade 8 — Section A',
        'subject': 'Science',
        'teacherUid': 'teacher_rahul',
        'teacherName': 'Mr. Rahul Verma',
        'teacherEmail': 'rahul.verma@tatva.edu',
        'classCode': 'SCI312',
        'studentUids': ['student_arjun', 'student_sneha', 'student_ravi'],
        'parentUids': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'class_sci9b',
        'name': 'Grade 9 — Section B',
        'subject': 'Science',
        'teacherUid': 'teacher_rahul',
        'teacherName': 'Mr. Rahul Verma',
        'teacherEmail': 'rahul.verma@tatva.edu',
        'classCode': 'SCI498',
        'studentUids': ['student_divya', 'student_karan'],
        'parentUids': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'class_eng8a',
        'name': 'Grade 8 — Section A',
        'subject': 'English',
        'teacherUid': 'teacher_anita',
        'teacherName': 'Ms. Anita Desai',
        'teacherEmail': 'anita.desai@tatva.edu',
        'classCode': 'ENG312',
        'studentUids': ['student_arjun', 'student_sneha'],
        'parentUids': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'class_eng9b',
        'name': 'Grade 9 — Section B',
        'subject': 'English',
        'teacherUid': 'teacher_anita',
        'teacherName': 'Ms. Anita Desai',
        'teacherEmail': 'anita.desai@tatva.edu',
        'classCode': 'ENG498',
        'studentUids': ['student_divya'],
        'parentUids': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'class_hist8a',
        'name': 'Grade 8 — Section A',
        'subject': 'History',
        'teacherUid': 'teacher_vikram',
        'teacherName': 'Mr. Vikram Rao',
        'teacherEmail': 'vikram.rao@tatva.edu',
        'classCode': 'HIST312',
        'studentUids': ['student_arjun'],
        'parentUids': [],
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _db.batch();
    for (final c in classes) {
      batch.set(_db.collection('classes').doc(c['id'] as String), c);
    }
    await batch.commit();
  }

  // ─── STUDENTS (record-only) ────────────────────────────────────────────────

  Future<void> _seedStudents() async {
    final students = [
      {
        'id': 'rec_arjun',
        'name': 'Arjun Mehta',
        'rollNumber': '8A-01',
        'grade': '8',
        'section': 'A',
        'parentName': 'Mr. Suresh Mehta',
        'parentPhone': '+91 9876543210',
        'classIds': ['class_math8a', 'class_sci8a', 'class_eng8a', 'class_hist8a'],
        'enrolledBy': 'principal_anjali',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'rec_sneha',
        'name': 'Sneha Agarwal',
        'rollNumber': '8A-02',
        'grade': '8',
        'section': 'A',
        'parentName': 'Mrs. Kavitha Agarwal',
        'parentPhone': '+91 9876543211',
        'classIds': ['class_math8a', 'class_sci8a', 'class_eng8a'],
        'enrolledBy': 'principal_anjali',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'rec_ravi',
        'name': 'Ravi Kumar',
        'rollNumber': '8A-03',
        'grade': '8',
        'section': 'A',
        'parentName': 'Mr. Deepak Kumar',
        'parentPhone': '+91 9876543212',
        'classIds': ['class_math8a', 'class_sci8a'],
        'enrolledBy': 'teacher_priya',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'rec_divya',
        'name': 'Divya Pillai',
        'rollNumber': '9B-01',
        'grade': '9',
        'section': 'B',
        'parentName': 'Mrs. Nisha Pillai',
        'parentPhone': '+91 9876543213',
        'classIds': ['class_math9b', 'class_sci9b', 'class_eng9b'],
        'enrolledBy': 'principal_anjali',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'rec_karan',
        'name': 'Karan Singh',
        'rollNumber': '9B-02',
        'grade': '9',
        'section': 'B',
        'parentName': 'Mr. Harpreet Singh',
        'parentPhone': '+91 9876543214',
        'classIds': ['class_math9b', 'class_sci9b'],
        'enrolledBy': 'teacher_priya',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _db.batch();
    for (final s in students) {
      batch.set(_db.collection('students').doc(s['id'] as String), s);
    }
    await batch.commit();
  }

  // ─── GRADES ────────────────────────────────────────────────────────────────

  Future<void> _seedGrades() async {
    final grades = [
      // Arjun's grades
      {'studentUid': 'student_arjun', 'studentName': 'Arjun Mehta', 'classId': 'class_math8a', 'subject': 'Mathematics', 'assessmentName': 'Unit Test 1', 'score': 42.0, 'total': 50.0, 'teacherUid': 'teacher_priya'},
      {'studentUid': 'student_arjun', 'studentName': 'Arjun Mehta', 'classId': 'class_math8a', 'subject': 'Mathematics', 'assessmentName': 'Unit Test 2', 'score': 38.0, 'total': 50.0, 'teacherUid': 'teacher_priya'},
      {'studentUid': 'student_arjun', 'studentName': 'Arjun Mehta', 'classId': 'class_math8a', 'subject': 'Mathematics', 'assessmentName': 'Mid-Term', 'score': 76.0, 'total': 100.0, 'teacherUid': 'teacher_priya'},
      {'studentUid': 'student_arjun', 'studentName': 'Arjun Mehta', 'classId': 'class_sci8a', 'subject': 'Science', 'assessmentName': 'Unit Test 1', 'score': 40.0, 'total': 50.0, 'teacherUid': 'teacher_rahul'},
      {'studentUid': 'student_arjun', 'studentName': 'Arjun Mehta', 'classId': 'class_sci8a', 'subject': 'Science', 'assessmentName': 'Lab Assessment', 'score': 18.0, 'total': 20.0, 'teacherUid': 'teacher_rahul'},
      {'studentUid': 'student_arjun', 'studentName': 'Arjun Mehta', 'classId': 'class_eng8a', 'subject': 'English', 'assessmentName': 'Essay', 'score': 17.0, 'total': 20.0, 'teacherUid': 'teacher_anita'},
      {'studentUid': 'student_arjun', 'studentName': 'Arjun Mehta', 'classId': 'class_eng8a', 'subject': 'English', 'assessmentName': 'Mid-Term', 'score': 82.0, 'total': 100.0, 'teacherUid': 'teacher_anita'},
      {'studentUid': 'student_arjun', 'studentName': 'Arjun Mehta', 'classId': 'class_hist8a', 'subject': 'History', 'assessmentName': 'Project', 'score': 45.0, 'total': 50.0, 'teacherUid': 'teacher_vikram'},
      // Sneha's grades
      {'studentUid': 'student_sneha', 'studentName': 'Sneha Agarwal', 'classId': 'class_math8a', 'subject': 'Mathematics', 'assessmentName': 'Unit Test 1', 'score': 47.0, 'total': 50.0, 'teacherUid': 'teacher_priya'},
      {'studentUid': 'student_sneha', 'studentName': 'Sneha Agarwal', 'classId': 'class_math8a', 'subject': 'Mathematics', 'assessmentName': 'Unit Test 2', 'score': 44.0, 'total': 50.0, 'teacherUid': 'teacher_priya'},
      {'studentUid': 'student_sneha', 'studentName': 'Sneha Agarwal', 'classId': 'class_math8a', 'subject': 'Mathematics', 'assessmentName': 'Mid-Term', 'score': 91.0, 'total': 100.0, 'teacherUid': 'teacher_priya'},
      {'studentUid': 'student_sneha', 'studentName': 'Sneha Agarwal', 'classId': 'class_sci8a', 'subject': 'Science', 'assessmentName': 'Unit Test 1', 'score': 45.0, 'total': 50.0, 'teacherUid': 'teacher_rahul'},
      // Ravi's grades
      {'studentUid': 'student_ravi', 'studentName': 'Ravi Kumar', 'classId': 'class_math8a', 'subject': 'Mathematics', 'assessmentName': 'Unit Test 1', 'score': 35.0, 'total': 50.0, 'teacherUid': 'teacher_priya'},
      {'studentUid': 'student_ravi', 'studentName': 'Ravi Kumar', 'classId': 'class_math8a', 'subject': 'Mathematics', 'assessmentName': 'Mid-Term', 'score': 68.0, 'total': 100.0, 'teacherUid': 'teacher_priya'},
      // Divya's grades
      {'studentUid': 'student_divya', 'studentName': 'Divya Pillai', 'classId': 'class_math9b', 'subject': 'Mathematics', 'assessmentName': 'Unit Test 1', 'score': 46.0, 'total': 50.0, 'teacherUid': 'teacher_priya'},
      {'studentUid': 'student_divya', 'studentName': 'Divya Pillai', 'classId': 'class_sci9b', 'subject': 'Science', 'assessmentName': 'Unit Test 1', 'score': 43.0, 'total': 50.0, 'teacherUid': 'teacher_rahul'},
      // Karan's grades
      {'studentUid': 'student_karan', 'studentName': 'Karan Singh', 'classId': 'class_math9b', 'subject': 'Mathematics', 'assessmentName': 'Unit Test 1', 'score': 38.0, 'total': 50.0, 'teacherUid': 'teacher_priya'},
    ];

    final batch = _db.batch();
    for (final g in grades) {
      final ref = _db.collection('grades').doc();
      batch.set(ref, {
        ...g,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ─── HOMEWORK ──────────────────────────────────────────────────────────────

  Future<void> _seedHomework() async {
    final homework = [
      {
        'title': 'Quadratic Equations — Practice Set',
        'description': 'Solve exercises 5.1 to 5.4 from textbook. Show all steps.',
        'subject': 'Mathematics',
        'classId': 'class_math8a',
        'className': 'Grade 8 — Section A',
        'teacherUid': 'teacher_priya',
        'teacherName': 'Mrs. Priya Sharma',
        'dueDate': '2026-04-28',
        'submittedBy': ['student_arjun', 'student_sneha'],
      },
      {
        'title': 'Trigonometry Worksheet',
        'description': 'Complete the trigonometry identities worksheet handed out in class.',
        'subject': 'Mathematics',
        'classId': 'class_math8a',
        'className': 'Grade 8 — Section A',
        'teacherUid': 'teacher_priya',
        'teacherName': 'Mrs. Priya Sharma',
        'dueDate': '2026-04-30',
        'submittedBy': ['student_arjun'],
      },
      {
        'title': 'Statistics Project',
        'description': 'Collect data and create frequency distribution tables.',
        'subject': 'Mathematics',
        'classId': 'class_math8a',
        'className': 'Grade 8 — Section A',
        'teacherUid': 'teacher_priya',
        'teacherName': 'Mrs. Priya Sharma',
        'dueDate': '2026-05-05',
        'submittedBy': [],
      },
      {
        'title': 'Linear Equations Review',
        'description': 'Review chapter 3 and solve all end-of-chapter exercises.',
        'subject': 'Mathematics',
        'classId': 'class_math9b',
        'className': 'Grade 9 — Section B',
        'teacherUid': 'teacher_priya',
        'teacherName': 'Mrs. Priya Sharma',
        'dueDate': '2026-04-29',
        'submittedBy': ['student_divya'],
      },
      {
        'title': 'Photosynthesis Lab Report',
        'description': 'Write up the lab experiment results from last Friday.',
        'subject': 'Science',
        'classId': 'class_sci8a',
        'className': 'Grade 8 — Section A',
        'teacherUid': 'teacher_rahul',
        'teacherName': 'Mr. Rahul Verma',
        'dueDate': '2026-04-27',
        'submittedBy': ['student_arjun', 'student_sneha', 'student_ravi'],
      },
      {
        'title': 'Essay: My Favorite Book',
        'description': 'Write a 500-word essay on your favorite book and why it matters.',
        'subject': 'English',
        'classId': 'class_eng8a',
        'className': 'Grade 8 — Section A',
        'teacherUid': 'teacher_anita',
        'teacherName': 'Ms. Anita Desai',
        'dueDate': '2026-05-02',
        'submittedBy': [],
      },
    ];

    final batch = _db.batch();
    for (final h in homework) {
      final ref = _db.collection('homework').doc();
      batch.set(ref, {
        ...h,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ─── ANNOUNCEMENTS ─────────────────────────────────────────────────────────

  Future<void> _seedAnnouncements() async {
    final announcements = [
      {
        'title': 'Annual Sports Day',
        'body': 'Annual Sports Day is scheduled for May 15, 2026. All students must participate in at least one event. Registration forms are available at the front office.',
        'audience': 'Everyone',
        'classIds': [],
        'createdBy': 'principal_anjali',
        'createdByName': 'Dr. Anjali Nair',
        'createdByRole': 'Principal',
      },
      {
        'title': 'Parent-Teacher Meeting',
        'body': 'PTM is on April 30. Parents are requested to meet with the class teacher between 10 AM and 1 PM. Please bring your child\'s report card.',
        'audience': 'Parents',
        'classIds': [],
        'createdBy': 'principal_anjali',
        'createdByName': 'Dr. Anjali Nair',
        'createdByRole': 'Principal',
      },
      {
        'title': 'Math Olympiad Registration',
        'body': 'Registration for the National Math Olympiad is now open. Interested students can register with Mrs. Priya Sharma before May 5. Top performers will represent Tatva Academy.',
        'audience': 'Students',
        'classIds': [],
        'createdBy': 'teacher_priya',
        'createdByName': 'Mrs. Priya Sharma',
        'createdByRole': 'Teacher',
      },
      {
        'title': 'Library Book Return Reminder',
        'body': 'All library books must be returned by May 10, 2026. Students with overdue books will not be issued new ones until cleared.',
        'audience': 'Students',
        'classIds': [],
        'createdBy': 'principal_anjali',
        'createdByName': 'Dr. Anjali Nair',
        'createdByRole': 'Principal',
      },
      {
        'title': 'Science Fair Winners',
        'body': 'Congratulations to all participants! First place goes to Sneha Agarwal for her project on Renewable Energy. Results are posted on the notice board.',
        'audience': 'Everyone',
        'classIds': [],
        'createdBy': 'teacher_rahul',
        'createdByName': 'Mr. Rahul Verma',
        'createdByRole': 'Teacher',
      },
    ];

    final batch = _db.batch();
    for (final a in announcements) {
      final ref = _db.collection('announcements').doc();
      batch.set(ref, {
        ...a,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ─── VOTES ─────────────────────────────────────────────────────────────────

  Future<void> _seedVotes() async {
    final votes = [
      {
        'question': 'Should we have school on Saturday for extra classes?',
        'type': 'school_decision',
        'createdBy': 'principal_anjali',
        'createdByName': 'Dr. Anjali Nair',
        'createdByRole': 'Principal',
        'votes': {'school': 45, 'no_school': 120, 'undecided': 15},
        'voters': ['parent_suresh', 'parent_kavitha', 'parent_deepak'],
        'active': true,
      },
      {
        'question': 'Should the annual day theme be "Space Exploration" or "Heritage of India"?',
        'type': 'school_decision',
        'createdBy': 'principal_anjali',
        'createdByName': 'Dr. Anjali Nair',
        'createdByRole': 'Principal',
        'votes': {'school': 90, 'no_school': 65, 'undecided': 25},
        'voters': ['parent_suresh', 'parent_nisha'],
        'active': true,
      },
    ];

    final batch = _db.batch();
    for (final v in votes) {
      final ref = _db.collection('votes').doc();
      batch.set(ref, {
        ...v,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ─── MESSAGES ──────────────────────────────────────────────────────────────

  Future<void> _seedMessages() async {
    final convId = 'parent_suresh_teacher_priya';
    final messages = [
      {'text': 'Good morning Mrs. Sharma! I wanted to discuss Arjun\'s progress in mathematics.', 'senderUid': 'parent_suresh', 'receiverUid': 'teacher_priya', 'conversationId': convId},
      {'text': 'Good morning Mr. Mehta! Arjun has been doing well. His test scores have improved consistently.', 'senderUid': 'teacher_priya', 'receiverUid': 'parent_suresh', 'conversationId': convId},
      {'text': 'That\'s wonderful to hear! Are there any areas where he could improve?', 'senderUid': 'parent_suresh', 'receiverUid': 'teacher_priya', 'conversationId': convId},
      {'text': 'He should practice word problems more. I\'ll send some extra worksheets.', 'senderUid': 'teacher_priya', 'receiverUid': 'parent_suresh', 'conversationId': convId},
      {'text': 'Thank you so much! We\'ll make sure he works on those.', 'senderUid': 'parent_suresh', 'receiverUid': 'teacher_priya', 'conversationId': convId},
    ];

    final batch = _db.batch();
    for (int i = 0; i < messages.length; i++) {
      final ref = _db.collection('messages').doc();
      batch.set(ref, {
        ...messages[i],
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 4, 23, 9, 0 + i * 2),
        ),
      });
    }
    await batch.commit();
  }
}
