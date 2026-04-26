import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth } from "../middleware/auth";
import { db, getDoc, queryDocs, serializeDoc, serializeDocs } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { Config } from "../lib/config";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

router.get(
  "/user/:uid",
  asyncHandler(async (req, res) => {
    const doc = await getDoc(Collections.USERS, req.params.uid as string);
    if (!doc) return res.status(404).json({ error: "User not found" });
    res.json(serializeDoc(doc));
  })
);

router.post(
  "/user",
  asyncHandler(async (req, res) => {
    const { uid, name, email, role } = req.body;
    if (!uid || !name || !email || !role)
      return res.status(400).json({ error: "uid, name, email, role required" });

    await db.collection(Collections.USERS).doc(uid).set({
      uid, name, email, role,
      classIds: [],
      children: [],
      createdAt: FieldValue.serverTimestamp(),
    });

    await admin.auth().setCustomUserClaims(uid, { role });
    res.json({ uid, created: true });
  })
);

router.get(
  "/report/weekly",
  asyncHandler(async (req, res) => {
    const { studentUid, startDate, endDate } = req.query as Record<string, string>;
    if (!studentUid)
      return res.status(400).json({ error: "studentUid required" });

    const start = startDate || new Date(Date.now() - Config.WEEKLY_REPORT_MS).toISOString().slice(0, 10);
    const end = endDate || new Date().toISOString().slice(0, 10);

    const [grades, behavior, attendance] = await Promise.all([
      queryDocs(Collections.GRADES, [{ field: "studentUid", op: "==", value: studentUid }]),
      queryDocs(Collections.BEHAVIOR_POINTS, [{ field: "studentUid", op: "==", value: studentUid }]),
      queryDocs(Collections.ATTENDANCE, [
        { field: "studentUid", op: "==", value: studentUid },
        { field: "date", op: ">=", value: start },
        { field: "date", op: "<=", value: end },
      ]),
    ]);

    res.json({
      grades: serializeDocs(grades),
      behaviorPoints: serializeDocs(behavior),
      attendance: serializeDocs(attendance),
    });
  })
);

export default router;
