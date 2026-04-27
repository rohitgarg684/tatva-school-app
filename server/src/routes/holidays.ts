import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, serializeDocs, serializeDoc } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { deleteDocument } from "../lib/crud-helpers";
import { Collections } from "../lib/collections";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

const VALID_TYPES = ["federal", "summer_break", "spring_break", "winter_break", "teacher_workday", "custom"];

router.post(
  "/holiday",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { name, startDate, endDate, type, description } = req.body;
    if (!name || !startDate || !endDate)
      return res.status(400).json({ error: "name, startDate, endDate required" });
    if (type && !VALID_TYPES.includes(type))
      return res.status(400).json({ error: `type must be one of: ${VALID_TYPES.join(", ")}` });

    const ref = await db.collection(Collections.HOLIDAYS).add({
      name,
      startDate,
      endDate,
      type: type || "custom",
      description: description || "",
      createdBy: req.uid,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    res.json({ id: ref.id, created: true });
  })
);

router.put(
  "/holiday/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const id = req.params.id as string;
    const ref = db.collection(Collections.HOLIDAYS).doc(id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: "Not found" });

    const { name, startDate, endDate, type, description } = req.body;
    if (type && !VALID_TYPES.includes(type))
      return res.status(400).json({ error: `type must be one of: ${VALID_TYPES.join(", ")}` });

    const updates: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
    if (name !== undefined) updates.name = name;
    if (startDate !== undefined) updates.startDate = startDate;
    if (endDate !== undefined) updates.endDate = endDate;
    if (type !== undefined) updates.type = type;
    if (description !== undefined) updates.description = description;

    await ref.update(updates);
    res.json({ id, updated: true });
  })
);

router.delete(
  "/holiday/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    await deleteDocument(Collections.HOLIDAYS, req.params.id as string, res);
  })
);

router.get(
  "/holidays",
  asyncHandler(async (req, res) => {
    const year = parseInt(req.query.year as string, 10);
    if (!year) return res.status(400).json({ error: "year query param required" });

    const startBound = `${year - 1}-08-01`;
    const endBound = `${year}-07-31`;

    const snap = await db.collection(Collections.HOLIDAYS)
      .where("startDate", ">=", startBound)
      .where("startDate", "<=", endBound)
      .orderBy("startDate", "asc")
      .get();

    const holidays = snap.docs.map((d) => serializeDoc({ id: d.id, ...d.data() }));
    res.json({ holidays });
  })
);

// ─── School Year Dates ──────────────────────────────────────────────

router.get(
  "/school-year-dates",
  asyncHandler(async (req, res) => {
    const year = parseInt(req.query.year as string, 10);
    if (!year) return res.status(400).json({ error: "year query param required" });

    const doc = await db.collection(Collections.SCHOOL_SETTINGS).doc(`${year}`).get();
    if (!doc.exists) return res.json({ firstDay: "", lastDay: "" });
    const data = doc.data()!;
    res.json({ firstDay: data.firstDay || "", lastDay: data.lastDay || "" });
  })
);

router.put(
  "/school-year-dates",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { year, firstDay, lastDay } = req.body;
    if (!year) return res.status(400).json({ error: "year required" });

    const updates: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
    if (firstDay !== undefined) updates.firstDay = firstDay;
    if (lastDay !== undefined) updates.lastDay = lastDay;

    await db.collection(Collections.SCHOOL_SETTINGS).doc(`${year}`).set(updates, { merge: true });
    res.json({ year, updated: true });
  })
);

export default router;
