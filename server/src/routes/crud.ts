import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, getDoc, queryDocs, serializeDoc, serializeDocs } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";

const router = Router();
router.use(requireAuth);
const FieldValue = admin.firestore.FieldValue;

// ─── User ────────────────────────────────────────────────────────────────────

router.get("/user/:uid", async (req, res) => {
  try {
    const doc = await getDoc("users", req.params.uid as string);
    if (!doc) return res.status(404).json({ error: "User not found" });
    res.json(serializeDoc(doc));
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/user", async (req, res) => {
  try {
    const { uid, name, email, role } = req.body;
    if (!uid || !name || !email || !role)
      return res.status(400).json({ error: "uid, name, email, role required" });

    await db.collection("users").doc(uid).set({
      uid, name, email, role,
      classIds: [],
      children: [],
      createdAt: FieldValue.serverTimestamp(),
    });

    await admin.auth().setCustomUserClaims(uid, { role });
    res.json({ uid, created: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Class ───────────────────────────────────────────────────────────────────

router.post(
  "/class",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const { name, subject, classCode } = req.body;
      if (!name || !subject || !classCode)
        return res.status(400).json({ error: "name, subject, classCode required" });

      const uid = req.uid!;
      const userDoc = await getDoc("users", uid);
      const teacherName = userDoc?.name || "";
      const teacherEmail = userDoc?.email || "";

      const existing = await db.collection("classes")
        .where("classCode", "==", classCode).limit(1).get();
      if (!existing.empty)
        return res.status(409).json({ error: "Class code already in use" });

      const ref = await db.collection("classes").add({
        name, subject, classCode,
        teacherUid: uid,
        teacherName,
        teacherEmail,
        studentUids: [],
        parentUids: [],
        createdAt: FieldValue.serverTimestamp(),
      });

      await db.collection("users").doc(uid).update({
        classIds: FieldValue.arrayUnion(ref.id),
      });

      cacheDeletePrefix("teacher_dash_");
      res.json({ id: ref.id, created: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

router.delete(
  "/class/:classId",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const classId = req.params.classId as string;
      const uid = req.uid!;
      const role = req.role;

      const classDoc = await db.collection("classes").doc(classId).get();
      if (!classDoc.exists)
        return res.status(404).json({ error: "Class not found" });

      const classData = classDoc.data()!;

      if (role === "Teacher" && classData.teacherUid !== uid)
        return res.status(403).json({ error: "You can only delete your own classes" });

      const batch = db.batch();

      batch.delete(classDoc.ref);

      // Remove classId from teacher's user doc
      if (classData.teacherUid) {
        batch.update(db.collection("users").doc(classData.teacherUid), {
          classIds: admin.firestore.FieldValue.arrayRemove(classId),
        });
      }

      // Remove classId from enrolled students/parents user docs
      const memberUids = [
        ...(classData.studentUids || []),
        ...(classData.parentUids || []),
      ];
      for (const memberId of memberUids) {
        batch.update(db.collection("users").doc(memberId), {
          classIds: admin.firestore.FieldValue.arrayRemove(classId),
        });
      }

      await batch.commit();

      cacheDeletePrefix("teacher_dash_");
      cacheDeletePrefix("principal_dash_");
      cacheDeletePrefix("student_dash_");
      cacheDeletePrefix("parent_dash_");
      res.json({ id: classId, deleted: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

router.post("/class/join", async (req, res) => {
  try {
    const { classCode, childName } = req.body;
    if (!classCode)
      return res.status(400).json({ error: "classCode required" });

    const uid = req.uid!;
    const role = req.role;
    const snap = await db.collection("classes")
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
        await db.collection("users").doc(uid).update({
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

    await db.collection("users").doc(uid).update({
      classIds: FieldValue.arrayUnion(classId),
    });

    res.json({ classId, joined: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Student Enrollment ──────────────────────────────────────────────────────

router.post(
  "/student/enroll",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const { name, rollNumber, grade, section, parentName, parentPhone, classIds } = req.body;
      if (!name)
        return res.status(400).json({ error: "name required" });

      const ref = await db.collection("students").add({
        name,
        rollNumber: rollNumber || "",
        grade: grade || "",
        section: section || "",
        parentName: parentName || "",
        parentPhone: parentPhone || "",
        classIds: classIds || [],
        enrolledBy: req.uid,
        createdAt: FieldValue.serverTimestamp(),
      });

      res.json({ id: ref.id, enrolled: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

router.get(
  "/students",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const students = await queryDocs("students", [], { field: "name", direction: "asc" });
      res.json({ students: serializeDocs(students) });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Homework ────────────────────────────────────────────────────────────────

router.post(
  "/homework",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const { title, description, subject, classId, className, dueDate, attachments } = req.body;
      if (!title || !classId)
        return res.status(400).json({ error: "title, classId required" });

      const uid = req.uid!;
      const userDoc = await getDoc("users", uid);

      const ref = await db.collection("homework").add({
        title,
        description: description || "",
        subject: subject || "",
        classId,
        className: className || "",
        teacherUid: uid,
        teacherName: userDoc?.name || "",
        dueDate: dueDate || "",
        submittedBy: [],
        attachments: Array.isArray(attachments) ? attachments : [],
        createdAt: FieldValue.serverTimestamp(),
      });

      cacheDeletePrefix("teacher_dash_");
      cacheDeletePrefix("student_dash_");
      res.json({ id: ref.id, created: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

router.delete(
  "/homework/:id",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const docId = req.params.id as string;
      const ref = db.collection("homework").doc(docId);
      const snap = await ref.get();
      if (!snap.exists) return res.status(404).json({ error: "Not found" });
      await ref.delete();
      cacheDeletePrefix("teacher_dash_");
      cacheDeletePrefix("student_dash_");
      res.json({ deleted: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Announcement ────────────────────────────────────────────────────────────

router.post(
  "/announcement",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const { title, body: bodyText, audience } = req.body;
      if (!title || !bodyText)
        return res.status(400).json({ error: "title, body required" });

      const uid = req.uid!;
      const userDoc = await getDoc("users", uid);

      const ref = await db.collection("announcements").add({
        title,
        body: bodyText,
        audience: audience || "Everyone",
        classIds: [],
        createdBy: uid,
        createdByName: userDoc?.name || "",
        createdByRole: req.role || "",
        createdAt: FieldValue.serverTimestamp(),
      });

      cacheDeletePrefix("announcements_all");
      res.json({ id: ref.id, created: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Vote ────────────────────────────────────────────────────────────────────

router.post(
  "/vote",
  requireRole("Principal"),
  async (req, res) => {
    try {
      const { question, type } = req.body;
      if (!question)
        return res.status(400).json({ error: "question required" });

      const uid = req.uid!;
      const userDoc = await getDoc("users", uid);

      const ref = await db.collection("votes").add({
        question,
        type: type || "school_decision",
        createdBy: uid,
        createdByName: userDoc?.name || "",
        createdByRole: req.role || "",
        votes: { school: 0, no_school: 0, undecided: 0 },
        voters: [],
        active: true,
        createdAt: FieldValue.serverTimestamp(),
      });

      cacheDeletePrefix("votes_active");
      res.json({ id: ref.id, created: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Story Post ──────────────────────────────────────────────────────────────

router.post(
  "/story",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const { classId, className, text, mediaUrls, mediaType } = req.body;
      if (!classId || !text)
        return res.status(400).json({ error: "classId, text required" });

      const uid = req.uid!;
      const userDoc = await getDoc("users", uid);

      const ref = await db.collection("stories").add({
        authorUid: uid,
        authorName: userDoc?.name || "",
        authorRole: req.role || "",
        classId,
        className: className || "",
        text,
        mediaUrls: mediaUrls || [],
        mediaType: mediaType || "none",
        likedBy: [],
        commentCount: 0,
        createdAt: FieldValue.serverTimestamp(),
      });

      cacheDeletePrefix("teacher_dash_");
      cacheDeletePrefix("student_dash_");
      cacheDeletePrefix("parent_dash_");
      res.json({ id: ref.id, created: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Grade ───────────────────────────────────────────────────────────────────

router.post(
  "/grade",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const { studentUid, studentName, classId, subject, assessmentName, score, total } = req.body;
      if (!studentUid || !classId || !subject || !assessmentName)
        return res.status(400).json({ error: "studentUid, classId, subject, assessmentName required" });

      const existing = await db.collection("grades")
        .where("studentUid", "==", studentUid)
        .where("classId", "==", classId)
        .where("assessmentName", "==", assessmentName)
        .limit(1).get();

      if (!existing.empty) {
        await existing.docs[0].ref.update({
          score: score || 0,
          total: total || 100,
          updatedAt: FieldValue.serverTimestamp(),
        });
        res.json({ id: existing.docs[0].id, updated: true });
      } else {
        const ref = await db.collection("grades").add({
          studentUid,
          studentName: studentName || "",
          classId,
          subject,
          assessmentName,
          score: score || 0,
          total: total || 100,
          teacherUid: req.uid,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        res.json({ id: ref.id, created: true });
      }

      cacheDeletePrefix("student_dash_");
      cacheDeletePrefix("teacher_dash_");
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Messages (1:1 polling) ──────────────────────────────────────────────────

router.get("/messages/:conversationId", async (req, res) => {
  try {
    const convId = req.params.conversationId as string;
    const uid = req.uid!;

    const msgs = await queryDocs(
      "messages",
      [{ field: "conversationId", op: "==", value: convId }],
      { field: "createdAt", direction: "asc" },
      200
    );

    const participates = msgs.some(
      (m: any) => m.senderUid === uid || m.receiverUid === uid
    );
    if (!participates && msgs.length > 0)
      return res.status(403).json({ error: "Forbidden" });

    res.json({ messages: serializeDocs(msgs) });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/messages", async (req, res) => {
  try {
    const uid = req.uid!;
    const { conversationId, receiverUid, text } = req.body;
    if (!conversationId || !receiverUid || !text)
      return res.status(400).json({ error: "conversationId, receiverUid, text required" });

    const ref = await db.collection("messages").add({
      conversationId,
      senderUid: uid,
      receiverUid,
      text,
      participantUids: [uid, receiverUid],
      createdAt: FieldValue.serverTimestamp(),
    });

    res.json({ id: ref.id, sent: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Group Messages (polling) ────────────────────────────────────────────────

router.get("/groups", async (req, res) => {
  try {
    const uid = req.uid!;
    const groups = await queryDocs(
      "group_conversations",
      [{ field: "participantUids", op: "array-contains", value: uid }]
    );
    res.json({ groups: serializeDocs(groups) });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/group-messages/:groupId", async (req, res) => {
  try {
    const groupId = req.params.groupId as string;
    const snap = await db.collection("group_conversations").doc(groupId)
      .collection("messages")
      .orderBy("createdAt", "asc")
      .limit(200)
      .get();

    const msgs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    res.json({ messages: serializeDocs(msgs) });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/group-messages/:groupId", async (req, res) => {
  try {
    const groupId = req.params.groupId as string;
    const uid = req.uid!;
    const { text, senderName } = req.body;
    if (!text)
      return res.status(400).json({ error: "text required" });

    const ref = await db.collection("group_conversations").doc(groupId)
      .collection("messages").add({
        text,
        senderUid: uid,
        senderName: senderName || "",
        createdAt: FieldValue.serverTimestamp(),
      });

    res.json({ id: ref.id, sent: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Weekly Report ───────────────────────────────────────────────────────────

router.get("/report/weekly", async (req, res) => {
  try {
    const { studentUid, startDate, endDate } = req.query as Record<string, string>;
    if (!studentUid)
      return res.status(400).json({ error: "studentUid required" });

    const start = startDate || new Date(Date.now() - 7 * 86400000).toISOString().slice(0, 10);
    const end = endDate || new Date().toISOString().slice(0, 10);

    const [grades, behavior, attendance] = await Promise.all([
      queryDocs("grades", [{ field: "studentUid", op: "==", value: studentUid }]),
      queryDocs("behavior_points", [{ field: "studentUid", op: "==", value: studentUid }]),
      queryDocs("attendance", [
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
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Schedule (Timetable) ────────────────────────────────────────────────────

router.put(
  "/schedule",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const { grade, section, dayOfWeek, periods } = req.body;
      if (!grade || !section || !dayOfWeek || !Array.isArray(periods))
        return res
          .status(400)
          .json({ error: "grade, section, dayOfWeek, periods[] required" });

      const docId = `${grade}_${section}_${dayOfWeek}`;
      await db
        .collection("schedules")
        .doc(docId)
        .set(
          {
            grade,
            section,
            dayOfWeek,
            periods,
            createdBy: req.uid,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

      res.json({ id: docId, saved: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

router.get("/schedule/:grade/:section", requireAuth, async (req, res) => {
  try {
    const grade = req.params.grade as string;
    const section = req.params.section as string;

    const snap = await db
      .collection("schedules")
      .where("grade", "==", grade)
      .where("section", "==", section)
      .orderBy("dayOfWeek", "asc")
      .get();

    const schedules = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    res.json({ schedules: serializeDocs(schedules) });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Teacher Weekly Calendar ─────────────────────────────────────────────────

router.get(
  "/teacher-calendar/:uid",
  requireAuth,
  async (req, res) => {
    try {
      const uid = req.params.uid as string;
      const weekStart = req.query.weekStart as string; // YYYY-MM-DD
      const weekEnd = req.query.weekEnd as string; // YYYY-MM-DD

      const userDoc = await getDoc("users", uid);
      const teacherName = userDoc?.name || "";

      const classSnap = await db
        .collection("classes")
        .where("teacherUid", "==", uid)
        .get();
      const teacherClasses = classSnap.docs.map((d) => ({
        id: d.id,
        ...d.data(),
      }));

      const gradeSections = new Set<string>();
      for (const cls of teacherClasses) {
        const name = (cls as any).name || "";
        const match = name.match(/(\d+)\s*[—-]\s*Section\s*(\w+)/i);
        if (match) gradeSections.add(`${match[1]}_${match[2]}`);
      }

      const schedulePromises = Array.from(gradeSections).map((gs) => {
        const [grade, section] = gs.split("_");
        return db
          .collection("schedules")
          .where("grade", "==", grade)
          .where("section", "==", section)
          .get();
      });
      const schedSnaps = await Promise.all(schedulePromises);

      const classIdSet = new Set(teacherClasses.map((c: any) => c.id));
      const myPeriods: any[] = [];
      for (const snap of schedSnaps) {
        for (const doc of snap.docs) {
          const data = doc.data();
          const periods = (data.periods || []) as any[];
          for (const p of periods) {
            if (classIdSet.has(p.classId) || p.teacherName === teacherName) {
              myPeriods.push({
                dayOfWeek: data.dayOfWeek,
                grade: data.grade,
                section: data.section,
                ...p,
              });
            }
          }
        }
      }

      let events: any[] = [];
      if (weekStart && weekEnd) {
        const evSnap = await db
          .collection("schedule_events")
          .where("date", ">=", weekStart)
          .where("date", "<=", weekEnd)
          .get();
        events = evSnap.docs.map((d) => {
          const data = d.data();
          return {
            id: d.id,
            ...data,
            createdAt: data.createdAt?.toDate?.()?.toISOString?.() || null,
          };
        });
      }

      res.json({ periods: myPeriods, events });
    } catch (err: any) {
      console.error("teacher-calendar error:", err);
      res.status(500).json({ error: err.message });
    }
  }
);

// ─── Schedule Events (Special Days) ─────────────────────────────────────────

router.post(
  "/schedule-event",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const { title, description, date, startTime, endTime, type, affectedGrades, cancelsRegularSchedule } =
        req.body;
      if (!title || !date)
        return res.status(400).json({ error: "title, date required" });

      const ref = await db.collection("schedule_events").add({
        title,
        description: description || "",
        date,
        startTime: startTime || "",
        endTime: endTime || "",
        type: type || "event",
        createdBy: req.uid,
        affectedGrades: Array.isArray(affectedGrades) ? affectedGrades : [],
        cancelsRegularSchedule: cancelsRegularSchedule === true,
        createdAt: FieldValue.serverTimestamp(),
      });

      cacheDeletePrefix("teacher_dash_");
      res.json({ id: ref.id, created: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

router.delete(
  "/schedule-event/:id",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const docId = req.params.id as string;
      const ref = db.collection("schedule_events").doc(docId);
      const snap = await ref.get();
      if (!snap.exists) return res.status(404).json({ error: "Not found" });
      await ref.delete();
      res.json({ deleted: true });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
);

router.get("/schedule-events", requireAuth, async (req, res) => {
  try {
    const start = req.query.start as string;
    const end = req.query.end as string;
    if (!start || !end)
      return res.status(400).json({ error: "start, end required" });

    const snap = await db
      .collection("schedule_events")
      .where("date", ">=", start)
      .where("date", "<=", end)
      .orderBy("date", "asc")
      .get();

    const events = snap.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        ...data,
        createdAt: data.createdAt?.toDate?.()?.toISOString?.() || null,
      };
    });
    res.json({ events });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
