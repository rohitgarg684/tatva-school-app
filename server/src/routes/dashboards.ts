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
import { Collections } from "../lib/collections";
import { Config } from "../lib/config";

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
  const childDoc = await getDoc(Collections.USERS, childUid);
  if (!childDoc) return false;
  return (callerDoc.children as Array<{ childName: string }>).some(
    (c) => c.childName === childDoc.name
  );
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

function filterAnnouncementsByGrade(announcements: any[], userGrades: string[]): any[] {
  return announcements.filter((a: any) => {
    if ((a.audience || "").toLowerCase() === "everyone") return true;
    if (Array.isArray(a.grades) && a.grades.length > 0) {
      return a.grades.some((g: string) => userGrades.includes(g));
    }
    return true;
  });
}

function computeBehaviorScore(points: any[]): number {
  let score = 0;
  for (const p of points) {
    score += (p.points as number) || 0;
  }
  return score;
}

function computeSubjectAverages(grades: any[]): Record<string, number> {
  const sums: Record<string, { total: number; count: number }> = {};
  for (const g of grades) {
    const subj = g.subject || "Unknown";
    const pct = (g.total ?? 0) > 0 ? ((g.score || 0) / (g.total ?? 1)) * 100 : 0;
    if (!sums[subj]) sums[subj] = { total: 0, count: 0 };
    sums[subj].total += pct;
    sums[subj].count += 1;
  }
  const result: Record<string, number> = {};
  for (const [subj, { total, count }] of Object.entries(sums)) {
    result[subj] = count > 0 ? Math.round((total / count) * 10) / 10 : 0;
  }
  return result;
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
      safe(fetchShared("votes_active", () =>
        queryDocs(Collections.VOTES, [{ field: "active", op: "==", value: true }], { field: "createdAt", direction: "desc" })
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
      contentItems: serializeDocs(contentItems),
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

    let studentsInFirstClass: any[] = [];
    let parentsInFirstClass: any[] = [];
    let gradesInFirstClass: any[] = [];
    let classBehavior: any[] = [];
    let todayAttendance: any[] = [];
    let activityFeed: any[] = [];
    let allTeacherGrades: any[] = [];
    let testTitles: any[] = [];

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

      studentsInFirstClass = students;
      parentsInFirstClass = parents;
      gradesInFirstClass = grades;
      classBehavior = behavior;
      todayAttendance = att;
      activityFeed = activity;

      const allClassIds = classes.map((c: any) => c.id);
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

    const [announcements, homework, allStudents] = await Promise.all([
      safe(fetchShared("announcements_all", () =>
        queryDocs(Collections.ANNOUNCEMENTS, [], { field: "createdAt", direction: "desc" }, Config.ANNOUNCEMENTS_LIMIT)
      ), []),
      safe(queryDocs(Collections.HOMEWORK, [{ field: "teacherUid", op: "==", value: uid }], { field: "createdAt", direction: "desc" }), []),
      safe(fetchShared("all_students", () =>
        queryDocs(Collections.USERS, [{ field: "role", op: "==", value: "Student" }], { field: "name" })
      ), []),
    ]);

    const teacherGrades = classes.map((c: any) => c.grade).filter(Boolean);
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

    const cacheKey = `parent_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return res.json(cached);

    const user = await getDoc(Collections.USERS, uid);
    if (!user) return res.status(404).json({ error: "User not found" });

    const children: Array<{ childName: string; classId: string }> = user.children || [];
    const classIdSet = new Set<string>();
    const childrenData: any[] = [];

    const classIdsFromChildren = children.map((c) => c.classId).filter(Boolean);
    const childClasses = classIdsFromChildren.length > 0
      ? await getDocs(Collections.CLASSES, classIdsFromChildren)
      : [];
    const classMap = new Map(childClasses.map((c: any) => [c.id, c]));

    // Batch: collect all child names, find matching student UIDs in one pass
    const childNames = children.map((c) => c.childName).filter(Boolean);
    let allStudents: any[] = [];
    if (childNames.length > 0) {
      const nameChunks: string[][] = [];
      for (let i = 0; i < childNames.length; i += Config.FIRESTORE_IN_LIMIT) {
        nameChunks.push(childNames.slice(i, i + Config.FIRESTORE_IN_LIMIT));
      }
      const studentChunks = await Promise.all(
        nameChunks.map((names) =>
          queryDocs(Collections.USERS, [
            { field: "role", op: "==", value: "Student" },
            { field: "name", op: "in", value: names },
          ])
        )
      );
      allStudents = studentChunks.flat();
    }
    const studentNameMap = new Map(allStudents.map((s: any) => [s.name, s.id]));

    // Batch: collect all child UIDs, query grades/behavior/attendance in bulk
    const childUids: string[] = [];
    for (const childInfo of children) {
      const uid = studentNameMap.get(childInfo.childName) || "";
      if (uid) childUids.push(uid);
    }

    const [allGrades, allBehavior, allAttendance] = childUids.length > 0
      ? await Promise.all([
          safe(queryDocs(Collections.GRADES, [{ field: "studentUid", op: "in", value: childUids.slice(0, Config.FIRESTORE_IN_LIMIT) }], { field: "createdAt" }), []),
          safe(queryDocs(Collections.BEHAVIOR_POINTS, [{ field: "studentUid", op: "in", value: childUids.slice(0, Config.FIRESTORE_IN_LIMIT) }], { field: "createdAt", direction: "desc" }), []),
          safe(queryDocs(Collections.ATTENDANCE, [{ field: "studentUid", op: "in", value: childUids.slice(0, Config.FIRESTORE_IN_LIMIT) }], { field: "date", direction: "desc" }), []),
        ])
      : [[], [], []];

    for (const childInfo of children) {
      if (childInfo.classId) classIdSet.add(childInfo.classId);
      const childUid = studentNameMap.get(childInfo.childName) || "";

      if (childUid) {
        const grades = (allGrades as any[]).filter((g: any) => g.studentUid === childUid);
        const behavior = (allBehavior as any[]).filter((b: any) => b.studentUid === childUid);
        const attendance = (allAttendance as any[]).filter((a: any) => a.studentUid === childUid);

        childrenData.push({
          info: childInfo,
          childUid,
          childClass: serializeDoc(classMap.get(childInfo.classId) || null),
          grades: serializeDocs(grades),
          behaviorPoints: serializeDocs(behavior),
          behaviorScore: computeBehaviorScore(behavior),
          attendance: serializeDocs(attendance),
        });
      } else {
        childrenData.push({
          info: childInfo,
          childUid: "",
          childClass: serializeDoc(classMap.get(childInfo.classId) || null),
          grades: [],
          behaviorPoints: [],
          behaviorScore: 0,
          attendance: [],
        });
      }
    }

    const classIdList = Array.from(classIdSet);
    const firstChildUid = childrenData.length > 0 ? childrenData[0].childUid : "";

    const childGrades = childClasses.map((c: any) => c.grade).filter(Boolean);

    const [announcements, votes, activity, content] = await Promise.all([
      safe(fetchShared("announcements_all", () =>
        queryDocs(Collections.ANNOUNCEMENTS, [], { field: "createdAt", direction: "desc" }, Config.ANNOUNCEMENTS_LIMIT)
      ), []),
      safe(fetchShared("votes_active", () =>
        queryDocs(Collections.VOTES, [{ field: "active", op: "==", value: true }], { field: "createdAt", direction: "desc" })
      ), []),
      safe(firstChildUid
        ? queryDocs(Collections.ACTIVITIES, [{ field: "targetUid", op: "==", value: firstChildUid }], { field: "createdAt", direction: "desc" }, Config.ACTIVITY_FEED_LIMIT)
        : Promise.resolve([]), []),
      safe(fetchShared("content_all", () =>
        queryDocs(Collections.CONTENT, [], { field: "createdAt", direction: "desc" })
      ), []),
    ]);

    const filteredAnnouncements = filterAnnouncementsByGrade(announcements as any[], childGrades);

    const result = {
      user: serializeDoc(user),
      childrenData,
      announcements: serializeDocs(filteredAnnouncements.slice(0, Config.PRINCIPAL_ACTIVITY_LIMIT)),
      activeVotes: serializeDocs(votes),
      activityFeed: serializeDocs(activity as any[]),
      contentItems: serializeDocs(content),
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
      fetchShared("votes_active", () =>
        queryDocs(Collections.VOTES, [{ field: "active", op: "==", value: true }], { field: "createdAt", direction: "desc" })
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

export default router;
