import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import {
  db,
  getDoc,
  getDocs,
  queryDocs,
  serializeDocs,
  serializeDoc,
} from "../lib/firestore-helpers";
import { cacheGet, cacheSet, SHARED_TTL, USER_TTL } from "../lib/cache";
import { asyncHandler } from "../lib/async-handler";
import {
  filterAnnouncementsByGrade,
  computeBehaviorScore,
  computeSubjectAverages,
  type AnnouncementDoc,
  type BehaviorPointDoc,
  type GradeDoc,
  type ClassDoc,
  type StudentDoc,
  type AttendanceDoc,
  type ContentDoc,
  type ActivityDoc,
} from "../lib/dashboard-helpers";
import { Collections } from "../lib/collections";
import { Config } from "../lib/config";
import * as admin from "firebase-admin";
import { type ChildEntry, isParentOfChild, deduplicateChildren } from "./users";

const FieldValue = admin.firestore.FieldValue;

const router = Router();
router.use(requireAuth);

// ─── Access control helpers ─────────────────────────────────────────────────

async function callerSharesClassWith(callerUid: string, targetUid: string): Promise<boolean> {
  const [callerDoc, targetDoc] = await Promise.all([
    getDoc(Collections.USERS, callerUid),
    getDoc(Collections.USERS, targetUid),
  ]);
  if (!callerDoc || !targetDoc) return false;
  const callerClasses: string[] = callerDoc.classIds || [];
  const targetClasses: string[] = targetDoc.classIds || [];
  return callerClasses.some((c) => targetClasses.includes(c));
}

async function callerIsParentOf(callerUid: string, childUid: string): Promise<boolean> {
  const callerDoc = await getDoc(Collections.USERS, callerUid);
  if (!callerDoc || !callerDoc.children) return false;
  return isParentOfChild(callerDoc.children as ChildEntry[], childUid);
}

async function fetchShared<T>(key: string, fetcher: () => Promise<T>): Promise<T> {
  const cached = cacheGet<T>(key);
  if (cached) return cached;
  const data = await fetcher();
  cacheSet(key, data, SHARED_TTL);
  return data;
}

async function safe<T>(promise: Promise<T>, fallback: T): Promise<T> {
  try {
    return await promise;
  } catch (err) {
    console.warn("Non-fatal query error (using fallback):", (err as Error)?.message || err);
    return fallback;
  }
}


// ─── Student Dashboard ──────────────────────────────────────────────────────

