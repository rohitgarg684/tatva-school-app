import * as admin from "firebase-admin";
import { db } from "./firestore-helpers";
import { Collections } from "./collections";

type ActivityType =
  | "behaviorPoint"
  | "attendance"
  | "homeworkAssigned"
  | "homeworkSubmitted"
  | "gradeEntered"
  | "announcement"
  | "storyPost"
  | "voteCreated"
  | "studentEnrolled";

interface LogActivityParams {
  type: ActivityType;
  actorUid: string;
  actorName: string;
  actorRole?: string;
  targetUid?: string;
  classId?: string;
  title: string;
  body?: string;
  metadata?: Record<string, any>;
}

export function logActivity(params: LogActivityParams): void {
  db.collection(Collections.ACTIVITIES)
    .add({
      type: params.type,
      actorUid: params.actorUid,
      actorName: params.actorName,
      actorRole: params.actorRole || "",
      targetUid: params.targetUid || "",
      classId: params.classId || "",
      title: params.title,
      body: params.body || "",
      metadata: params.metadata || {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    })
    .catch((err) => console.error("Activity log failed:", err));
}
