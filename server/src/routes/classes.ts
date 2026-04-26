import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, getDoc } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

router.post(
  "/class",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { name, subject, classCode } = req.body;
    if (!name || !subject || !classCode)
      return res.status(400).json({ error: "name, subject, classCode required" });

    const uid = req.uid!;
    const userDoc = await getDoc(Collections.USERS, uid);
    const teacherName = userDoc?.name || "";
    const teacherEmail = userDoc?.email || "";

    const existing = await db.collection(Collections.CLASSES)
      .where("classCode", "==", classCode).limit(1).get();
    if (!existing.empty)
      return res.status(409).json({ error: "Class code already in use" });

    const ref = await db.collection(Collections.CLASSES).add({
      name, subject, classCode,
      teacherUid: uid,
      teacherName,
      teacherEmail,
      studentUids: [],
      parentUids: [],
      createdAt: FieldValue.serverTimestamp(),
    });

    await db.collection(Collections.USERS).doc(uid).update({
      classIds: FieldValue.arrayUnion(ref.id),
    });

    cacheDeletePrefix("teacher_dash_");
    res.json({ id: ref.id, created: true });
  })
);

router.delete(
  "/class/:classId",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const classId = req.params.classId as string;
    const uid = req.uid!;
    const role = req.role;

    const classDoc = await db.collection(Collections.CLASSES).doc(classId).get();
    if (!classDoc.exists)
      return res.status(404).json({ error: "Class not found" });

    const classData = classDoc.data()!;

    if (role === "Teacher" && classData.teacherUid !== uid)
      return res.status(403).json({ error: "You can only delete your own classes" });

    const batch = db.batch();
    batch.delete(classDoc.ref);

    if (classData.teacherUid) {
      batch.update(db.collection(Collections.USERS).doc(classData.teacherUid), {
        classIds: FieldValue.arrayRemove(classId),
      });
    }

    const memberUids = [
      ...(classData.studentUids || []),
      ...(classData.parentUids || []),
    ];
    for (const memberId of memberUids) {
      batch.update(db.collection(Collections.USERS).doc(memberId), {
        classIds: FieldValue.arrayRemove(classId),
      });
    }

    await batch.commit();

    cacheDeletePrefix("teacher_dash_");
    cacheDeletePrefix("principal_dash_");
    cacheDeletePrefix("student_dash_");
    cacheDeletePrefix("parent_dash_");
    res.json({ id: classId, deleted: true });
  })
);

router.post(
  "/class/join",
  asyncHandler(async (req, res) => {
    const { classCode, childName } = req.body;
    if (!classCode)
      return res.status(400).json({ error: "classCode required" });

    const uid = req.uid!;
    const role = req.role;
    const snap = await db.collection(Collections.CLASSES)
      .where("classCode", "==", classCode).limit(1).get();
    if (snap.empty)
      return res.status(404).json({ error: "Class not found" });

    const classDoc = snap.docs[0];
    const classId = classDoc.id;
    const classData = classDoc.data();

    if (role === "Student") {
      await classDoc.ref.update({
        studentUids: FieldValue.arrayUnion(uid),
      });
    } else if (role === "Parent") {
      await classDoc.ref.update({
        parentUids: FieldValue.arrayUnion(uid),
      });
      if (childName) {
        await db.collection(Collections.USERS).doc(uid).update({
          children: FieldValue.arrayUnion({
            childName,
            classId,
            className: classData.name,
            subject: classData.subject,
            teacherName: classData.teacherName,
            teacherUid: classData.teacherUid,
            teacherEmail: classData.teacherEmail,
          }),
        });
      }
    }

    await db.collection(Collections.USERS).doc(uid).update({
      classIds: FieldValue.arrayUnion(classId),
    });

    cacheDeletePrefix("student_dash_");
    cacheDeletePrefix("parent_dash_");
    cacheDeletePrefix("teacher_dash_");
    res.json({ classId, joined: true });
  })
);

export default router;
