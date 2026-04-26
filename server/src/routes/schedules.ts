import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, getDoc, serializeDocs, serializeDoc } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";
import { asyncHandler } from "../lib/async-handler";
import { deleteDocument } from "../lib/crud-helpers";
import { Collections } from "../lib/collections";
import { SchedulePeriod } from "../models";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

router.put(
  "/schedule",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { grade, section, dayOfWeek, periods } = req.body;
    if (!grade || !section || !dayOfWeek || !Array.isArray(periods))
      return res.status(400).json({ error: "grade, section, dayOfWeek, periods[] required" });

    const docId = `${grade}_${section}_${dayOfWeek}`;
    await db.collection(Collections.SCHEDULES).doc(docId).set(
      { grade, section, dayOfWeek, periods, createdBy: req.uid, updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );

    res.json({ id: docId, saved: true });
  })
);

router.get(
  "/schedule/:grade/:section",
  asyncHandler(async (req, res) => {
    const grade = req.params.grade as string;
    const section = req.params.section as string;

    const now = new Date();
    const monday = new Date(now);
    monday.setDate(now.getDate() - ((now.getDay() + 6) % 7));
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    const wsStr = monday.toISOString().substring(0, 10);
    const weStr = sunday.toISOString().substring(0, 10);

    const [schedSnap, cancelSnap] = await Promise.all([
      db.collection(Collections.SCHEDULES)
        .where("grade", "==", grade)
        .where("section", "==", section)
        .orderBy("dayOfWeek", "asc")
        .get(),
      db.collection(Collections.PERIOD_CANCELLATIONS)
        .where("grade", "==", grade)
        .where("section", "==", section)
        .where("date", ">=", wsStr)
        .where("date", "<=", weStr)
        .get(),
    ]);

    const schedules = schedSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const cancellations = cancelSnap.docs.map((d) => serializeDoc({ id: d.id, ...d.data() }));
    res.json({ schedules: serializeDocs(schedules), cancellations });
  })
);

router.get(
  "/teacher-calendar/:uid",
  asyncHandler(async (req, res) => {
    const uid = req.params.uid as string;
    const weekStart = req.query.weekStart as string;
    const weekEnd = req.query.weekEnd as string;

    const userDoc = await getDoc(Collections.USERS, uid);
    const teacherName = userDoc?.name || "";

    const classSnap = await db.collection(Collections.CLASSES)
      .where("teacherUid", "==", uid).get();
    const teacherClasses = classSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

    const gradeSections = new Set<string>();
    for (const cls of teacherClasses) {
      const name = (cls as any).name || "";
      const match = name.match(/(\d+)\s*[—-]\s*Section\s*(\w+)/i);
      if (match) gradeSections.add(`${match[1]}_${match[2]}`);
    }

    const schedulePromises = Array.from(gradeSections).map((gs) => {
      const [grade, section] = gs.split("_");
      return db.collection(Collections.SCHEDULES)
        .where("grade", "==", grade)
        .where("section", "==", section)
        .get();
    });
    const schedSnaps = await Promise.all(schedulePromises);

    const classIdSet = new Set(teacherClasses.map((c: any) => c.id));
    const myPeriods: Array<SchedulePeriod & { dayOfWeek: string; grade: string; section: string }> = [];
    for (const snap of schedSnaps) {
      for (const doc of snap.docs) {
        const data = doc.data();
        const periods = (data.periods || []) as any[];
        for (const p of periods) {
          if (classIdSet.has(p.classId) || p.teacherName === teacherName) {
            myPeriods.push({ dayOfWeek: data.dayOfWeek, grade: data.grade, section: data.section, ...p });
          }
        }
      }
    }

    let events: any[] = [];
    if (weekStart && weekEnd) {
      const evSnap = await db.collection(Collections.SCHEDULE_EVENTS)
        .where("date", ">=", weekStart).where("date", "<=", weekEnd).get();
      events = evSnap.docs.map((d) => serializeDoc({ id: d.id, ...d.data() }));
    }

    let cancellations: any[] = [];
    if (weekStart && weekEnd) {
      const cancelSnap = await db.collection(Collections.PERIOD_CANCELLATIONS)
        .where("date", ">=", weekStart).where("date", "<=", weekEnd).get();
      cancellations = cancelSnap.docs.map((d) => serializeDoc({ id: d.id, ...d.data() }));
    }

    res.json({ periods: myPeriods, events, cancellations });
  })
);

router.post(
  "/schedule-event",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { title, description, date, startTime, endTime, type, affectedGrades, cancelsRegularSchedule } = req.body;
    if (!title || !date)
      return res.status(400).json({ error: "title, date required" });

    const ref = await db.collection(Collections.SCHEDULE_EVENTS).add({
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
  })
);

router.delete(
  "/schedule-event/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    await deleteDocument(
      Collections.SCHEDULE_EVENTS,
      req.params.id as string,
      res
    );
  })
);

router.get(
  "/schedule-events",
  asyncHandler(async (req, res) => {
    const start = req.query.start as string;
    const end = req.query.end as string;
    if (!start || !end)
      return res.status(400).json({ error: "start, end required" });

    const snap = await db.collection(Collections.SCHEDULE_EVENTS)
      .where("date", ">=", start)
      .where("date", "<=", end)
      .orderBy("date", "asc")
      .get();

    const events = snap.docs.map((d) => serializeDoc({ id: d.id, ...d.data() }));
    res.json({ events });
  })
);

router.post(
  "/period-cancellation",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { grade, section, date, startTime, classId, reason } = req.body;
    if (!grade || !section || !date || !startTime)
      return res.status(400).json({ error: "grade, section, date, startTime required" });

    const docId = `${grade}_${section}_${date}_${startTime.replace(":", "")}`;
    await db.collection(Collections.PERIOD_CANCELLATIONS).doc(docId).set({
      grade, section, date, startTime,
      classId: classId || "",
      reason: reason || "",
      cancelledBy: req.uid,
      createdAt: FieldValue.serverTimestamp(),
    });

    cacheDeletePrefix("teacher_dash_");
    cacheDeletePrefix("student_dash_");
    res.json({ id: docId, cancelled: true });
  })
);

router.delete(
  "/period-cancellation/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    await deleteDocument(
      Collections.PERIOD_CANCELLATIONS,
      req.params.id as string,
      res,
      ["teacher_dash_", "student_dash_"]
    );
  })
);

export default router;
