import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, getDoc, serializeDocs } from "../lib/firestore-helpers";
import { invalidateDashboards } from "../lib/cache-invalidation";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { Config } from "../lib/config";
import { logActivity } from "../lib/activity-logger";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

router.post(
  "/announcement",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { title, body: bodyText, audience, grades, attachments } = req.body;
    if (!title || !bodyText)
      return res.status(400).json({ error: "title, body required" });

    const uid = req.uid!;
    const userDoc = await getDoc(Collections.USERS, uid);

    const ref = await db.collection(Collections.ANNOUNCEMENTS).add({
      title,
      body: bodyText,
      audience: Array.isArray(grades) && grades.length > 0 ? "Grades" : "Everyone",
      grades: Array.isArray(grades) ? grades : [],
      classIds: [],
      createdBy: uid,
      createdByName: userDoc?.name || "",
      createdByRole: req.role || "",
      likedBy: [],
      commentCount: 0,
      attachments: Array.isArray(attachments) ? attachments : [],
      createdAt: FieldValue.serverTimestamp(),
    });

    logActivity({
      type: "announcement",
      actorUid: uid,
      actorName: userDoc?.name || "",
      actorRole: req.role || "",
      title: `Announcement: ${title}`,
      body: bodyText,
    });

    invalidateDashboards("announcements_");
    res.json({ id: ref.id, created: true });
  })
);

router.get(
  "/announcements",
  asyncHandler(async (req, res) => {
    const grade = req.query.grade as string | undefined;
    const limit = Math.min(
      parseInt(req.query.limit as string) || Config.ANNOUNCEMENTS_LIMIT,
      100
    );

    let query = db
      .collection(Collections.ANNOUNCEMENTS)
      .orderBy("createdAt", "desc")
      .limit(limit);

    const snap = await query.get();
    let docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

    if (grade) {
      docs = docs.filter(
        (d: any) =>
          d.audience === "Everyone" ||
          (Array.isArray(d.grades) && d.grades.includes(grade))
      );
    }

    res.json({ announcements: serializeDocs(docs) });
  })
);

router.get(
  "/announcements/paginated",
  asyncHandler(async (req, res) => {
    const grade = req.query.grade as string | undefined;
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 50);
    const after = req.query.after as string | undefined;

    let query: FirebaseFirestore.Query = db
      .collection(Collections.ANNOUNCEMENTS)
      .orderBy("createdAt", "desc");

    if (after) {
      query = query.where("createdAt", "<", new Date(after));
    }

    const fetchLimit = grade ? limit * 3 : limit + 1;
    const snap = await query.limit(fetchLimit).get();
    let docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

    if (grade) {
      docs = docs.filter(
        (d: any) =>
          d.audience === "Everyone" ||
          (Array.isArray(d.grades) && d.grades.includes(grade))
      );
    }

    const hasMore = docs.length > limit;
    const items = serializeDocs(docs.slice(0, limit));
    res.json({ items, hasMore });
  })
);

router.post(
  "/announcement/:id/like",
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const id = req.params.id as string;

    const ref = db.collection(Collections.ANNOUNCEMENTS).doc(id);
    const snap = await ref.get();
    if (!snap.exists)
      return res.status(404).json({ error: "Announcement not found" });

    const likedBy: string[] = snap.data()?.likedBy || [];
    const isLiked = likedBy.includes(uid);

    await ref.update({
      likedBy: isLiked
        ? FieldValue.arrayRemove(uid)
        : FieldValue.arrayUnion(uid),
    });

    invalidateDashboards("announcements_");
    res.json({ id, liked: !isLiked });
  })
);

router.put(
  "/announcement/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const id = req.params.id as string;
    const { title, body: bodyText, grades, attachments } = req.body;

    const ref = db.collection(Collections.ANNOUNCEMENTS).doc(id);
    const snap = await ref.get();
    if (!snap.exists)
      return res.status(404).json({ error: "Announcement not found" });

    const data = snap.data()!;
    if (data.createdBy !== uid && req.role !== "Principal") {
      return res.status(403).json({ error: "Only author or principal can edit" });
    }

    const updates: Record<string, any> = {};
    if (title) updates.title = title;
    if (bodyText) updates.body = bodyText;
    if (grades !== undefined) {
      updates.grades = Array.isArray(grades) ? grades : [];
      updates.audience = Array.isArray(grades) && grades.length > 0 ? "Grades" : "Everyone";
    }
    if (attachments !== undefined) {
      updates.attachments = Array.isArray(attachments) ? attachments : [];
    }

    await ref.update(updates);
    invalidateDashboards("announcements_");
    res.json({ id, updated: true });
  })
);

router.delete(
  "/announcement/:id",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const id = req.params.id as string;

    const ref = db.collection(Collections.ANNOUNCEMENTS).doc(id);
    const snap = await ref.get();
    if (!snap.exists)
      return res.status(404).json({ error: "Announcement not found" });

    const data = snap.data()!;
    if (data.createdBy !== uid && req.role !== "Principal") {
      return res.status(403).json({ error: "Only author or principal can delete" });
    }

    await ref.delete();
    invalidateDashboards("announcements_");
    res.json({ deleted: true });
  })
);

export default router;
