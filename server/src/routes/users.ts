import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth } from "../middleware/auth";
import { db, getDoc, getDocs, queryDocs, serializeDoc, serializeDocs } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { Config } from "../lib/config";

type ChildEntry = {
  childName: string; classId: string; className: string;
  subject: string; teacherName: string; teacherUid: string; teacherEmail: string;
};

function childKey(c: ChildEntry): string {
  return `${c.childName}::${c.classId}`;
}

function deduplicateChildren(existing: ChildEntry[], incoming: ChildEntry[]): ChildEntry[] {
  const seen = new Set(existing.map(childKey));
  const merged = [...existing];
  for (const entry of incoming) {
    const key = childKey(entry);
    if (!seen.has(key)) {
      seen.add(key);
      merged.push(entry);
    }
  }
  return merged;
}

async function buildChildEntriesFromStudents(
  studentSnap: FirebaseFirestore.QuerySnapshot
): Promise<{ entries: ChildEntry[]; classIds: Set<string> }> {
  const entries: ChildEntry[] = [];
  const classIds = new Set<string>();

  for (const doc of studentSnap.docs) {
    const s = doc.data();
    const studentClassIds: string[] = s.classIds || [];
    for (const cid of studentClassIds) classIds.add(cid);

    const classDocs = studentClassIds.length > 0
      ? await getDocs(Collections.CLASSES, studentClassIds) : [];

    if (classDocs.length > 0) {
      for (const cls of classDocs as any[]) {
        entries.push({
          childName: s.name, classId: cls.id,
          className: cls.name || "", subject: cls.subject || "",
          teacherName: cls.teacherName || "", teacherUid: cls.teacherUid || "",
          teacherEmail: cls.teacherEmail || "",
        });
      }
    } else {
      entries.push({
        childName: s.name, classId: "", className: "", subject: "",
        teacherName: "", teacherUid: "", teacherEmail: "",
      });
    }
  }
  return { entries, classIds };
}

async function autoLinkParentByEmail(uid: string, email: string): Promise<void> {
  const studentSnap = await db.collection(Collections.STUDENTS)
    .where("parentEmail", "==", email).get();
  if (studentSnap.empty) return;

  const userDoc = await getDoc(Collections.USERS, uid);
  const existingChildren: ChildEntry[] = userDoc?.children || [];
  const existingClassIds: string[] = userDoc?.classIds || [];

  const { entries, classIds } = await buildChildEntriesFromStudents(studentSnap);
  const merged = deduplicateChildren(existingChildren, entries);
  if (merged.length === existingChildren.length) return;

  const allClassIds = [...new Set([...existingClassIds, ...classIds])];
  await db.collection(Collections.USERS).doc(uid).update({
    children: merged,
    classIds: allClassIds,
  });

  for (const cid of classIds) {
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
