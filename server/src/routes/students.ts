import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, queryDocs, serializeDocs } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { getDoc } from "../lib/firestore-helpers";
import { logActivity } from "../lib/activity-logger";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

router.post(
  "/student/enroll",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { name, rollNumber, grade, section, parentName, parentPhone, parentEmail, classIds } = req.body;
    if (!name)
      return res.status(400).json({ error: "name required" });

    const ref = await db.collection(Collections.STUDENTS).add({
      name,
      rollNumber: rollNumber || "",
      grade: grade || "",
      section: section || "",
      parentName: parentName || "",
      parentPhone: parentPhone || "",
      parentEmail: parentEmail || "",
      classIds: classIds || [],
      enrolledBy: req.uid,
      createdAt: FieldValue.serverTimestamp(),
    });

    const teacherDoc = await getDoc(Collections.USERS, req.uid!);
    logActivity({
      type: "studentEnrolled",
      actorUid: req.uid!,
      actorName: teacherDoc?.name || "",
      actorRole: req.role || "Teacher",
      title: `Enrolled: ${name}`,
      body: grade && section ? `Grade ${grade} — Section ${section}` : "",
      metadata: { studentName: name, grade, section },
    });

    res.json({ id: ref.id, enrolled: true });
  })
);

router.patch(
  "/student/parent-email",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { studentName, parentEmail } = req.body;
    if (!studentName)
      return res.status(400).json({ error: "studentName required" });

    const snap = await db.collection(Collections.STUDENTS)
      .where("name", "==", studentName).limit(1).get();
    if (snap.empty)
      return res.status(404).json({ error: "Student record not found" });

    await snap.docs[0].ref.update({ parentEmail: parentEmail || "" });
    res.json({ updated: true });
  })
);

router.get(
  "/student/by-name",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const name = req.query.name as string;
    if (!name)
      return res.status(400).json({ error: "name query param required" });

    const snap = await db.collection(Collections.STUDENTS)
      .where("name", "==", name).limit(1).get();
    if (snap.empty)
      return res.json({ student: null });

    const doc = snap.docs[0];
    res.json({ student: { id: doc.id, ...doc.data() } });
  })
);

router.get(
  "/students",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (_req, res) => {
    const students = await queryDocs(Collections.STUDENTS, [], { field: "name", direction: "asc" });
    res.json({ students: serializeDocs(students) });
  })
);

export default router;