router.get(
  "/student/:uid",
  asyncHandler(async (req, res) => {
    const uid = (req.params.uid as string) || req.uid!;
    const callerUid = req.uid!;
    const role = req.role;

    if (role === "Student" && callerUid !== uid) {
      return res.status(403).json({ error: "Students can only view their own dashboard" });
    }
    if (role === "Teacher" && callerUid !== uid) {
      const shared = await callerSharesClassWith(callerUid, uid);
      if (!shared) return res.status(403).json({ error: "Forbidden: student not in your class" });
    }
    if (role === "Parent" && callerUid !== uid) {
      const isParent = await callerIsParentOf(callerUid, uid);
      if (!isParent) return res.status(403).json({ error: "Forbidden: not your child" });
    }

    const cacheKey = `student_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return res.json(cached);

    const user = await getDoc(Collections.USERS, uid);
    if (!user) return res.status(404).json({ error: "User not found" });

    const classIds: string[] = user.classIds || [];
    const inLimit = classIds.slice(0, Config.FIRESTORE_IN_LIMIT);

    const [
      primaryClass, grades, announcements, homework, votes,
      behaviorPoints, attendance, activityFeed, contentItems,
    ] = await Promise.all([
      safe(classIds.length > 0 ? getDoc(Collections.CLASSES, classIds[0]) : Promise.resolve(null), null),
      safe(queryDocs(Collections.GRADES, [{ field: "studentUid", op: "==", value: uid }], { field: "createdAt" }), []),
      safe(fetchShared("announcements_all", () =>
        queryDocs(Collections.ANNOUNCEMENTS, [], { field: "createdAt", direction: "desc" }, Config.ANNOUNCEMENTS_LIMIT)
      ), []),
      safe(classIds.length > 0
        ? queryDocs(Collections.HOMEWORK, [{ field: "classId", op: "in", value: inLimit }], { field: "createdAt", direction: "desc" })
        : Promise.resolve([]), []),
      safe(fetchShared("votes_visible", () =>
        queryDocs(Collections.VOTES, [{ field: "resultsVisibleUntil", op: ">=", value: new Date().toISOString() }], { field: "resultsVisibleUntil" })
      ), []),
      safe(queryDocs(Collections.BEHAVIOR_POINTS, [{ field: "studentUid", op: "==", value: uid }], { field: "createdAt", direction: "desc" }), []),
      safe(queryDocs(Collections.ATTENDANCE, [{ field: "studentUid", op: "==", value: uid }], { field: "date", direction: "desc" }), []),
      safe(queryDocs(Collections.ACTIVITIES, [{ field: "targetUid", op: "==", value: uid }], { field: "createdAt", direction: "desc" }, Config.ACTIVITY_FEED_LIMIT), []),
      safe(fetchShared("content_all", () =>
        queryDocs(Collections.CONTENT, [], { field: "createdAt", direction: "desc" })
      ), []),
    ]);

    const userGrade = (primaryClass as any)?.grade || "";
    const userGrades = userGrade ? [userGrade] : [];
    const filteredAnnouncements = filterAnnouncementsByGrade(announcements as any[], userGrades);

    const filteredContent = (contentItems as ContentDoc[]).filter((c) => {
      const hasGrade = c.grade && c.grade.length > 0;
      const stuIds = c.studentUids || [];
      const hasStudents = stuIds.length > 0;
      if (!hasGrade && !hasStudents) return true;
      if (hasStudents && stuIds.includes(uid)) return true;
      if (hasGrade && userGrade && c.grade === userGrade) return true;
      return false;
    });

    const result = {
      user: serializeDoc(user),
      primaryClass: serializeDoc(primaryClass),
      grades: serializeDocs(grades),
      announcements: serializeDocs(filteredAnnouncements.slice(0, Config.PRINCIPAL_ACTIVITY_LIMIT)),
      homework: serializeDocs(homework as any[]),
      activeVotes: serializeDocs(votes),
      behaviorPoints: serializeDocs(behaviorPoints),
      behaviorScore: computeBehaviorScore(behaviorPoints),
      attendance: serializeDocs(attendance),
      activityFeed: serializeDocs(activityFeed),
      contentItems: serializeDocs(filteredContent),
    };

    cacheSet(cacheKey, result, USER_TTL);
    res.json(result);
  })
);

// ─── Teacher Dashboard ──────────────────────────────────────────────────────

router.get(
  "/teacher/:uid",
  asyncHandler(async (req, res) => {
    const uid = (req.params.uid as string) || req.uid!;
    const callerUid = req.uid!;
    const role = req.role;

    if (role !== "Principal" && callerUid !== uid)
      return res.status(403).json({ error: "Forbidden" });
    if (role !== "Teacher" && role !== "Principal")
      return res.status(403).json({ error: "Forbidden: insufficient role" });

    const cacheKey = `teacher_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return res.json(cached);

    const user = await getDoc(Collections.USERS, uid);
    if (!user) return res.status(404).json({ error: "User not found" });

    const classIds: string[] = user.classIds || [];
    const classes = classIds.length > 0 ? await getDocs(Collections.CLASSES, classIds) : [];

    let studentsInFirstClass: StudentDoc[] = [];
    let parentsInFirstClass: StudentDoc[] = [];
    let gradesInFirstClass: GradeDoc[] = [];
    let classBehavior: BehaviorPointDoc[] = [];
    let todayAttendance: AttendanceDoc[] = [];
    let activityFeed: ActivityDoc[] = [];
    let allTeacherGrades: GradeDoc[] = [];
    let testTitles: { id: string; [key: string]: unknown }[] = [];

    if (classes.length > 0) {
      const first = classes[0] as any;
      const today = new Date().toISOString().substring(0, 10);

      const [students, parents, grades, behavior, att, activity] = await Promise.all([
        safe(getDocs(Collections.USERS, first.studentUids || []), []),
        safe(getDocs(Collections.USERS, first.parentUids || []), []),
        safe(queryDocs(Collections.GRADES, [{ field: "classId", op: "==", value: first.id }], { field: "createdAt" }), []),
        safe(queryDocs(Collections.BEHAVIOR_POINTS, [{ field: "classId", op: "==", value: first.id }], { field: "createdAt", direction: "desc" }), []),
        safe(queryDocs(Collections.ATTENDANCE, [{ field: "date", op: "==", value: today }]), []),
        safe(queryDocs(Collections.ACTIVITIES, [{ field: "classId", op: "==", value: first.id }], { field: "createdAt", direction: "desc" }, Config.ACTIVITY_FEED_LIMIT), []),
      ]);

      studentsInFirstClass = students as StudentDoc[];
      parentsInFirstClass = parents as StudentDoc[];
      gradesInFirstClass = grades;
      classBehavior = behavior;
      todayAttendance = att;
      activityFeed = activity;

      const allClassIds = (classes as ClassDoc[]).map((c) => c.id);
      const gradeArrays = await Promise.all(
        allClassIds.map((cid: string) =>
          safe(queryDocs(Collections.GRADES, [{ field: "classId", op: "==", value: cid }], { field: "createdAt" }), [])
        )
      );
      allTeacherGrades = gradeArrays.flat();
    }

    try {
      const ttSnap = await db.collection(Collections.TEST_TITLES)
        .where("teacherUid", "==", uid)
        .orderBy("createdAt", "desc")
        .get();
      testTitles = ttSnap.docs.map(d => serializeDoc({ id: d.id, ...d.data() }));
    } catch (err) {
      console.warn("Non-fatal: test_titles query failed:", (err as Error)?.message);
    }

    const [announcements, homework, allStudents, teacherContent, votes] = await Promise.all([
      safe(fetchShared("announcements_all", () =>
        queryDocs(Collections.ANNOUNCEMENTS, [], { field: "createdAt", direction: "desc" }, Config.ANNOUNCEMENTS_LIMIT)
      ), []),
      safe(queryDocs(Collections.HOMEWORK, [{ field: "teacherUid", op: "==", value: uid }], { field: "createdAt", direction: "desc" }), []),
      safe(fetchShared("all_students", () =>
        queryDocs(Collections.USERS, [{ field: "role", op: "==", value: "Student" }], { field: "name" })
      ), []),
      safe(queryDocs(Collections.CONTENT, [], { field: "createdAt", direction: "desc" }), []),
      safe(fetchShared("votes_visible", () =>
        queryDocs(Collections.VOTES, [{ field: "resultsVisibleUntil", op: ">=", value: new Date().toISOString() }], { field: "resultsVisibleUntil" })
      ), []),
    ]);

    const teacherGrades = (classes as ClassDoc[]).map((c) => c.grade).filter(Boolean) as string[];
    const filteredAnnouncements = filterAnnouncementsByGrade(announcements as any[], teacherGrades);

    const result = {
      user: serializeDoc(user),
      classes: serializeDocs(classes),
      studentsInFirstClass: serializeDocs(studentsInFirstClass),
      parentsInFirstClass: serializeDocs(parentsInFirstClass),
      gradesInFirstClass: serializeDocs(gradesInFirstClass),
      allTeacherGrades: serializeDocs(allTeacherGrades),
      testTitles,
      announcements: serializeDocs(filteredAnnouncements),
      homework: serializeDocs(homework),
      classBehavior: serializeDocs(classBehavior),
      todayAttendance: serializeDocs(todayAttendance),
      activityFeed: serializeDocs(activityFeed),
      allStudents: serializeDocs(allStudents),
      contentItems: serializeDocs(teacherContent),
      activeVotes: serializeDocs(votes),
    };

    cacheSet(cacheKey, result, USER_TTL);
    res.json(result);
  })
);

