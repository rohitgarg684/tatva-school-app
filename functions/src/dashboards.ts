import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  db,
  getDoc,
  getDocs,
  queryDocs,
  serializeDocs,
  serializeDoc,
} from "./firestore-helpers";
import {
  cacheGet,
  cacheSet,
  cacheDelete,
  SHARED_TTL,
  USER_TTL,
} from "./cache";

function requireAuth(request: any): string {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  return request.auth.uid;
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

// ─── Student Dashboard ─────────────────────────────────────────────────────

export const getStudentDashboard = onCall(
  { region: "us-central1", memory: "256MiB" },
  async (request) => {
    const callerUid = requireAuth(request);
    const uid = (request.data?.uid as string) || callerUid;

    const cacheKey = `student_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return cached;

    const user = await getDoc("users", uid);
    if (!user) {
      throw new HttpsError("not-found", "User not found.");
    }

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
    return result;
  }
);

// ─── Teacher Dashboard ──────────────────────────────────────────────────────

export const getTeacherDashboard = onCall(
  { region: "us-central1", memory: "256MiB" },
  async (request) => {
    const callerUid = requireAuth(request);
    const uid = (request.data?.uid as string) || callerUid;

    const cacheKey = `teacher_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return cached;

    const user = await getDoc("users", uid);
    if (!user) {
      throw new HttpsError("not-found", "User not found.");
    }

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
            { field: "classId", op: "==", value: first.id },
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

    const [announcements, homework] = await Promise.all([
      fetchShared("announcements_all", () =>
        queryDocs("announcements", [], { field: "createdAt", direction: "desc" }, 25)
      ),
      queryDocs(
        "homework",
        [{ field: "teacherUid", op: "==", value: uid }],
        { field: "createdAt", direction: "desc" }
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
    };

    cacheSet(cacheKey, result, USER_TTL);
    return result;
  }
);

// ─── Parent Dashboard ───────────────────────────────────────────────────────

export const getParentDashboard = onCall(
  { region: "us-central1", memory: "256MiB" },
  async (request) => {
    const callerUid = requireAuth(request);
    const uid = (request.data?.uid as string) || callerUid;

    const cacheKey = `parent_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return cached;

    const user = await getDoc("users", uid);
    if (!user) {
      throw new HttpsError("not-found", "User not found.");
    }

    const children: any[] = user.children || [];
    const classIdSet = new Set<string>();
    const childrenData: any[] = [];

    // Resolve child UIDs by querying users where role==Student and name matches
    const studentSnap = children.length > 0
      ? await db
          .collection("users")
          .where("role", "==", "Student")
          .get()
      : null;

    const allStudents = studentSnap
      ? studentSnap.docs.map((d) => ({ id: d.id, ...d.data() }))
      : [];

    // Gather all class IDs to batch-fetch
    const classIds = children
      .map((c: any) => c.classId)
      .filter((id: string) => id);
    const childClasses = classIds.length > 0
      ? await getDocs("classes", classIds)
      : [];
    const classMap = new Map(childClasses.map((c: any) => [c.id, c]));

    // For each child, resolve UID then batch-fetch per-child data
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
    return result;
  }
);

// ─── Principal Dashboard ────────────────────────────────────────────────────

export const getPrincipalDashboard = onCall(
  { region: "us-central1", memory: "512MiB" },
  async (request) => {
    const callerUid = requireAuth(request);
    const uid = (request.data?.uid as string) || callerUid;

    const cacheKey = `principal_dash_${uid}`;
    const cached = cacheGet<any>(cacheKey);
    if (cached) return cached;

    const user = await getDoc("users", uid);
    if (!user) {
      throw new HttpsError("not-found", "User not found.");
    }

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
    const allClasses = classSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const parents = parentSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const allGrades = gradeSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

    const result = {
      user: serializeDoc(user),
      teacherCount: teacherSnap.size,
      studentCount: studentSnap.size,
      classCount: classSnap.size,
      teachers: serializeDocs(teachers),
      allClasses: serializeDocs(allClasses),
      parents: serializeDocs(parents),
      allGrades: serializeDocs(allGrades),
      subjectAverages: computeSubjectAverages(allGrades),
      announcements: serializeDocs(announcements),
      activeVotes: serializeDocs(votes),
      activityFeed: serializeDocs(activityFeed),
    };

    cacheSet(cacheKey, result, USER_TTL);
    return result;
  }
);
