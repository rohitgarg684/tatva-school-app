import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "./firestore-helpers";
import { cacheDeletePrefix } from "./cache";
import * as admin from "firebase-admin";

function requireAuth(request: any): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  return request.auth.uid;
}

export const toggleStoryLike = onCall(
  { region: "us-central1" },
  async (request) => {
    const uid = requireAuth(request);
    const { storyId } = request.data;
    if (!storyId) throw new HttpsError("invalid-argument", "storyId required");

    const ref = db.collection("stories").doc(storyId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError("not-found", "Story not found");

    const likedBy: string[] = snap.data()?.likedBy || [];
    const isLiked = likedBy.includes(uid);

    await ref.update({
      likedBy: isLiked
        ? admin.firestore.FieldValue.arrayRemove(uid)
        : admin.firestore.FieldValue.arrayUnion(uid),
    });

    return { storyId, liked: !isLiked };
  }
);

export const submitHomework = onCall(
  { region: "us-central1" },
  async (request) => {
    const uid = requireAuth(request);
    const { homeworkId } = request.data;
    if (!homeworkId)
      throw new HttpsError("invalid-argument", "homeworkId required");

    await db.collection("homework").doc(homeworkId).update({
      submittedBy: admin.firestore.FieldValue.arrayUnion(uid),
    });

    cacheDeletePrefix("student_dash_");
    return { homeworkId, submitted: true };
  }
);

export const markContentCompleted = onCall(
  { region: "us-central1" },
  async (request) => {
    const uid = requireAuth(request);
    const { contentId } = request.data;
    if (!contentId)
      throw new HttpsError("invalid-argument", "contentId required");

    await db.collection("content").doc(contentId).update({
      completedBy: admin.firestore.FieldValue.arrayUnion(uid),
    });

    return { contentId, completed: true };
  }
);

export const castVote = onCall(
  { region: "us-central1" },
  async (request) => {
    const uid = requireAuth(request);
    const { voteId, choice } = request.data;
    if (!voteId || !choice)
      throw new HttpsError("invalid-argument", "voteId and choice required");

    const ref = db.collection("votes").doc(voteId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError("not-found", "Vote not found");

    const data = snap.data()!;
    const voters: string[] = data.voters || [];
    if (voters.includes(uid)) {
      throw new HttpsError("already-exists", "Already voted");
    }

    const voteKey = `votes.${choice}`;
    await ref.update({
      [voteKey]: admin.firestore.FieldValue.increment(1),
      voters: admin.firestore.FieldValue.arrayUnion(uid),
    });

    return { voteId, voted: true, choice };
  }
);

export const closeVote = onCall(
  { region: "us-central1" },
  async (request) => {
    requireAuth(request);
    const { voteId } = request.data;
    if (!voteId) throw new HttpsError("invalid-argument", "voteId required");

    await db.collection("votes").doc(voteId).update({ active: false });
    cacheDeletePrefix("votes_active");

    return { voteId, closed: true };
  }
);

export const markAttendance = onCall(
  { region: "us-central1" },
  async (request) => {
    requireAuth(request);
    const { records } = request.data;
    if (!Array.isArray(records) || records.length === 0) {
      throw new HttpsError("invalid-argument", "records array required");
    }

    const batch = db.batch();
    for (const rec of records) {
      const docId = `${rec.studentUid}_${rec.date}`;
      const ref = db.collection("attendance").doc(docId);
      batch.set(ref, {
        ...rec,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    await batch.commit();

    cacheDeletePrefix("teacher_dash_");
    return { marked: records.length };
  }
);

export const awardBehaviorPoint = onCall(
  { region: "us-central1" },
  async (request) => {
    const uid = requireAuth(request);
    const { studentUid, studentName, classId, categoryId, points, note } =
      request.data;

    if (!studentUid || !classId || !categoryId) {
      throw new HttpsError(
        "invalid-argument",
        "studentUid, classId, categoryId required"
      );
    }

    const userSnap = await db.collection("users").doc(uid).get();
    const awardedByName = userSnap.data()?.name || "";

    const ref = await db.collection("behavior_points").add({
      studentUid,
      studentName: studentName || "",
      classId,
      categoryId,
      points: points || 1,
      awardedBy: uid,
      awardedByName,
      note: note || "",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    cacheDeletePrefix("student_dash_");
    cacheDeletePrefix("teacher_dash_");

    return { id: ref.id, awarded: true };
  }
);
