import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth } from "../middleware/auth";
import { db, getDoc, getDocs, queryDocs, serializeDoc, serializeDocs } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { Config } from "../lib/config";

export type ChildEntry = {
  childName: string; childUid: string; classId: string; className: string;
  subject: string; teacherName: string; teacherUid: string; teacherEmail: string;
};

function childKey(c: ChildEntry): string {
  return `${c.childName}::${c.classId}`;
}

export function isParentOfChild(children: ChildEntry[], targetUid: string): boolean {
  return children.some((c) => c.childUid === targetUid);
}

export function deduplicateChildren(existing: ChildEntry[], incoming: ChildEntry[]): ChildEntry[] {
  const incomingKeys = new Set(incoming.map(childKey));
  const kept = existing.filter((e) => !incomingKeys.has(childKey(e)));
  const seen = new Set<string>();
  const result: ChildEntry[] = [];
  for (const entry of [...incoming, ...kept]) {
    const key = childKey(entry);
    if (!seen.has(key)) {
      seen.add(key);
      result.push(entry);
    }
  }
  return result;
}

async function resolveStudentUids(
  studentNames: string[]
): Promise<Map<string, string>> {
  if (studentNames.length === 0) return new Map();
  const chunks: string[][] = [];
  for (let i = 0; i < studentNames.length; i += Config.FIRESTORE_IN_LIMIT) {
    chunks.push(studentNames.slice(i, i + Config.FIRESTORE_IN_LIMIT));
  }
  const results = await Promise.all(
    chunks.map((names) =>
      queryDocs(Collections.USERS, [
        { field: "role", op: "==", value: "Student" },
        { field: "name", op: "in", value: names },
      ])
    )
  );
  return new Map(results.flat().map((u: any) => [u.name, u.id]));
}

async function buildChildEntriesFromStudents(
  studentSnap: FirebaseFirestore.QuerySnapshot
): Promise<{ entries: ChildEntry[]; classIds: Set<string> }> {
  const entries: ChildEntry[] = [];
  const classIds = new Set<string>();

  const names = studentSnap.docs.map((d) => d.data().name as string).filter(Boolean);
  const nameToUid = await resolveStudentUids([...new Set(names)]);

  for (const doc of studentSnap.docs) {
    const s = doc.data();
    const resolvedUid = nameToUid.get(s.name) || "";
    const studentClassIds: string[] = s.classIds || [];
    for (const cid of studentClassIds) classIds.add(cid);

    const classDocs = studentClassIds.length > 0
      ? await getDocs(Collections.CLASSES, studentClassIds) : [];

    if (classDocs.length > 0) {
      for (const cls of classDocs as any[]) {
        entries.push({
          childName: s.name, childUid: resolvedUid, classId: cls.id,
          className: cls.name || "", subject: cls.subject || "",
          teacherName: cls.teacherName || "", teacherUid: cls.teacherUid || "",
          teacherEmail: cls.teacherEmail || "",
        });
      }
    } else {
      entries.push({
        childName: s.name, childUid: resolvedUid, classId: "", className: "", subject: "",
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
  "/users/by-role",
  asyncHandler(async (req, res) => {
    const role = req.query.role as string;
    if (!role) return res.status(400).json({ error: "role query param required" });
    const docs = await queryDocs(Collections.USERS, [{ field: "role", op: "==", value: role }]);
    res.json({ users: serializeDocs(docs) });
  })
);

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

    if (uid !== req.uid)
      return res.status(403).json({ error: "You can only create your own profile" });

    const validRoles = ["Teacher", "Parent", "Principal"];
    if (!validRoles.includes(role))
      return res.status(400).json({ error: "Invalid role" });

    const existing = await getDoc(Collections.USERS, uid);
    if (existing)
      return res.status(409).json({ error: "User already exists" });

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

    const callerRole = req.role!;
    const callerUid = req.uid!;
    if (callerRole === "Student" && callerUid !== studentUid)
      return res.status(403).json({ error: "Forbidden" });
    if (callerRole === "Parent") {
      const callerDoc = await getDoc(Collections.USERS, callerUid);
      const children: ChildEntry[] = callerDoc?.children || [];
      if (!isParentOfChild(children, studentUid))
        return res.status(403).json({ error: "Forbidden" });
    }

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
