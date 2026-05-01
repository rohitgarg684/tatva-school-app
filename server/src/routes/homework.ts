import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, getDoc, serializeDocs } from "../lib/firestore-helpers";
import { invalidateDashboards } from "../lib/cache-invalidation";
import { asyncHandler } from "../lib/async-handler";
import { deleteDocument } from "../lib/crud-helpers";
import { Collections } from "../lib/collections";
import { logActivity } from "../lib/activity-logger";
import { notify } from "../lib/notifications/notifier";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

async function resolveStudentUid(req: any): Promise<{ studentUid: string; error?: string }> {
  if (req.role === "Parent") {
    const targetUid = req.body?.studentUid as string;
    if (!targetUid) return { studentUid: "", error: "studentUid required for parent submissions" };
    const parentDoc = await getDoc(Collections.USERS, req.uid!);
    const children: Array<{ childName: string }> = parentDoc?.children || [];
    const childNames = children.map((c) => c.childName);
    const studentDoc = await getDoc(Collections.USERS, targetUid);
    if (!studentDoc || !childNames.includes(studentDoc.name)) {
      return { studentUid: "", error: "You can only submit for your own child" };
    }
    return { studentUid: targetUid };
  }
  return { studentUid: req.uid! };
}

router.post(
  "/homework",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { title, description, subject, classId, className, dueDate, attachments } = req.body;
    if (!title || !classId)
      return res.status(400).json({ error: "title, classId required" });

    const uid = req.uid!;
    const userDoc = await getDoc(Collections.USERS, uid);

    const ref = await db.collection(Collections.HOMEWORK).add({
      title,
      description: description || "",
      subject: subject || "",
      classId,
      className: className || "",
      teacherUid: uid,
      teacherName: userDoc?.name || "",
      dueDate: dueDate || "",
      submittedBy: [],
      attachments: Array.isArray(attachments) ? attachments : [],
      createdAt: FieldValue.serverTimestamp(),
    });

    logActivity({
      type: "homeworkAssigned",
      actorUid: uid,
      actorName: userDoc?.name || "",
      actorRole: req.role || "Teacher",
      classId,
      title: `Homework: ${title}`,
      body: subject ? `${subject}${dueDate ? ` — due ${dueDate}` : ''}` : "",
      metadata: { subject, dueDate },
    });

    notify({
      event: "homeworkAssigned",
      ctx: {
        homeworkId: ref.id,
        classId,
        title,
        teacherName: userDoc?.name || "",
        teacherUid: uid,
      },
    });

    invalidateDashboards("homework_");
    res.json({ id: ref.id, created: true });
  })
);

router.delete(
  "/homework/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    await deleteDocument(
      Collections.HOMEWORK,
      req.params.id as string,
      res,
      ["teacher_dash_", "student_dash_", "parent_dash_"]
    );
  })
);

router.post(
  "/homework/:homeworkId/submit",
  requireRole("Student", "Parent"),
  asyncHandler(async (req, res) => {
    const { studentUid, error } = await resolveStudentUid(req);
    if (error) return res.status(403).json({ error });

    const homeworkId = req.params.homeworkId as string;

    const subRef = db
      .collection(Collections.HOMEWORK_SUBMISSIONS)
      .doc(`${homeworkId}_${studentUid}`);
    const subSnap = await subRef.get();
    if (!subSnap.exists) {
      await subRef.set({
        homeworkId,
        studentUid,
        files: [],
        note: "",
        status: "pending",
        commentCount: 0,
        submittedAt: FieldValue.serverTimestamp(),
      });
    }

    await db.collection(Collections.HOMEWORK).doc(homeworkId).update({
      submittedBy: FieldValue.arrayUnion(studentUid),
    });

    const hwDoc = await getDoc(Collections.HOMEWORK, homeworkId);
    const studentDoc = await getDoc(Collections.USERS, studentUid);
    logActivity({
      type: "homeworkSubmitted",
      actorUid: studentUid,
      actorName: studentDoc?.name || "",
      actorRole: "Student",
      targetUid: studentUid,
      classId: hwDoc?.classId || "",
      title: `Submitted: ${hwDoc?.title || "Homework"}`,
    });

    invalidateDashboards("homework_");
    res.json({ homeworkId, submitted: true });
  })
);

