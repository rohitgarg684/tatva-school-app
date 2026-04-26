import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, getDoc, serializeDocs } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";
import { asyncHandler } from "../lib/async-handler";
import { deleteDocument } from "../lib/crud-helpers";
import { Collections } from "../lib/collections";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

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

    cacheDeletePrefix("teacher_dash_");
    cacheDeletePrefix("student_dash_");
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
      ["teacher_dash_", "student_dash_"]
    );
  })
);

router.post(
  "/homework/:homeworkId/submit",
  requireRole("Student"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const homeworkId = req.params.homeworkId as string;

    await db.collection(Collections.HOMEWORK).doc(homeworkId).update({
      submittedBy: FieldValue.arrayUnion(uid),
    });

    const subRef = db
      .collection(Collections.HOMEWORK_SUBMISSIONS)
      .doc(`${homeworkId}_${uid}`);
    const subSnap = await subRef.get();
    if (!subSnap.exists) {
      await subRef.set({
        homeworkId,
        studentUid: uid,
        files: [],
        note: "",
        submittedAt: FieldValue.serverTimestamp(),
      });
    }

    cacheDeletePrefix("student_dash_");
    cacheDeletePrefix("teacher_dash_");
    res.json({ homeworkId, submitted: true });
  })
);

export default router;
