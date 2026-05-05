import { db } from "../firestore-helpers";
import { Collections } from "../collections";
import { Recipient } from "./types";

const FIRESTORE_IN_LIMIT = 30;

async function fetchTokensForUids(uids: string[], excludeUid?: string): Promise<Recipient[]> {
  const filtered = excludeUid ? uids.filter((u) => u !== excludeUid) : uids;
  const unique = [...new Set(filtered)];
  if (unique.length === 0) return [];

  const recipients: Recipient[] = [];
  for (let i = 0; i < unique.length; i += FIRESTORE_IN_LIMIT) {
    const chunk = unique.slice(i, i + FIRESTORE_IN_LIMIT);
    const snap = await db
      .collection(Collections.USERS)
      .where("uid", "in", chunk)
      .get();
    for (const doc of snap.docs) {
      const token = doc.data().fcmToken;
      if (token) recipients.push({ uid: doc.id, token });
    }
  }
  return recipients;
}

export async function resolveAnnouncementRecipients(
  audience: string,
  grades: string[],
  senderUid: string
): Promise<Recipient[]> {
  if (audience === "Everyone") {
    const snap = await db
      .collection(Collections.USERS)
      .where("fcmToken", "!=", "")
      .get();
    return snap.docs
      .filter((d) => d.id !== senderUid && d.data().fcmToken)
      .map((d) => ({ uid: d.id, token: d.data().fcmToken }));
  }

  if (grades.length === 0) return [];

  const uids: string[] = [];
  for (let i = 0; i < grades.length; i += FIRESTORE_IN_LIMIT) {
    const chunk = grades.slice(i, i + FIRESTORE_IN_LIMIT);
    const snap = await db
      .collection(Collections.CLASSES)
      .where("grade", "in", chunk)
      .get();
    for (const doc of snap.docs) {
      const data = doc.data();
      uids.push(...(data.studentUids || []), ...(data.parentUids || []));
    }
  }

  return fetchTokensForUids(uids, senderUid);
}

export async function resolveClassRecipients(
  classId: string,
  excludeUid?: string
): Promise<Recipient[]> {
  const classSnap = await db.collection(Collections.CLASSES).doc(classId).get();
  if (!classSnap.exists) return [];

  const data = classSnap.data()!;
  const uids = [...(data.studentUids || []), ...(data.parentUids || [])];
  return fetchTokensForUids(uids, excludeUid);
}

export async function resolveStudentAndParents(
  studentUid: string,
  classId?: string
): Promise<Recipient[]> {
  const uids = [studentUid];

  if (classId) {
    const classSnap = await db.collection(Collections.CLASSES).doc(classId).get();
    if (classSnap.exists) {
      const parentUids: string[] = classSnap.data()?.parentUids || [];
      if (parentUids.length > 0) {
        for (let i = 0; i < parentUids.length; i += FIRESTORE_IN_LIMIT) {
          const chunk = parentUids.slice(i, i + FIRESTORE_IN_LIMIT);
          const snap = await db
            .collection(Collections.USERS)
            .where("uid", "in", chunk)
            .get();
          for (const doc of snap.docs) {
            const children: { classId: string }[] = doc.data().children || [];
            if (children.some((c) => c.classId === classId)) {
              uids.push(doc.id);
            }
          }
        }
      }
    }
  }

  return fetchTokensForUids(uids);
}

export async function resolveCommentRecipient(
  authorUid: string,
  studentUid: string,
  teacherUid: string
): Promise<Recipient[]> {
  const targetUid = authorUid === studentUid ? teacherUid : studentUid;
  return fetchTokensForUids([targetUid], authorUid);
}

export async function resolveParentsOfStudent(
  studentUid: string,
  excludeUid?: string
): Promise<Recipient[]> {
  const snap = await db
    .collection(Collections.USERS)
    .where("role", "==", "Parent")
    .get();

  const parentUids: string[] = [];
  for (const doc of snap.docs) {
    const children: { childUid: string }[] = doc.data().children || [];
    if (children.some((c) => c.childUid === studentUid)) {
      parentUids.push(doc.id);
    }
  }

  return fetchTokensForUids(parentUids, excludeUid);
}

export async function resolveDiaryCommentRecipient(
  authorUid: string,
  teacherUid: string
): Promise<Recipient[]> {
  return fetchTokensForUids([teacherUid], authorUid);
}