router.post(
  "/homework/:homeworkId/submissions/:studentUid/comments",
  asyncHandler(async (req, res) => {
    const homeworkId = req.params.homeworkId as string;
    const studentUid = req.params.studentUid as string;
    const uid = req.uid!;
    const role = req.role!;
    const { text } = req.body;
    if (!text || typeof text !== "string")
      return res.status(400).json({ error: "text required" });

    const isTeacher = role === "Teacher" || role === "Principal";
    let isOwner = uid === studentUid;
    if (!isOwner && role === "Parent") {
      const parentDoc = await getDoc(Collections.USERS, uid);
      const childNames: string[] = ((parentDoc?.children || []) as Array<{ childName: string }>).map((c) => c.childName);
      const studentDoc = await getDoc(Collections.USERS, studentUid);
      isOwner = !!studentDoc && childNames.includes(studentDoc.name);
    }
    if (!isTeacher && !isOwner)
      return res.status(403).json({ error: "Forbidden" });

    const subId = `${homeworkId}_${studentUid}`;
    const subRef = db.collection(Collections.HOMEWORK_SUBMISSIONS).doc(subId);
    const subSnap = await subRef.get();
    if (!subSnap.exists) {
      await subRef.set({
        homeworkId,
        studentUid,
        files: [],
        note: "",
        status: "pending",
        commentCount: 0,
        submittedAt: FieldValue.serverTimestamp(),
      });
    }

    const userDoc = await getDoc(Collections.USERS, uid);
    const authorName = userDoc?.name || "";
    const ref = await db.collection(Collections.HOMEWORK_COMMENTS).add({
      submissionId: subId,
      authorUid: uid,
      authorName,
      authorRole: role,
      text,
      createdAt: FieldValue.serverTimestamp(),
    });

    await subRef.update({ commentCount: FieldValue.increment(1) });

    const hwDoc = await getDoc(Collections.HOMEWORK, homeworkId);
    notify({
      event: "homeworkComment",
      ctx: {
        homeworkId,
        studentUid,
        authorUid: uid,
        authorName,
        teacherUid: hwDoc?.teacherUid || "",
        homeworkTitle: hwDoc?.title || "Homework",
      },
    });

    res.json({ id: ref.id, created: true });
  })
);

router.get(
  "/homework/:homeworkId/submissions/:studentUid/comments",
  asyncHandler(async (req, res) => {
    const homeworkId = req.params.homeworkId as string;
    const studentUid = req.params.studentUid as string;
    const uid = req.uid!;
    const role = req.role!;

    const isTeacher = role === "Teacher" || role === "Principal";
    let isOwner = uid === studentUid;
    if (!isOwner && role === "Parent") {
      const parentDoc = await getDoc(Collections.USERS, uid);
      const childNames: string[] = ((parentDoc?.children || []) as Array<{ childName: string }>).map((c) => c.childName);
      const studentDoc = await getDoc(Collections.USERS, studentUid);
      isOwner = !!studentDoc && childNames.includes(studentDoc.name);
    }
    if (!isTeacher && !isOwner)
      return res.status(403).json({ error: "Forbidden" });

    const subId = `${homeworkId}_${studentUid}`;
    const snap = await db.collection(Collections.HOMEWORK_COMMENTS)
      .where("submissionId", "==", subId)
      .orderBy("createdAt", "asc")
      .get();

    const comments = snap.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        ...data,
        createdAt: data.createdAt?.toDate?.()?.toISOString?.() || null,
      };
    });

    res.json({ comments });
  })
);

router.patch(
  "/homework/:homeworkId/submissions/:studentUid/status",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const homeworkId = req.params.homeworkId as string;
    const studentUid = req.params.studentUid as string;
    const { status } = req.body;
    if (!["accepted", "returned"].includes(status))
      return res.status(400).json({ error: "status must be 'accepted' or 'returned'" });

    const subRef = db
      .collection(Collections.HOMEWORK_SUBMISSIONS)
      .doc(`${homeworkId}_${studentUid}`);
    const snap = await subRef.get();
    if (!snap.exists) return res.status(404).json({ error: "Submission not found" });

    await subRef.update({ status });

    const hwDoc = await getDoc(Collections.HOMEWORK, homeworkId);
    notify({
      event: "homeworkStatusChanged",
      ctx: {
        homeworkId,
        studentUid,
        classId: hwDoc?.classId || "",
        title: hwDoc?.title || "Homework",
        status,
      },
    });

    invalidateDashboards("homework_");
    res.json({ updated: true, status });
  })
);

export default router;