// ─── Parent Dashboard ───────────────────────────────────────────────────────

router.get(
  "/parent/:uid",
  asyncHandler(async (req, res) => {
    const uid = (req.params.uid as string) || req.uid!;
    const callerUid = req.uid!;
    const role = req.role;

    if (role !== "Principal" && callerUid !== uid)
      return res.status(403).json({ error: "Forbidden" });
    if (role !== "Parent" && role !== "Principal")
      return res.status(403).json({ error: "Forbidden: insufficient role" });

    let user = await getDoc(Collections.USERS, uid);
    if (!user) return res.status(404).json({ error: "User not found" });

    const cacheKey = `parent_dash_${uid}`;
    let didDedup = false;

    // Lazy auto-link: pick up students whose parentEmail matches this parent
    if (user.email) {
      const studentSnap = await db.collection(Collections.STUDENTS)
        .where("parentEmail", "==", user.email).get();
      if (!studentSnap.empty) {
        const existingChildren: ChildEntry[] = user.children || [];

        const incoming: ChildEntry[] = [];
        const newClassIds = new Set<string>();

        const names = studentSnap.docs.map((d) => d.data().name as string).filter(Boolean);
        const nameChunks: string[][] = [];
        const uniqueNames = [...new Set(names)];
        for (let i = 0; i < uniqueNames.length; i += Config.FIRESTORE_IN_LIMIT) {
          nameChunks.push(uniqueNames.slice(i, i + Config.FIRESTORE_IN_LIMIT));
        }
        const studentUserChunks = await Promise.all(
          nameChunks.map((n) =>
            queryDocs(Collections.USERS, [
              { field: "role", op: "==", value: "Student" },
              { field: "name", op: "in", value: n },
            ])
          )
        );
        const nameToUid = new Map(studentUserChunks.flat().map((u: any) => [u.name, u.id]));

        for (const doc of studentSnap.docs) {
          const s = doc.data();
          const resolvedUid = nameToUid.get(s.name) || "";
          const studentClassIds: string[] = s.classIds || [];
          const classDocs = studentClassIds.length > 0
            ? await getDocs(Collections.CLASSES, studentClassIds) : [];
          for (const cid of studentClassIds) newClassIds.add(cid);

          if (classDocs.length > 0) {
            for (const cls of classDocs as any[]) {
              incoming.push({
                childName: s.name, childUid: resolvedUid, classId: cls.id,
                className: cls.name || "", subject: cls.subject || "",
                teacherName: cls.teacherName || "", teacherUid: cls.teacherUid || "",
                teacherEmail: cls.teacherEmail || "",
              });
            }
          } else {
            incoming.push({ childName: s.name, childUid: resolvedUid, classId: "", className: "", subject: "", teacherName: "", teacherUid: "", teacherEmail: "" });
          }
        }

        const merged = deduplicateChildren(existingChildren, incoming);
        const changed = merged.length !== existingChildren.length ||
          merged.some((m, i) => m.childUid !== (existingChildren[i]?.childUid || ""));

        if (changed) {
          didDedup = true;
          const allClassIds = [...new Set([
            ...(user.classIds || []) as string[],
            ...newClassIds,
          ])];
          await db.collection(Collections.USERS).doc(uid).update({
            children: merged,
            classIds: allClassIds,
          });
          for (const cid of newClassIds) {
            await db.collection(Collections.CLASSES).doc(cid).update({
              parentUids: FieldValue.arrayUnion(uid),
            });
          }
          user = await getDoc(Collections.USERS, uid);
        }
      }
    }

    if (!didDedup) {
      const cached = cacheGet<any>(cacheKey);
      if (cached) return res.json(cached);
    }

    const children: ChildEntry[] = user!.children || [];
    const classIdSet = new Set<string>();
    const childrenData: { childUid: string; childPhotoUrl: string; info: unknown; childClass: unknown; grades: any[]; behaviorPoints: any[]; behaviorScore: number; attendance: any[]; homework: any[]; submissions: any[] }[] = [];

    const classIdsFromChildren = children.map((c) => c.classId).filter(Boolean);
    const childClasses = classIdsFromChildren.length > 0
      ? await getDocs(Collections.CLASSES, classIdsFromChildren)
      : [];
    const classMap = new Map((childClasses as ClassDoc[]).map((c) => [c.id, c]));

    const childUids = [...new Set(children.map((c) => c.childUid).filter(Boolean))];

    // Fetch child photo URLs in bulk
    const childUserDocs = childUids.length > 0
      ? await getDocs(Collections.USERS, childUids.slice(0, Config.FIRESTORE_IN_LIMIT))
      : [];
    const uidToPhoto = new Map((childUserDocs as any[]).map((u) => [u.id, u.photoUrl || ""]));

    const [allGrades, allBehavior, allAttendance, allHomework, allSubmissions] = await Promise.all([
      childUids.length > 0
        ? safe(queryDocs(Collections.GRADES, [{ field: "studentUid", op: "in", value: childUids.slice(0, Config.FIRESTORE_IN_LIMIT) }], { field: "createdAt" }), [])
        : Promise.resolve([]),
      childUids.length > 0
        ? safe(queryDocs(Collections.BEHAVIOR_POINTS, [{ field: "studentUid", op: "in", value: childUids.slice(0, Config.FIRESTORE_IN_LIMIT) }], { field: "createdAt", direction: "desc" }), [])
        : Promise.resolve([]),
      childUids.length > 0
        ? safe(queryDocs(Collections.ATTENDANCE, [{ field: "studentUid", op: "in", value: childUids.slice(0, Config.FIRESTORE_IN_LIMIT) }], { field: "date", direction: "desc" }), [])
        : Promise.resolve([]),
      classIdsFromChildren.length > 0
        ? safe(queryDocs(Collections.HOMEWORK, [{ field: "classId", op: "in", value: classIdsFromChildren.slice(0, Config.FIRESTORE_IN_LIMIT) }], { field: "createdAt", direction: "desc" }), [])
        : Promise.resolve([]),
      childUids.length > 0
        ? safe(queryDocs(Collections.HOMEWORK_SUBMISSIONS, [{ field: "studentUid", op: "in", value: childUids.slice(0, Config.FIRESTORE_IN_LIMIT) }]), [])
        : Promise.resolve([]),
    ]);

    const emittedStudentData = new Set<string>();
    for (const childInfo of children) {
      if (childInfo.classId) classIdSet.add(childInfo.classId);
      const cUid = childInfo.childUid || "";

      const classId = childInfo.classId;
      const homework = (allHomework as any[]).filter((h) => h.classId === classId);
      const isFirstEntryForChild = cUid && !emittedStudentData.has(cUid);
      if (cUid) emittedStudentData.add(cUid);

      if (cUid && isFirstEntryForChild) {
        const grades = (allGrades as GradeDoc[]).filter((g) => g.studentUid === cUid);
        const behavior = (allBehavior as BehaviorPointDoc[]).filter((b) => b.studentUid === cUid);
        const attendance = (allAttendance as AttendanceDoc[]).filter((a) => a.studentUid === cUid);
        const submissions = (allSubmissions as any[]).filter((s) => s.studentUid === cUid);

        childrenData.push({
          info: childInfo,
          childUid: cUid,
          childPhotoUrl: uidToPhoto.get(cUid) || "",
          childClass: serializeDoc(classMap.get(classId) || null),
          grades: serializeDocs(grades),
          behaviorPoints: serializeDocs(behavior),
          behaviorScore: computeBehaviorScore(behavior),
          attendance: serializeDocs(attendance),
          homework: serializeDocs(homework),
          submissions: serializeDocs(submissions),
        });
      } else {
        childrenData.push({
          info: childInfo,
          childUid: cUid,
          childPhotoUrl: cUid ? (uidToPhoto.get(cUid) || "") : "",
          childClass: serializeDoc(classMap.get(classId) || null),
          grades: [],
          behaviorPoints: [],
          behaviorScore: 0,
          attendance: [],
          homework: serializeDocs(homework),
          submissions: [],
        });
      }
    }

    const classIdList = Array.from(classIdSet);
    const firstChildUid = childrenData.length > 0 ? childrenData[0].childUid : "";

    const childGrades = (childClasses as ClassDoc[]).map((c) => c.grade).filter(Boolean) as string[];

    const [announcements, votes, activity, content] = await Promise.all([
      safe(fetchShared("announcements_all", () =>
        queryDocs(Collections.ANNOUNCEMENTS, [], { field: "createdAt", direction: "desc" }, Config.ANNOUNCEMENTS_LIMIT)
      ), []),
      safe(fetchShared("votes_visible", () =>
        queryDocs(Collections.VOTES, [{ field: "resultsVisibleUntil", op: ">=", value: new Date().toISOString() }], { field: "resultsVisibleUntil" })
      ), []),
      safe(firstChildUid
        ? queryDocs(Collections.ACTIVITIES, [{ field: "targetUid", op: "==", value: firstChildUid }], { field: "createdAt", direction: "desc" }, Config.ACTIVITY_FEED_LIMIT)
        : Promise.resolve([]), []),
      safe(fetchShared("content_all", () =>
        queryDocs(Collections.CONTENT, [], { field: "createdAt", direction: "desc" })
      ), []),
    ]);

    const filteredAnnouncements = filterAnnouncementsByGrade(announcements as any[], childGrades);

    const filteredContent = (content as ContentDoc[]).filter((c) => {
      const hasGrade = c.grade && c.grade.length > 0;
      const stuIds = c.studentUids || [];
      const hasStudents = stuIds.length > 0;
      if (!hasGrade && !hasStudents) return true;
      if (hasStudents && childUids.some((u: string) => stuIds.includes(u))) return true;
      if (hasGrade && childGrades.includes(c.grade!)) return true;
      return false;
    });

    const result = {
      user: serializeDoc(user),
      childrenData,
      announcements: serializeDocs(filteredAnnouncements.slice(0, Config.PRINCIPAL_ACTIVITY_LIMIT)),
      activeVotes: serializeDocs(votes),
      activityFeed: serializeDocs(activity as any[]),
      contentItems: serializeDocs(filteredContent),
    };

    cacheSet(cacheKey, result, USER_TTL);
    res.json(result);
  })
);

