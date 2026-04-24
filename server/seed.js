const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

const FieldValue = admin.firestore.FieldValue;

const DEFAULT_PASSWORD = "Tatva@2026";

async function ensureAuthUser(uid, email, displayName) {
  try {
    await admin.auth().getUser(uid);
  } catch {
    await admin.auth().createUser({
      uid,
      email,
      password: DEFAULT_PASSWORD,
      displayName,
      emailVerified: true,
    });
    console.log(`  Auth: created ${email}`);
  }
}

async function seedUsers() {
  console.log("Seeding users...");
  const users = [
    { uid: "teacher_priya", name: "Mrs. Priya Sharma", email: "priya.sharma@tatva.edu", role: "Teacher", classIds: ["class_math8a", "class_math9b", "class_math7a"] },
    { uid: "teacher_rahul", name: "Mr. Rahul Verma", email: "rahul.verma@tatva.edu", role: "Teacher", classIds: ["class_sci8a", "class_sci9b"] },
    { uid: "teacher_anita", name: "Ms. Anita Desai", email: "anita.desai@tatva.edu", role: "Teacher", classIds: ["class_eng8a", "class_eng9b"] },
    { uid: "teacher_vikram", name: "Mr. Vikram Rao", email: "vikram.rao@tatva.edu", role: "Teacher", classIds: ["class_hist8a"] },
    { uid: "student_arjun", name: "Arjun Mehta", email: "arjun.mehta@tatva.edu", role: "Student", classIds: ["class_math8a", "class_sci8a", "class_eng8a", "class_hist8a"] },
    { uid: "student_sneha", name: "Sneha Agarwal", email: "sneha.agarwal@tatva.edu", role: "Student", classIds: ["class_math8a", "class_sci8a", "class_eng8a"] },
    { uid: "student_ravi", name: "Ravi Kumar", email: "ravi.kumar@tatva.edu", role: "Student", classIds: ["class_math8a", "class_sci8a"] },
    { uid: "student_divya", name: "Divya Pillai", email: "divya.pillai@tatva.edu", role: "Student", classIds: ["class_math9b", "class_sci9b", "class_eng9b"] },
    { uid: "student_karan", name: "Karan Singh", email: "karan.singh@tatva.edu", role: "Student", classIds: ["class_math9b", "class_sci9b"] },
    {
      uid: "parent_suresh", name: "Mr. Suresh Mehta", email: "suresh.mehta@tatva.edu", role: "Parent", classIds: ["class_math8a"],
      children: [{ childName: "Arjun Mehta", classId: "class_math8a", className: "Grade 8 — Section A", subject: "Mathematics", teacherName: "Mrs. Priya Sharma", teacherUid: "teacher_priya", teacherEmail: "priya.sharma@tatva.edu" }],
    },
    {
      uid: "parent_kavitha", name: "Mrs. Kavitha Agarwal", email: "kavitha.agarwal@tatva.edu", role: "Parent", classIds: ["class_math8a"],
      children: [{ childName: "Sneha Agarwal", classId: "class_math8a", className: "Grade 8 — Section A", subject: "Mathematics", teacherName: "Mrs. Priya Sharma", teacherUid: "teacher_priya", teacherEmail: "priya.sharma@tatva.edu" }],
    },
    {
      uid: "parent_deepak", name: "Mr. Deepak Kumar", email: "deepak.kumar@tatva.edu", role: "Parent", classIds: ["class_math8a"],
      children: [{ childName: "Ravi Kumar", classId: "class_math8a", className: "Grade 8 — Section A", subject: "Mathematics", teacherName: "Mrs. Priya Sharma", teacherUid: "teacher_priya", teacherEmail: "priya.sharma@tatva.edu" }],
    },
    {
      uid: "parent_nisha", name: "Mrs. Nisha Pillai", email: "nisha.pillai@tatva.edu", role: "Parent", classIds: ["class_math9b"],
      children: [{ childName: "Divya Pillai", classId: "class_math9b", className: "Grade 9 — Section B", subject: "Mathematics", teacherName: "Mrs. Priya Sharma", teacherUid: "teacher_priya", teacherEmail: "priya.sharma@tatva.edu" }],
    },
    { uid: "principal_anjali", name: "Dr. Anjali Nair", email: "principal@tatva.edu", role: "Principal", classIds: [] },
  ];

  for (const u of users) {
    await ensureAuthUser(u.uid, u.email, u.name);
    await admin.auth().setCustomUserClaims(u.uid, { role: u.role });
  }

  const batch = db.batch();
  for (const u of users) {
    batch.set(db.collection("users").doc(u.uid), {
      ...u,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`  ${users.length} users seeded`);
}

async function seedClasses() {
  console.log("Seeding classes...");
  const classes = [
    { id: "class_math8a", name: "Grade 8 — Section A", subject: "Mathematics", teacherUid: "teacher_priya", teacherName: "Mrs. Priya Sharma", teacherEmail: "priya.sharma@tatva.edu", classCode: "MATH312", studentUids: ["student_arjun", "student_sneha", "student_ravi"], parentUids: ["parent_suresh", "parent_kavitha", "parent_deepak"] },
    { id: "class_math9b", name: "Grade 9 — Section B", subject: "Mathematics", teacherUid: "teacher_priya", teacherName: "Mrs. Priya Sharma", teacherEmail: "priya.sharma@tatva.edu", classCode: "MATH498", studentUids: ["student_divya", "student_karan"], parentUids: ["parent_nisha"] },
    { id: "class_math7a", name: "Grade 7 — Section A", subject: "Mathematics", teacherUid: "teacher_priya", teacherName: "Mrs. Priya Sharma", teacherEmail: "priya.sharma@tatva.edu", classCode: "MATH201", studentUids: [], parentUids: [] },
    { id: "class_sci8a", name: "Grade 8 — Section A", subject: "Science", teacherUid: "teacher_rahul", teacherName: "Mr. Rahul Verma", teacherEmail: "rahul.verma@tatva.edu", classCode: "SCI312", studentUids: ["student_arjun", "student_sneha", "student_ravi"], parentUids: [] },
    { id: "class_sci9b", name: "Grade 9 — Section B", subject: "Science", teacherUid: "teacher_rahul", teacherName: "Mr. Rahul Verma", teacherEmail: "rahul.verma@tatva.edu", classCode: "SCI498", studentUids: ["student_divya", "student_karan"], parentUids: [] },
    { id: "class_eng8a", name: "Grade 8 — Section A", subject: "English", teacherUid: "teacher_anita", teacherName: "Ms. Anita Desai", teacherEmail: "anita.desai@tatva.edu", classCode: "ENG312", studentUids: ["student_arjun", "student_sneha"], parentUids: [] },
    { id: "class_eng9b", name: "Grade 9 — Section B", subject: "English", teacherUid: "teacher_anita", teacherName: "Ms. Anita Desai", teacherEmail: "anita.desai@tatva.edu", classCode: "ENG498", studentUids: ["student_divya"], parentUids: [] },
    { id: "class_hist8a", name: "Grade 8 — Section A", subject: "History", teacherUid: "teacher_vikram", teacherName: "Mr. Vikram Rao", teacherEmail: "vikram.rao@tatva.edu", classCode: "HIST312", studentUids: ["student_arjun"], parentUids: [] },
  ];

  const batch = db.batch();
  for (const c of classes) {
    batch.set(db.collection("classes").doc(c.id), { ...c, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${classes.length} classes seeded`);
}

async function seedStudents() {
  console.log("Seeding students...");
  const students = [
    { id: "rec_arjun", name: "Arjun Mehta", rollNumber: "8A-01", grade: "8", section: "A", parentName: "Mr. Suresh Mehta", parentPhone: "+91 9876543210", classIds: ["class_math8a", "class_sci8a", "class_eng8a", "class_hist8a"], enrolledBy: "principal_anjali" },
    { id: "rec_sneha", name: "Sneha Agarwal", rollNumber: "8A-02", grade: "8", section: "A", parentName: "Mrs. Kavitha Agarwal", parentPhone: "+91 9876543211", classIds: ["class_math8a", "class_sci8a", "class_eng8a"], enrolledBy: "principal_anjali" },
    { id: "rec_ravi", name: "Ravi Kumar", rollNumber: "8A-03", grade: "8", section: "A", parentName: "Mr. Deepak Kumar", parentPhone: "+91 9876543212", classIds: ["class_math8a", "class_sci8a"], enrolledBy: "teacher_priya" },
    { id: "rec_divya", name: "Divya Pillai", rollNumber: "9B-01", grade: "9", section: "B", parentName: "Mrs. Nisha Pillai", parentPhone: "+91 9876543213", classIds: ["class_math9b", "class_sci9b", "class_eng9b"], enrolledBy: "principal_anjali" },
    { id: "rec_karan", name: "Karan Singh", rollNumber: "9B-02", grade: "9", section: "B", parentName: "Mr. Harpreet Singh", parentPhone: "+91 9876543214", classIds: ["class_math9b", "class_sci9b"], enrolledBy: "teacher_priya" },
  ];

  const batch = db.batch();
  for (const s of students) {
    batch.set(db.collection("students").doc(s.id), { ...s, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${students.length} students seeded`);
}

async function seedGrades() {
  console.log("Seeding grades...");
  const grades = [
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_math8a", subject: "Mathematics", assessmentName: "Unit Test 1", score: 42, total: 50, teacherUid: "teacher_priya" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_math8a", subject: "Mathematics", assessmentName: "Unit Test 2", score: 38, total: 50, teacherUid: "teacher_priya" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_math8a", subject: "Mathematics", assessmentName: "Mid-Term", score: 76, total: 100, teacherUid: "teacher_priya" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_sci8a", subject: "Science", assessmentName: "Unit Test 1", score: 40, total: 50, teacherUid: "teacher_rahul" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_sci8a", subject: "Science", assessmentName: "Lab Assessment", score: 18, total: 20, teacherUid: "teacher_rahul" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_eng8a", subject: "English", assessmentName: "Essay", score: 17, total: 20, teacherUid: "teacher_anita" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_eng8a", subject: "English", assessmentName: "Mid-Term", score: 82, total: 100, teacherUid: "teacher_anita" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_hist8a", subject: "History", assessmentName: "Project", score: 45, total: 50, teacherUid: "teacher_vikram" },
    { studentUid: "student_sneha", studentName: "Sneha Agarwal", classId: "class_math8a", subject: "Mathematics", assessmentName: "Unit Test 1", score: 47, total: 50, teacherUid: "teacher_priya" },
    { studentUid: "student_sneha", studentName: "Sneha Agarwal", classId: "class_math8a", subject: "Mathematics", assessmentName: "Unit Test 2", score: 44, total: 50, teacherUid: "teacher_priya" },
    { studentUid: "student_sneha", studentName: "Sneha Agarwal", classId: "class_math8a", subject: "Mathematics", assessmentName: "Mid-Term", score: 91, total: 100, teacherUid: "teacher_priya" },
    { studentUid: "student_sneha", studentName: "Sneha Agarwal", classId: "class_sci8a", subject: "Science", assessmentName: "Unit Test 1", score: 45, total: 50, teacherUid: "teacher_rahul" },
    { studentUid: "student_ravi", studentName: "Ravi Kumar", classId: "class_math8a", subject: "Mathematics", assessmentName: "Unit Test 1", score: 35, total: 50, teacherUid: "teacher_priya" },
    { studentUid: "student_ravi", studentName: "Ravi Kumar", classId: "class_math8a", subject: "Mathematics", assessmentName: "Mid-Term", score: 68, total: 100, teacherUid: "teacher_priya" },
    { studentUid: "student_divya", studentName: "Divya Pillai", classId: "class_math9b", subject: "Mathematics", assessmentName: "Unit Test 1", score: 46, total: 50, teacherUid: "teacher_priya" },
    { studentUid: "student_divya", studentName: "Divya Pillai", classId: "class_sci9b", subject: "Science", assessmentName: "Unit Test 1", score: 43, total: 50, teacherUid: "teacher_rahul" },
    { studentUid: "student_karan", studentName: "Karan Singh", classId: "class_math9b", subject: "Mathematics", assessmentName: "Unit Test 1", score: 38, total: 50, teacherUid: "teacher_priya" },
  ];

  const batch = db.batch();
  for (const g of grades) {
    batch.set(db.collection("grades").doc(), { ...g, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${grades.length} grades seeded`);
}

async function seedHomework() {
  console.log("Seeding homework...");
  const homework = [
    { title: "Quadratic Equations — Practice Set", description: "Solve exercises 5.1 to 5.4 from textbook. Show all steps.", subject: "Mathematics", classId: "class_math8a", className: "Grade 8 — Section A", teacherUid: "teacher_priya", teacherName: "Mrs. Priya Sharma", dueDate: "2026-04-28", submittedBy: ["student_arjun", "student_sneha"] },
    { title: "Trigonometry Worksheet", description: "Complete the trigonometry identities worksheet handed out in class.", subject: "Mathematics", classId: "class_math8a", className: "Grade 8 — Section A", teacherUid: "teacher_priya", teacherName: "Mrs. Priya Sharma", dueDate: "2026-04-30", submittedBy: ["student_arjun"] },
    { title: "Statistics Project", description: "Collect data and create frequency distribution tables.", subject: "Mathematics", classId: "class_math8a", className: "Grade 8 — Section A", teacherUid: "teacher_priya", teacherName: "Mrs. Priya Sharma", dueDate: "2026-05-05", submittedBy: [] },
    { title: "Linear Equations Review", description: "Review chapter 3 and solve all end-of-chapter exercises.", subject: "Mathematics", classId: "class_math9b", className: "Grade 9 — Section B", teacherUid: "teacher_priya", teacherName: "Mrs. Priya Sharma", dueDate: "2026-04-29", submittedBy: ["student_divya"] },
    { title: "Photosynthesis Lab Report", description: "Write up the lab experiment results from last Friday.", subject: "Science", classId: "class_sci8a", className: "Grade 8 — Section A", teacherUid: "teacher_rahul", teacherName: "Mr. Rahul Verma", dueDate: "2026-04-27", submittedBy: ["student_arjun", "student_sneha", "student_ravi"] },
    { title: "Essay: My Favorite Book", description: "Write a 500-word essay on your favorite book and why it matters.", subject: "English", classId: "class_eng8a", className: "Grade 8 — Section A", teacherUid: "teacher_anita", teacherName: "Ms. Anita Desai", dueDate: "2026-05-02", submittedBy: [] },
  ];

  const batch = db.batch();
  for (const h of homework) {
    batch.set(db.collection("homework").doc(), { ...h, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${homework.length} homework seeded`);
}

async function seedAnnouncements() {
  console.log("Seeding announcements...");
  const announcements = [
    { title: "Annual Sports Day", body: "Annual Sports Day is scheduled for May 15, 2026. All students must participate in at least one event.", audience: "Everyone", classIds: [], createdBy: "principal_anjali", createdByName: "Dr. Anjali Nair", createdByRole: "Principal" },
    { title: "Parent-Teacher Meeting", body: "PTM is on April 30. Parents are requested to meet with the class teacher between 10 AM and 1 PM.", audience: "Parents", classIds: [], createdBy: "principal_anjali", createdByName: "Dr. Anjali Nair", createdByRole: "Principal" },
    { title: "Math Olympiad Registration", body: "Registration for the National Math Olympiad is now open. Interested students can register with Mrs. Priya Sharma before May 5.", audience: "Students", classIds: [], createdBy: "teacher_priya", createdByName: "Mrs. Priya Sharma", createdByRole: "Teacher" },
    { title: "Library Book Return Reminder", body: "All library books must be returned by May 10, 2026.", audience: "Students", classIds: [], createdBy: "principal_anjali", createdByName: "Dr. Anjali Nair", createdByRole: "Principal" },
    { title: "Science Fair Winners", body: "Congratulations to all participants! First place goes to Sneha Agarwal for her project on Renewable Energy.", audience: "Everyone", classIds: [], createdBy: "teacher_rahul", createdByName: "Mr. Rahul Verma", createdByRole: "Teacher" },
  ];

  const batch = db.batch();
  for (const a of announcements) {
    batch.set(db.collection("announcements").doc(), { ...a, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${announcements.length} announcements seeded`);
}

async function seedVotes() {
  console.log("Seeding votes...");
  const votes = [
    { question: "Should we have school on Saturday for extra classes?", type: "school_decision", createdBy: "principal_anjali", createdByName: "Dr. Anjali Nair", createdByRole: "Principal", votes: { school: 45, no_school: 120, undecided: 15 }, voters: ["parent_suresh", "parent_kavitha", "parent_deepak"], active: true },
    { question: "Should the annual day theme be 'Space Exploration' or 'Heritage of India'?", type: "school_decision", createdBy: "principal_anjali", createdByName: "Dr. Anjali Nair", createdByRole: "Principal", votes: { school: 90, no_school: 65, undecided: 25 }, voters: ["parent_suresh", "parent_nisha"], active: true },
  ];

  const batch = db.batch();
  for (const v of votes) {
    batch.set(db.collection("votes").doc(), { ...v, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${votes.length} votes seeded`);
}

async function seedMessages() {
  console.log("Seeding messages...");
  const convId = "parent_suresh_teacher_priya";
  const messages = [
    { text: "Good morning Mrs. Sharma! I wanted to discuss Arjun's progress in mathematics.", senderUid: "parent_suresh", receiverUid: "teacher_priya", conversationId: convId, participantUids: ["parent_suresh", "teacher_priya"] },
    { text: "Good morning Mr. Mehta! Arjun has been doing well. His test scores have improved consistently.", senderUid: "teacher_priya", receiverUid: "parent_suresh", conversationId: convId, participantUids: ["parent_suresh", "teacher_priya"] },
    { text: "That's wonderful to hear! Are there any areas where he could improve?", senderUid: "parent_suresh", receiverUid: "teacher_priya", conversationId: convId, participantUids: ["parent_suresh", "teacher_priya"] },
    { text: "He should practice word problems more. I'll send some extra worksheets.", senderUid: "teacher_priya", receiverUid: "parent_suresh", conversationId: convId, participantUids: ["parent_suresh", "teacher_priya"] },
    { text: "Thank you so much! We'll make sure he works on those.", senderUid: "parent_suresh", receiverUid: "teacher_priya", conversationId: convId, participantUids: ["parent_suresh", "teacher_priya"] },
  ];

  const batch = db.batch();
  for (let i = 0; i < messages.length; i++) {
    batch.set(db.collection("messages").doc(), {
      ...messages[i],
      createdAt: admin.firestore.Timestamp.fromDate(new Date(2026, 3, 23, 9, i * 2)),
    });
  }
  await batch.commit();
  console.log(`  ${messages.length} messages seeded`);
}

async function seedBehaviorPoints() {
  console.log("Seeding behavior points...");
  const points = [
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_math8a", categoryId: "teamwork", points: 1, awardedBy: "teacher_priya", awardedByName: "Mrs. Priya Sharma", note: "Great collaboration on group project" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_math8a", categoryId: "hard_work", points: 1, awardedBy: "teacher_priya", awardedByName: "Mrs. Priya Sharma", note: "Extra practice problems completed" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_math8a", categoryId: "participation", points: 1, awardedBy: "teacher_priya", awardedByName: "Mrs. Priya Sharma", note: "" },
    { studentUid: "student_arjun", studentName: "Arjun Mehta", classId: "class_math8a", categoryId: "off_task", points: -1, awardedBy: "teacher_priya", awardedByName: "Mrs. Priya Sharma", note: "Using phone during class" },
    { studentUid: "student_sneha", studentName: "Sneha Agarwal", classId: "class_math8a", categoryId: "helping", points: 1, awardedBy: "teacher_priya", awardedByName: "Mrs. Priya Sharma", note: "Helped classmate with homework" },
    { studentUid: "student_sneha", studentName: "Sneha Agarwal", classId: "class_math8a", categoryId: "respect", points: 1, awardedBy: "teacher_priya", awardedByName: "Mrs. Priya Sharma", note: "" },
    { studentUid: "student_sneha", studentName: "Sneha Agarwal", classId: "class_math8a", categoryId: "creativity", points: 1, awardedBy: "teacher_priya", awardedByName: "Mrs. Priya Sharma", note: "Creative approach to math problem" },
    { studentUid: "student_ravi", studentName: "Ravi Kumar", classId: "class_sci8a", categoryId: "leadership", points: 1, awardedBy: "teacher_rahul", awardedByName: "Mr. Rahul Verma", note: "Led the science experiment group" },
    { studentUid: "student_ravi", studentName: "Ravi Kumar", classId: "class_sci8a", categoryId: "participation", points: 1, awardedBy: "teacher_rahul", awardedByName: "Mr. Rahul Verma", note: "" },
    { studentUid: "student_divya", studentName: "Divya Pillai", classId: "class_eng9b", categoryId: "kindness", points: 1, awardedBy: "teacher_anita", awardedByName: "Ms. Anita Desai", note: "Shared supplies with new student" },
  ];

  const batch = db.batch();
  for (const p of points) {
    batch.set(db.collection("behavior_points").doc(), { ...p, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${points.length} behavior points seeded`);
}

async function seedAttendance() {
  console.log("Seeding attendance...");
  const today = new Date();
  const students = ["student_arjun", "student_sneha", "student_ravi", "student_divya", "student_karan"];
  const names = ["Arjun Mehta", "Sneha Agarwal", "Ravi Kumar", "Divya Pillai", "Karan Singh"];
  const todayStatuses = ["Present", "Present", "Present", "Tardy", "Absent"];
  let count = 0;

  for (let day = 0; day < 5; day++) {
    const date = new Date(today);
    date.setDate(date.getDate() - day);
    const dateStr = date.toISOString().substring(0, 10);
    const batch = db.batch();
    for (let i = 0; i < students.length; i++) {
      const classId = i < 3 ? "class_math8a" : "class_math9b";
      const status = day === 0 ? todayStatuses[i] : "Present";
      const docId = `${students[i]}_${dateStr}`;
      batch.set(db.collection("attendance").doc(docId), {
        studentUid: students[i],
        studentName: names[i],
        classId,
        date: dateStr,
        status,
        markedBy: "teacher_priya",
        createdAt: FieldValue.serverTimestamp(),
      });
      count++;
    }
    await batch.commit();
  }
  console.log(`  ${count} attendance records seeded`);
}

async function seedStories() {
  console.log("Seeding stories...");
  const posts = [
    { authorUid: "teacher_priya", authorName: "Mrs. Priya Sharma", authorRole: "Teacher", classId: "class_math8a", className: "Grade 8 — Section A (Mathematics)", text: "Our class did an amazing job on the quadratic equations project today! So proud of everyone's teamwork.", mediaUrls: [], mediaType: "none", likedBy: ["parent_suresh", "parent_kavitha"], commentCount: 3 },
    { authorUid: "teacher_rahul", authorName: "Mr. Rahul Verma", authorRole: "Teacher", classId: "class_sci8a", className: "Grade 8 — Section A (Science)", text: "Science experiment day! Students explored chemical reactions with baking soda and vinegar. The excitement was contagious!", mediaUrls: [], mediaType: "none", likedBy: ["parent_deepak"], commentCount: 5 },
    { authorUid: "teacher_anita", authorName: "Ms. Anita Desai", authorRole: "Teacher", classId: "class_eng8a", className: "Grade 8 — Section A (English)", text: "Creative writing showcase! Students wrote their own short stories. Some truly talented authors in our class.", mediaUrls: [], mediaType: "none", likedBy: ["parent_suresh"], commentCount: 2 },
    { authorUid: "student_arjun", authorName: "Arjun Mehta", authorRole: "Student", classId: "class_math8a", className: "Grade 8 — Section A (Mathematics)", text: "Finished my math project! Learned how equations work in real life.", mediaUrls: [], mediaType: "none", likedBy: ["teacher_priya", "student_sneha"], commentCount: 1 },
  ];

  const batch = db.batch();
  for (const p of posts) {
    batch.set(db.collection("stories").doc(), { ...p, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${posts.length} stories seeded`);
}

async function seedActivities() {
  console.log("Seeding activities...");
  const events = [
    { type: "behaviorPoint", actorUid: "teacher_priya", actorName: "Mrs. Priya Sharma", actorRole: "Teacher", targetUid: "student_arjun", classId: "class_math8a", title: "+1 Teamwork", body: "Mrs. Priya Sharma gave Arjun Mehta a point for Teamwork", metadata: {} },
    { type: "attendance", actorUid: "teacher_priya", actorName: "Mrs. Priya Sharma", actorRole: "Teacher", targetUid: "", classId: "class_math8a", title: "Attendance marked: 3/3 present", body: "Mrs. Priya Sharma marked attendance for today", metadata: {} },
    { type: "homeworkAssigned", actorUid: "teacher_priya", actorName: "Mrs. Priya Sharma", actorRole: "Teacher", targetUid: "", classId: "class_math8a", title: "New homework: Quadratic Equations", body: "Due Apr 28, 2026", metadata: {} },
    { type: "storyPost", actorUid: "teacher_priya", actorName: "Mrs. Priya Sharma", actorRole: "Teacher", targetUid: "", classId: "class_math8a", title: "New story post in Grade 8A Math", body: "Our class did an amazing job on the quadratic equations project!", metadata: {} },
    { type: "gradeEntered", actorUid: "teacher_priya", actorName: "Mrs. Priya Sharma", actorRole: "Teacher", targetUid: "student_arjun", classId: "class_math8a", title: "Grade entered: Mid-Term", body: "Arjun Mehta scored 76/100 in Mathematics", metadata: {} },
    { type: "announcement", actorUid: "principal_anjali", actorName: "Dr. Anjali Nair", actorRole: "Principal", targetUid: "", classId: "", title: "Annual Sports Day", body: "Annual Sports Day is scheduled for May 15, 2026!", metadata: {} },
    { type: "studentEnrolled", actorUid: "teacher_priya", actorName: "Mrs. Priya Sharma", actorRole: "Teacher", targetUid: "student_ravi", classId: "class_math8a", title: "New student enrolled", body: "Ravi Kumar joined Grade 8 — Section A", metadata: {} },
  ];

  const batch = db.batch();
  for (const e of events) {
    batch.set(db.collection("activities").doc(), { ...e, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${events.length} activities seeded`);
}

async function seedContent() {
  console.log("Seeding content...");
  const items = [
    { title: "Breathing Buddies", description: "Learn a simple breathing exercise to help you feel calm and focused before tests.", category: "mindfulness", videoUrl: "", thumbnailUrl: "", duration: "5 min", ageGroup: "All", viewCount: 45, completedBy: ["student_arjun"] },
    { title: "The Power of Yet", description: "Discover how adding the word 'yet' can change your mindset. You can't do it... yet!", category: "growthMindset", videoUrl: "", thumbnailUrl: "", duration: "7 min", ageGroup: "All", viewCount: 62, completedBy: ["student_arjun", "student_sneha"] },
    { title: "Walking in Someone Else's Shoes", description: "An interactive story that helps you understand how others feel and why empathy matters.", category: "empathy", videoUrl: "", thumbnailUrl: "", duration: "8 min", ageGroup: "All", viewCount: 38, completedBy: [] },
    { title: "Gratitude Journal", description: "Start a daily gratitude practice. Write down three things you are thankful for each day.", category: "gratitude", videoUrl: "", thumbnailUrl: "", duration: "4 min", ageGroup: "All", viewCount: 51, completedBy: ["student_sneha"] },
    { title: "The Marshmallow Challenge", description: "Can you wait for a bigger reward? Learn about patience and perseverance.", category: "perseverance", videoUrl: "", thumbnailUrl: "", duration: "6 min", ageGroup: "All", viewCount: 29, completedBy: [] },
    { title: "Team Tower Building", description: "Work together to build the tallest tower! Learn what makes teams successful.", category: "teamwork", videoUrl: "", thumbnailUrl: "", duration: "10 min", ageGroup: "All", viewCount: 73, completedBy: ["student_arjun", "student_ravi"] },
    { title: "Imagine & Create", description: "Let your imagination run wild! Draw, write, or build something that doesn't exist yet.", category: "creativity", videoUrl: "", thumbnailUrl: "", duration: "12 min", ageGroup: "All", viewCount: 41, completedBy: ["student_divya"] },
    { title: "Being a Good Citizen", description: "Learn about responsibility at home, in school, and in your community.", category: "responsibility", videoUrl: "", thumbnailUrl: "", duration: "6 min", ageGroup: "All", viewCount: 33, completedBy: [] },
  ];

  const batch = db.batch();
  for (const item of items) {
    batch.set(db.collection("content").doc(), { ...item, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();
  console.log(`  ${items.length} content items seeded`);
}

async function seedGroupConversations() {
  console.log("Seeding group conversations...");
  const groups = [
    {
      id: "group_math8a",
      name: "Grade 8A Math — Class Chat",
      classId: "class_math8a",
      participantUids: ["teacher_priya", "student_arjun", "student_sneha", "student_ravi", "parent_suresh", "parent_kavitha", "parent_deepak"],
      createdBy: "teacher_priya",
    },
  ];

  const batch = db.batch();
  for (const g of groups) {
    batch.set(db.collection("group_conversations").doc(g.id), { ...g, createdAt: FieldValue.serverTimestamp() });
  }
  await batch.commit();

  const msgs = [
    { text: "Welcome to the Grade 8A Math class chat!", senderUid: "teacher_priya", senderName: "Mrs. Priya Sharma" },
    { text: "Remember to submit your homework by Friday.", senderUid: "teacher_priya", senderName: "Mrs. Priya Sharma" },
    { text: "Thank you Mrs. Sharma!", senderUid: "student_arjun", senderName: "Arjun Mehta" },
  ];

  const msgBatch = db.batch();
  for (const m of msgs) {
    msgBatch.set(db.collection("group_conversations").doc("group_math8a").collection("messages").doc(), {
      ...m,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  await msgBatch.commit();
  console.log(`  ${groups.length} groups + ${msgs.length} messages seeded`);
}

async function main() {
  console.log("=== Seeding Firestore & Auth for tatva-school-app ===\n");
  console.log("Default password for all demo accounts:", DEFAULT_PASSWORD, "\n");

  await seedUsers();
  await seedClasses();
  await seedStudents();
  await seedGrades();
  await seedHomework();
  await seedAnnouncements();
  await seedVotes();
  await seedMessages();
  await seedBehaviorPoints();
  await seedAttendance();
  await seedStories();
  await seedActivities();
  await seedContent();
  await seedGroupConversations();

  console.log("\n=== Seeding complete! ===");
  console.log("\nDemo accounts (all use password: " + DEFAULT_PASSWORD + "):");
  console.log("  Teacher:   priya.sharma@tatva.edu");
  console.log("  Teacher:   rahul.verma@tatva.edu");
  console.log("  Student:   arjun.mehta@tatva.edu");
  console.log("  Parent:    suresh.mehta@tatva.edu");
  console.log("  Principal: principal@tatva.edu");
  process.exit(0);
}

main().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
