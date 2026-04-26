import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";
import { asyncHandler } from "../lib/async-handler";
import { deleteDocument } from "../lib/crud-helpers";
import { Collections } from "../lib/collections";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

router.post(
  "/behavior-point",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const { studentUid, studentName, classId, categoryId, points, note } = req.body;

    if (!studentUid || !classId || !categoryId) {
      return res.status(400).json({ error: "studentUid, classId, categoryId required" });
    }

    const userSnap = await db.collection(Collections.USERS).doc(uid).get();
    const awardedByName = userSnap.data()?.name || "";

    const ref = await db.collection(Collections.BEHAVIOR_POINTS).add({
      studentUid,
      studentName: studentName || "",
      classId,
      categoryId,
      points: points || 1,
      awardedBy: uid,
      awardedByName,
      note: note || "",
      createdAt: FieldValue.serverTimestamp(),
    });

    cacheDeletePrefix("student_dash_");
    cacheDeletePrefix("teacher_dash_");
    res.json({ id: ref.id, awarded: true });
  })
);

router.delete(
  "/behavior-point/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    await deleteDocument(
      Collections.BEHAVIOR_POINTS,
      req.params.id as string,
      res,
      ["student_dash_", "teacher_dash_"]
    );
  })
);

export default router;