// ─── Principal Dashboard ────────────────────────────────────────────────────

router.get(
  "/principal/:uid",
  asyncHandler(async (req, res) => {
    const uid = (req.params.uid as string) || req.uid!;
    const callerUid = req.uid!;
    const role = req.role;

    if (role !== "Principal")
      return res.status(403).json({ error: "Forbidden: principal access only" });
    if (callerUid !== uid)
      return res.status(403).json({ error: "Forbidden" });

    const cacheKey = `principal_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return res.json(cached);

    const user = await getDoc(Collections.USERS, uid);
    if (!user) return res.status(404).json({ error: "User not found" });

    const [
      teacherSnap, studentSnap, parentSnap, classSnap, gradeSnap,
      announcements, votes, activityFeed,
    ] = await Promise.all([
      db.collection(Collections.USERS).where("role", "==", "Teacher").get(),
      db.collection(Collections.USERS).where("role", "==", "Student").get(),
      db.collection(Collections.USERS).where("role", "==", "Parent").get(),
      db.collection(Collections.CLASSES).get(),
      db.collection(Collections.GRADES).get(),
      fetchShared("announcements_all", () =>
        queryDocs(Collections.ANNOUNCEMENTS, [], { field: "createdAt", direction: "desc" }, Config.ANNOUNCEMENTS_LIMIT)
      ),
      fetchShared("votes_visible", () =>
        queryDocs(Collections.VOTES, [{ field: "resultsVisibleUntil", op: ">=", value: new Date().toISOString() }], { field: "resultsVisibleUntil" })
      ),
      queryDocs(Collections.ACTIVITIES, [], { field: "createdAt", direction: "desc" }, Config.PRINCIPAL_ACTIVITY_LIMIT),
    ]);

    const teachers = teacherSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const students = studentSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const allClasses = classSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const parents = parentSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const allGrades = gradeSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

    const result = {
      user: serializeDoc(user),
      teacherCount: teacherSnap.size,
      studentCount: studentSnap.size,
      classCount: classSnap.size,
      teachers: serializeDocs(teachers),
      students: serializeDocs(students),
      allClasses: serializeDocs(allClasses),
      parents: serializeDocs(parents),
      allGrades: serializeDocs(allGrades),
      subjectAverages: computeSubjectAverages(allGrades),
      announcements: serializeDocs(announcements),
      activeVotes: serializeDocs(votes),
      activityFeed: serializeDocs(activityFeed),
    };

    cacheSet(cacheKey, result, USER_TTL);
    res.json(result);
  })
);

router.get(
  "/activities/paginated",
  asyncHandler(async (req, res) => {
    const targetUid = req.query.targetUid as string | undefined;
    const classId = req.query.classId as string | undefined;
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 50);
    const after = req.query.after as string | undefined;

    let query: FirebaseFirestore.Query = db
      .collection(Collections.ACTIVITIES)
      .orderBy("createdAt", "desc");

    if (targetUid) {
      query = query.where("targetUid", "==", targetUid);
    } else if (classId) {
      query = query.where("classId", "==", classId);
    }

    if (after) {
      query = query.where("createdAt", "<", new Date(after));
    }

    const snap = await query.limit(limit + 1).get();
    const docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const hasMore = docs.length > limit;
    const items = serializeDocs(docs.slice(0, limit));
    res.json({ items, hasMore });
  })
);

export default router;
