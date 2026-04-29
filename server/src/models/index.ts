export interface UserDoc {
  id: string;
  uid: string;
  name: string;
  email: string;
  role: "Student" | "Teacher" | "Parent" | "Principal";
  classIds: string[];
  children: ChildInfo[];
  fcmToken?: string;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface ChildInfo {
  childName: string;
  classId: string;
  className: string;
  subject: string;
  teacherName: string;
  teacherUid: string;
  teacherEmail: string;
}

export interface ClassDoc {
  id: string;
  name: string;
  subject: string;
  grade: string;
  section: string;
  classCode: string;
  teacherUid: string;
  teacherName: string;
  teacherEmail: string;
  studentUids: string[];
  parentUids: string[];
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface HomeworkDoc {
  id: string;
  title: string;
  description: string;
  subject: string;
  classId: string;
  className: string;
  teacherUid: string;
  teacherName: string;
  dueDate: string;
  submittedBy: string[];
  attachments: HomeworkAttachment[];
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface HomeworkAttachment {
  url: string;
  name: string;
  type: "pdf" | "image" | "document";
}

export interface HomeworkSubmissionDoc {
  id: string;
  homeworkId: string;
  studentUid: string;
  files: HomeworkAttachment[];
  note: string;
  status: "pending" | "accepted" | "returned";
  commentCount: number;
  submittedAt?: FirebaseFirestore.Timestamp | string;
}

export interface HomeworkCommentDoc {
  id: string;
  submissionId: string;
  authorUid: string;
  authorName: string;
  authorRole: string;
  text: string;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface AnnouncementDoc {
  id: string;
  title: string;
  body: string;
  audience: string;
  grades: string[];
  classIds: string[];
  createdBy: string;
  createdByName: string;
  createdByRole: string;
  likedBy: string[];
  commentCount: number;
  attachments: { url: string; name: string; type: string }[];
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface VoteDoc {
  id: string;
  question: string;
  type: string;
  options: string[];
  createdBy: string;
  createdByName: string;
  createdByRole: string;
  votes: Record<string, number>;
  voters: string[];
  active: boolean;
  votingDeadline: string;
  resultsVisibleUntil: string;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface StoryDoc {
  id: string;
  authorUid: string;
  authorName: string;
  authorRole: string;
  classId: string;
  className: string;
  text: string;
  mediaUrls: string[];
  mediaType: string;
  likedBy: string[];
  commentCount: number;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface GradeDoc {
  id: string;
  studentUid: string;
  studentName: string;
  classId: string;
  subject: string;
  assessmentName: string;
  score: number;
  total: number;
  teacherUid: string;
  createdAt?: FirebaseFirestore.Timestamp | string;
  updatedAt?: FirebaseFirestore.Timestamp | string;
}

export interface TestTitleDoc {
  id: string;
  teacherUid: string;
  title: string;
  subject: string;
  total: number;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface BehaviorPointDoc {
  id: string;
  studentUid: string;
  studentName: string;
  classId: string;
  categoryId: string;
  points: number;
  awardedBy: string;
  awardedByName: string;
  note: string;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface AttendanceDoc {
  id: string;
  studentUid: string;
  studentName: string;
  date: string;
  status: string;
  markedBy: string;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface MessageDoc {
  id: string;
  conversationId: string;
  senderUid: string;
  receiverUid: string;
  text: string;
  participantUids: string[];
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface GroupConversationDoc {
  id: string;
  participantUids: string[];
  lastSenderName: string;
  lastMessageAt?: string;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface ScheduleDoc {
  id: string;
  grade: string;
  section: string;
  dayOfWeek: string;
  periods: SchedulePeriod[];
  createdBy: string;
  updatedAt?: FirebaseFirestore.Timestamp | string;
}

export interface SchedulePeriod {
  classId?: string;
  teacherName?: string;
  subject?: string;
  startTime: string;
  endTime: string;
}

export interface ScheduleEventDoc {
  id: string;
  title: string;
  description: string;
  date: string;
  startTime: string;
  endTime: string;
  type: string;
  createdBy: string;
  affectedGrades: string[];
  cancelsRegularSchedule: boolean;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface PeriodCancellationDoc {
  id: string;
  grade: string;
  section: string;
  date: string;
  startTime: string;
  classId: string;
  reason: string;
  cancelledBy: string;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface ActivityDoc {
  id: string;
  targetUid?: string;
  classId?: string;
  body: string;
  metadata: Record<string, unknown>;
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface HolidayDoc {
  id: string;
  name: string;
  startDate: string;
  endDate: string;
  type: "federal" | "summer_break" | "spring_break" | "winter_break" | "teacher_workday" | "custom";
  description: string;
  createdBy: string;
  createdAt: FirebaseFirestore.Timestamp | string;
  updatedAt: FirebaseFirestore.Timestamp | string;
}

export interface ContentDoc {
  id: string;
  viewCount: number;
  completedBy: string[];
  createdAt?: FirebaseFirestore.Timestamp | string;
}

export interface WeeklyReportDoc {
  id: string;
  studentUid: string;
  createdAt?: FirebaseFirestore.Timestamp | string;
}
