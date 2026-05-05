export type NotificationEvent =
  | "announcement"
  | "homeworkAssigned"
  | "homeworkStatusChanged"
  | "homeworkComment"
  | "diaryEntry"
  | "diaryComment";

export interface NotificationPayload {
  title: string;
  body: string;
  data: Record<string, string>;
}

export interface Recipient {
  uid: string;
  token: string;
}

export interface NotificationChannel {
  name: string;
  send(recipients: Recipient[], payload: NotificationPayload): Promise<void>;
}

export interface AnnouncementContext {
  title: string;
  authorName: string;
  audience: string;
  grades: string[];
  senderUid: string;
  announcementId: string;
}

export interface HomeworkAssignedContext {
  homeworkId: string;
  classId: string;
  title: string;
  teacherName: string;
  teacherUid: string;
}

export interface HomeworkStatusContext {
  homeworkId: string;
  studentUid: string;
  classId: string;
  title: string;
  status: "accepted" | "returned";
}

export interface HomeworkCommentContext {
  homeworkId: string;
  studentUid: string;
  authorUid: string;
  authorName: string;
  teacherUid: string;
  homeworkTitle: string;
}

export interface DiaryEntryContext {
  entryId: string;
  studentUid: string;
  studentName: string;
  teacherName: string;
  teacherUid: string;
  title: string;
}

export interface DiaryCommentContext {
  entryId: string;
  studentUid: string;
  authorUid: string;
  authorName: string;
  teacherUid: string;
  entryTitle: string;
}

export type EventContext =
  | { event: "announcement"; ctx: AnnouncementContext }
  | { event: "homeworkAssigned"; ctx: HomeworkAssignedContext }
  | { event: "homeworkStatusChanged"; ctx: HomeworkStatusContext }
  | { event: "homeworkComment"; ctx: HomeworkCommentContext }
  | { event: "diaryEntry"; ctx: DiaryEntryContext }
  | { event: "diaryComment"; ctx: DiaryCommentContext };
