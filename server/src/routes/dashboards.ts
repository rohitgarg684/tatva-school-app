import { Router, Request, Response } from "express";
import { requireAuth } from "../middleware/auth";
import {
  db,
  getDoc,
  getDocs,
  queryDocs,
  serializeDocs,
  serializeDoc,
} from "../lib/firestore-helpers";
import {
  cacheGet,
  cacheSet,
  SHARED_TTL,
  USER_TTL,
} from "../lib/cache";

const router = Router();
router.use(requireAuth);

// ─── Access control helpers ─────────────────────────────────────────────────

async function callerSharesClassWith(
  callerUid: string,
  targetUid: string
): Promise<boolean> {
  const [callerDoc, targetDoc] = await Promise.all([
    getDoc("users", callerUid),
    getDoc("users", targetUid),
  ]);
  if (!callerDoc || !targetDoc) return false;
  const callerClasses: string[] = callerDoc.classIds || [];
  const targetClasses: string[] = targetDoc.classIds || [];
  return callerClasses.some((c) => targetClasses.includes(c));
}

async function callerIsParentOf(
  callerUid: string,
  childUid: string
): Promise<boolean> {
  const callerDoc = await getDoc("users", callerUid);
  if (!callerDoc || !callerDoc.children) return false;
  const childDoc = await getDoc("users", childUid);
  if (!childDoc) return false;
  return (callerDoc.children as any[]).some(
    (c: any) => c.childName === childDoc.name
  );
}

async function fetchShared(key: string, fetcher: () => Promise<any>) {
  const cached = cacheGet<any>(key);
  if (cached) return cached;
  const data = await fetcher();
  cacheSet(key, data, SHARED_TTL);
  return data;
}

