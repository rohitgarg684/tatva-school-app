import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, serializeDocs } from "../lib/firestore-helpers";
import { invalidateDashboards } from "../lib/cache-invalidation";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { getDoc } from "../lib/firestore-helpers";
import { logActivity } from "../lib/activity-logger";

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

    const teacherDoc = await getDoc(Collections.USERS, req.uid!);
    const teacherName = teacherDoc?.name || "";
    for (const rec of records) {
      logActivity({
        type: "attendance",
        actorUid: req.uid!,
        actorName: teacherName,
        actorRole: req.role || "Teacher",
        targetUid: rec.studentUid,
        title: `Attendance: ${rec.status || "Present"}`,
        body: rec.date,
        metadata: { date: rec.date, status: rec.status || "Present" },
      });
    }

    invalidateDashboards("attendance_");
    res.json({ marked: records.length });
  })
);

router.get(
  "/attendance/:date",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const date = req.params.date as string;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return res.status(400).json({ error: "Invalid date format, use YYYY-MM-DD" });
    }
    const snap = await db
      .collection(Collections.ATTENDANCE)
      .where("date", "==", date)
      .get();
    const records = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    res.json({ records: serializeDocs(records) });
  })
);

export default router;
