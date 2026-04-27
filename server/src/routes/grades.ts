import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, getDoc } from "../lib/firestore-helpers";
import { invalidateDashboards } from "../lib/cache-invalidation";
import { asyncHandler } from "../lib/async-handler";
import { deleteDocument } from "../lib/crud-helpers";
import { Collections } from "../lib/collections";
import { Config } from "../lib/config";
import { logActivity } from "../lib/activity-logger";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

router.post(
  "/grade",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { studentUid, studentName, classId, subject, assessmentName, score, total, testDate } = req.body;
    if (!studentUid || !classId || !subject || !assessmentName)
      return res.status(400).json({ error: "studentUid, classId, subject, assessmentName required" });

    const existing = await db.collection(Collections.GRADES)
      .where("studentUid", "==", studentUid)
      .where("classId", "==", classId)
      .where("assessmentName", "==", assessmentName)
      .limit(1).get();

    const testDateValue = testDate ? new Date(testDate) : null;

    if (!existing.empty) {
      const updateData: Record<string, any> = {
        score: score || 0,
        total: total || Config.DEFAULT_SCORE_TOTAL,
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (testDateValue) updateData.testDate = testDateValue;
      await existing.docs[0].ref.update(updateData);
      res.json({ id: existing.docs[0].id, updated: true });
    } else {
      const docData: Record<string, any> = {
        studentUid,
        studentName: studentName || "",
        classId,
        subject,
        assessmentName,
        score: score || 0,
        total: total || Config.DEFAULT_SCORE_TOTAL,
        teacherUid: req.uid,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (testDateValue) docData.testDate = testDateValue;
      const ref = await db.collection(Collections.GRADES).add(docData);
      res.json({ id: ref.id, created: true });
    }

    const teacherDoc = await getDoc(Collections.USERS, req.uid!);
    logActivity({
      type: "gradeEntered",
      actorUid: req.uid!,
      actorName: teacherDoc?.name || "",
      actorRole: req.role || "Teacher",
      targetUid: studentUid,
      classId,
      title: `Grade entered: ${assessmentName}`,
      body: `${subject} — ${score}/${total || Config.DEFAULT_SCORE_TOTAL}`,
      metadata: { assessmentName, subject, score, total: total || Config.DEFAULT_SCORE_TOTAL },
    });

    invalidateDashboards("grades_");
  })
);

router.delete(
  "/grade/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    await deleteDocument(
      Collections.GRADES,
      req.params.id as string,
      res,
      ["student_dash_", "teacher_dash_"]
    );
  })
);

router.post(
  "/test-title",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { title, subject, total } = req.body;
    if (!title) return res.status(400).json({ error: "title required" });

    const existing = await db.collection(Collections.TEST_TITLES)
      .where("teacherUid", "==", req.uid)
      .where("title", "==", title)
      .limit(1).get();
    if (!existing.empty) {
      return res.json({ id: existing.docs[0].id, exists: true });
    }

    const ref = await db.collection(Collections.TEST_TITLES).add({
      teacherUid: req.uid,
      title,
      subject: subject || "",
      total: total || Config.DEFAULT_SCORE_TOTAL,
      createdAt: FieldValue.serverTimestamp(),
    });
    invalidateDashboards("grades_");
    res.json({ id: ref.id, created: true });
  })
);

router.delete(
  "/test-title/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    await deleteDocument(
      Collections.TEST_TITLES,
      req.params.id as string,
      res,
      ["teacher_dash_"]
    );
  })
);

export default router;
