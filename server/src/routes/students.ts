import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, queryDocs, serializeDocs } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { getDoc } from "../lib/firestore-helpers";
import { logActivity } from "../lib/activity-logger";
import { invalidateDashboards } from "../lib/cache-invalidation";
import { type ChildEntry } from "./users";

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

    const studentDoc = snap.docs[0];
    const oldEmail = (studentDoc.data().parentEmail || "") as string;

    await studentDoc.ref.update({ parentEmail: parentEmail || "" });

    // Revoke old parent's access if email changed
    if (oldEmail && oldEmail !== (parentEmail || "")) {
      const oldParentSnap = await db.collection(Collections.USERS)
        .where("email", "==", oldEmail)
        .where("role", "==", "Parent")
        .limit(1).get();
      if (!oldParentSnap.empty) {
        const oldParent = oldParentSnap.docs[0];
        const children: ChildEntry[] = oldParent.data().children || [];
        const filtered = children.filter((c) => c.childName !== studentName);
        const removedClassIds = children
          .filter((c) => c.childName === studentName)
          .map((c) => c.classId)
          .filter(Boolean);
        const remainingClassIds = [...new Set(filtered.map((c) => c.classId).filter(Boolean))];
        await oldParent.ref.update({
          children: filtered,
          classIds: remainingClassIds,
        });
        for (const cid of removedClassIds) {
          const hasOtherChildInClass = filtered.some((c) => c.classId === cid);
          if (!hasOtherChildInClass) {
            await db.collection(Collections.CLASSES).doc(cid).update({
              parentUids: FieldValue.arrayRemove(oldParent.id),
            });
          }
        }
      }
    }

    invalidateDashboards("parent_dash_");
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
