import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth } from "../middleware/auth";
import { db, getDoc, getDocs, queryDocs, serializeDoc, serializeDocs } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { Config } from "../lib/config";

async function autoLinkParentByEmail(uid: string, email: string): Promise<void> {
  const studentSnap = await db.collection(Collections.STUDENTS)
    .where("parentEmail", "==", email).get();
  if (studentSnap.empty) return;

  const classIdSet = new Set<string>();
  const childEntries: Record<string, unknown>[] = [];

  for (const doc of studentSnap.docs) {
    const s = doc.data();
    const studentClassIds: string[] = s.classIds || [];
    for (const cid of studentClassIds) classIdSet.add(cid);

    const classDocs = studentClassIds.length > 0
      ? await getDocs(Collections.CLASSES, studentClassIds)
      : [];

    if (classDocs.length > 0) {
      for (const cls of classDocs as any[]) {
        childEntries.push({
          childName: s.name,
          classId: cls.id,
          className: cls.name || "",
          subject: cls.subject || "",
          teacherName: cls.teacherName || "",
          teacherUid: cls.teacherUid || "",
          teacherEmail: cls.teacherEmail || "",
        });
      }
    } else {
      childEntries.push({ childName: s.name, classId: "", className: "", subject: "", teacherName: "", teacherUid: "", teacherEmail: "" });
    }
  }

  if (childEntries.length === 0) return;

  const updates: Record<string, unknown> = {
    children: FieldValue.arrayUnion(...childEntries),
  };
  if (classIdSet.size > 0) {
    updates.classIds = FieldValue.arrayUnion(...Array.from(classIdSet));
  }
  await db.collection(Collections.USERS).doc(uid).update(updates);

  for (const cid of classIdSet) {
    await db.collection(Collections.CLASSES).doc(cid).update({
      parentUids: FieldValue.arrayUnion(uid),
    });
  }
}

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

    if (role === "Parent") {
      await autoLinkParentByEmail(uid, email);
    }

    res.json({ uid, created: true });
  })
);

router.post(
  "/user/fcm-token",
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const { token } = req.body;
    if (!token || typeof token !== "string")
      return res.status(400).json({ error: "token required" });

    await db.collection(Collections.USERS).doc(uid).update({ fcmToken: token });
    res.json({ updated: true });
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