function isVisibleTo(audience: string, roleAudience: string): boolean {
  const a = (audience || "").toLowerCase();
  const r = roleAudience.toLowerCase();
  return a === "everyone" || a === r;
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
    const pct = g.total > 0 ? ((g.score || 0) / g.total) * 100 : 0;
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

router.get("/student/:uid", async (req, res) => {
  try {
    const uid = req.params.uid || req.uid!;
    const callerUid = req.uid!;
    const role = req.role;

    // Access: Student=self, Teacher=class member, Parent=their child, Principal=any
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

    const user = await getDoc("users", uid);
    if (!user) return res.status(404).json({ error: "User not found" });

    const classIds: string[] = user.classIds || [];

    const [
      primaryClass,
      grades,
      announcements,
      homework,
      votes,
      behaviorPoints,
      attendance,
      stories,
      activityFeed,
      contentItems,
    ] = await Promise.all([
      classIds.length > 0 ? getDoc("classes", classIds[0]) : null,
      queryDocs("grades", [{ field: "studentUid", op: "==", value: uid }], {
        field: "createdAt",
      }),
      fetchShared("announcements_all", () =>
        queryDocs("announcements", [], { field: "createdAt", direction: "desc" }, 25)
      ),
      classIds.length > 0
        ? queryDocs(
            "homework",
            [{ field: "classId", op: "in", value: classIds.slice(0, 30) }],
            { field: "createdAt", direction: "desc" }
          )
        : [],
      fetchShared("votes_active", () =>
        queryDocs("votes", [{ field: "active", op: "==", value: true }], {
          field: "createdAt",
          direction: "desc",
        })
      ),
      queryDocs(
        "behavior_points",
        [{ field: "studentUid", op: "==", value: uid }],
        { field: "createdAt", direction: "desc" }
      ),
      queryDocs(
        "attendance",
        [{ field: "studentUid", op: "==", value: uid }],
        { field: "date", direction: "desc" }
      ),
      classIds.length > 0
        ? queryDocs(
            "stories",
            [{ field: "classId", op: "in", value: classIds.slice(0, 30) }],
            { field: "createdAt", direction: "desc" }
          )
        : [],
      queryDocs(
        "activities",
        [{ field: "targetUid", op: "==", value: uid }],
        { field: "createdAt", direction: "desc" },
        10
      ),
      fetchShared("content_all", () =>
        queryDocs("content", [], { field: "createdAt", direction: "desc" })
      ),
    ]);

    const filteredAnnouncements = (announcements as any[]).filter((a: any) =>
      isVisibleTo(a.audience, "students")
    );

    const result = {
      user: serializeDoc(user),
      primaryClass: serializeDoc(primaryClass),
      grades: serializeDocs(grades),
      announcements: serializeDocs(filteredAnnouncements.slice(0, 20)),
      homework: serializeDocs(homework as any[]),
      activeVotes: serializeDocs(votes),
      behaviorPoints: serializeDocs(behaviorPoints),
      behaviorScore: computeBehaviorScore(behaviorPoints),
      attendance: serializeDocs(attendance),
      storyPosts: serializeDocs(stories as any[]),
      activityFeed: serializeDocs(activityFeed),
      contentItems: serializeDocs(contentItems),
    };

    cacheSet(cacheKey, result, USER_TTL);
    res.json(result);
  } catch (err: any) {
    console.error("getStudentDashboard error:", err);
    res.status(500).json({ error: err.message || "Internal server error" });
  }
});

// ─── Teacher Dashboard ──────────────────────────────────────────────────────

router.get("/teacher/:uid", async (req, res) => {
  try {
    const uid = req.params.uid || req.uid!;
    const callerUid = req.uid!;
    const role = req.role;

    // Access: Teacher=self, Principal=any
    if (role !== "Principal" && callerUid !== uid) {
      return res.status(403).json({ error: "Forbidden" });
    }
    if (role !== "Teacher" && role !== "Principal") {
      return res.status(403).json({ error: "Forbidden: insufficient role" });
    }

    const cacheKey = `teacher_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return res.json(cached);

    const user = await getDoc("users", uid);
    if (!user) return res.status(404).json({ error: "User not found" });

    const classIds: string[] = user.classIds || [];
    const classes =
      classIds.length > 0 ? await getDocs("classes", classIds) : [];

    let studentsInFirstClass: any[] = [];
    let parentsInFirstClass: any[] = [];
    let gradesInFirstClass: any[] = [];
    let classBehavior: any[] = [];
    let todayAttendance: any[] = [];
    let classStory: any[] = [];
    let activityFeed: any[] = [];

    if (classes.length > 0) {
      const first = classes[0] as any;
      const today = new Date().toISOString().substring(0, 10);

      const [students, parents, grades, behavior, att, story, activity] =
        await Promise.all([
          getDocs("users", first.studentUids || []),
          getDocs("users", first.parentUids || []),
          queryDocs(
            "grades",
            [{ field: "classId", op: "==", value: first.id }],
            { field: "createdAt" }
          ),
          queryDocs(
            "behavior_points",
            [{ field: "classId", op: "==", value: first.id }],
            { field: "createdAt", direction: "desc" }
          ),
          queryDocs("attendance", [
            { field: "date", op: "==", value: today },
          ]),
          queryDocs(
            "stories",
            [{ field: "classId", op: "==", value: first.id }],
            { field: "createdAt", direction: "desc" }
          ),
          queryDocs(
            "activities",
            [{ field: "classId", op: "==", value: first.id }],
            { field: "createdAt", direction: "desc" },
            10
          ),
        ]);

      studentsInFirstClass = students;
      parentsInFirstClass = parents;
      gradesInFirstClass = grades;
      classBehavior = behavior;
      todayAttendance = att;
      classStory = story;
      activityFeed = activity;
    }

    const [announcements, homework, allStudents] = await Promise.all([
      fetchShared("announcements_all", () =>
        queryDocs("announcements", [], { field: "createdAt", direction: "desc" }, 25)
      ),
      queryDocs(
        "homework",
        [{ field: "teacherUid", op: "==", value: uid }],
        { field: "createdAt", direction: "desc" }
      ),
      fetchShared("all_students", () =>
        queryDocs("users", [{ field: "role", op: "==", value: "Student" }], { field: "name" })
      ),
    ]);

    const result = {
      user: serializeDoc(user),
      classes: serializeDocs(classes),
      studentsInFirstClass: serializeDocs(studentsInFirstClass),
      parentsInFirstClass: serializeDocs(parentsInFirstClass),
      gradesInFirstClass: serializeDocs(gradesInFirstClass),
      announcements: serializeDocs(announcements),
      homework: serializeDocs(homework),
      classBehavior: serializeDocs(classBehavior),
      todayAttendance: serializeDocs(todayAttendance),
      classStory: serializeDocs(classStory),
      activityFeed: serializeDocs(activityFeed),
      allStudents: serializeDocs(allStudents),
    };

    cacheSet(cacheKey, result, USER_TTL);
    res.json(result);
  } catch (err: any) {
    console.error("getTeacherDashboard error:", err);
    res.status(500).json({ error: err.message || "Internal server error" });
  }
});

// ─── Parent Dashboard ───────────────────────────────────────────────────────

router.get("/parent/:uid", async (req, res) => {
  try {
    const uid = req.params.uid || req.uid!;
    const callerUid = req.uid!;
    const role = req.role;

    // Access: Parent=self, Principal=any
    if (role !== "Principal" && callerUid !== uid) {
      return res.status(403).json({ error: "Forbidden" });
    }
    if (role !== "Parent" && role !== "Principal") {
      return res.status(403).json({ error: "Forbidden: insufficient role" });
    }

    const cacheKey = `parent_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return res.json(cached);

    const user = await getDoc("users", uid);
    if (!user) return res.status(404).json({ error: "User not found" });

    const children: any[] = user.children || [];
    const classIdSet = new Set<string>();
    const childrenData: any[] = [];

    const studentSnap = children.length > 0
      ? await db
          .collection("users")
          .where("role", "==", "Student")
          .get()
      : null;

    const allStudents = studentSnap
      ? studentSnap.docs.map((d) => ({ id: d.id, ...d.data() }))
      : [];

    const classIds = children
      .map((c: any) => c.classId)
      .filter((id: string) => id);
    const childClasses = classIds.length > 0
      ? await getDocs("classes", classIds)
      : [];
    const classMap = new Map(childClasses.map((c: any) => [c.id, c]));

    for (const childInfo of children) {
      if (childInfo.classId) classIdSet.add(childInfo.classId);

      const match = allStudents.find(
        (s: any) => s.name === childInfo.childName
      );
      const childUid = match ? match.id : "";

      if (childUid) {
        const [grades, behavior, attendance] = await Promise.all([
          queryDocs(
            "grades",
            [{ field: "studentUid", op: "==", value: childUid }],
            { field: "createdAt" }
          ),
          queryDocs(
            "behavior_points",
            [{ field: "studentUid", op: "==", value: childUid }],
            { field: "createdAt", direction: "desc" }
          ),
          queryDocs(
            "attendance",
            [{ field: "studentUid", op: "==", value: childUid }],
            { field: "date", direction: "desc" }
          ),
        ]);

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
    const firstChildUid =
      childrenData.length > 0 ? childrenData[0].childUid : "";

    const [announcements, votes, stories, activity, content] =
      await Promise.all([
        fetchShared("announcements_all", () =>
          queryDocs("announcements", [], { field: "createdAt", direction: "desc" }, 25)
        ),
        fetchShared("votes_active", () =>
          queryDocs("votes", [{ field: "active", op: "==", value: true }], {
            field: "createdAt",
            direction: "desc",
          })
        ),
        classIdList.length > 0
          ? queryDocs(
              "stories",
              [
                {
                  field: "classId",
                  op: "in",
                  value: classIdList.slice(0, 30),
                },
              ],
              { field: "createdAt", direction: "desc" }
            )
          : [],
        firstChildUid
          ? queryDocs(
              "activities",
              [{ field: "targetUid", op: "==", value: firstChildUid }],
              { field: "createdAt", direction: "desc" },
              10
            )
          : [],
        fetchShared("content_all", () =>
          queryDocs("content", [], { field: "createdAt", direction: "desc" })
        ),
      ]);

    const filteredAnnouncements = (announcements as any[]).filter((a: any) =>
      isVisibleTo(a.audience, "parents")
    );

    const result = {
      user: serializeDoc(user),
      childrenData,
      announcements: serializeDocs(filteredAnnouncements.slice(0, 20)),
      activeVotes: serializeDocs(votes),
      storyPosts: serializeDocs(stories as any[]),
      activityFeed: serializeDocs(activity as any[]),
      contentItems: serializeDocs(content),
    };

    cacheSet(cacheKey, result, USER_TTL);
    res.json(result);
  } catch (err: any) {
    console.error("getParentDashboard error:", err);
    res.status(500).json({ error: err.message || "Internal server error" });
  }
});

// ─── Principal Dashboard ────────────────────────────────────────────────────

router.get("/principal/:uid", async (req, res) => {
  try {
    const uid = req.params.uid || req.uid!;
    const callerUid = req.uid!;
    const role = req.role;

    // Access: Principal only, self only
    if (role !== "Principal") {
      return res.status(403).json({ error: "Forbidden: principal access only" });
    }
    if (callerUid !== uid) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const cacheKey = `principal_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return res.json(cached);

    const user = await getDoc("users", uid);
    if (!user) return res.status(404).json({ error: "User not found" });

    const [
      teacherSnap,
      studentSnap,
      parentSnap,
      classSnap,
      gradeSnap,
      announcements,
      votes,
      activityFeed,
    ] = await Promise.all([
      db.collection("users").where("role", "==", "Teacher").get(),
      db.collection("users").where("role", "==", "Student").get(),
      db.collection("users").where("role", "==", "Parent").get(),
      db.collection("classes").get(),
      db.collection("grades").get(),
      fetchShared("announcements_all", () =>
        queryDocs("announcements", [], { field: "createdAt", direction: "desc" }, 25)
      ),
      fetchShared("votes_active", () =>
        queryDocs("votes", [{ field: "active", op: "==", value: true }], {
          field: "createdAt",
          direction: "desc",
        })
      ),
      queryDocs(
        "activities",
        [],
        { field: "createdAt", direction: "desc" },
        20
      ),
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
  } catch (err: any) {
    console.error("getPrincipalDashboard error:", err);
    res.status(500).json({ error: err.message || "Internal server error" });
  }
});

export default router;
