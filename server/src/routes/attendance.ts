import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";

const router = Router();
router.use(requireAuth);

router.post(
  "/attendance",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { records } = req.body;

    if (!Array.isArray(records) || records.length === 0) {
      return res.status(400).json({ error: "records array required" });
    }

    const batch = db.batch();
    for (const rec of records) {
      const docId = `${rec.studentUid}_${rec.date}`;
      const ref = db.collection(Collections.ATTENDANCE).doc(docId);
      batch.set(
        ref,
        {
          studentUid: rec.studentUid,
          studentName: rec.studentName || "",
          date: rec.date,
          status: rec.status || "Present",
          markedBy: req.uid,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
    await batch.commit();

    cacheDeletePrefix("teacher_dash_");
    res.json({ marked: records.length });
  })
);

export default router;
