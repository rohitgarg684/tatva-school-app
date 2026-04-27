import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, getDoc } from "../lib/firestore-helpers";
import { invalidateDashboards } from "../lib/cache-invalidation";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";
import { logActivity } from "../lib/activity-logger";

const router = Router();
router.use(requireAuth);

// ─── Mark content completed (Student) ────────────────────────────────────────

router.post(
  "/content/:contentId/complete",
  requireRole("Student"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const contentId = req.params.contentId as string;

    await db.collection(Collections.CONTENT).doc(contentId).update({
      completedBy: admin.firestore.FieldValue.arrayUnion(uid),
    });

    invalidateDashboards("content_");
    res.json({ contentId, completed: true });
  })
);

// ─── Create content (Teacher / Principal) ────────────────────────────────────

router.post(
  "/content",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const { title, description, category, duration, grade, studentUids } = req.body;

    if (!title || !category) {
      return res.status(400).json({ error: "title and category are required" });
    }

    const doc: Record<string, any> = {
      title,
      description: description || "",
      category,
      duration: duration || "",
      grade: grade || "",
      studentUids: Array.isArray(studentUids) ? studentUids : [],
      createdBy: uid,
      completedBy: [],
      videoUrl: "",
      thumbnailUrl: "",
      ageGroup: "All",
      viewCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const ref = await db.collection(Collections.CONTENT).add(doc);

    const user = await getDoc(Collections.USERS, uid);
    logActivity({
      type: "storyPost",
      actorUid: uid,
      actorName: (user as any)?.name || "",
      actorRole: req.role,
      title: `New learning content: ${title}`,
      body: description || "",
    });

    invalidateDashboards("content_");
    res.json({ id: ref.id, ...doc, createdAt: new Date().toISOString() });
  })
);

// ─── Update content (owner or Principal) ─────────────────────────────────────

router.put(
  "/content/:contentId",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const contentId = req.params.contentId as string;
    const existing = await db.collection(Collections.CONTENT).doc(contentId).get();

    if (!existing.exists) {
      return res.status(404).json({ error: "Content not found" });
    }

    const data = existing.data()!;
    if (data.createdBy !== uid && req.role !== "Principal") {
      return res.status(403).json({ error: "You can only edit your own content" });
    }

    const updates: Record<string, any> = {};
    const allowed = ["title", "description", "category", "duration", "grade", "studentUids"];
    for (const key of allowed) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }

    await db.collection(Collections.CONTENT).doc(contentId).update(updates);

    invalidateDashboards("content_");
    res.json({ contentId, updated: true });
  })
);

// ─── Delete content (owner or Principal) ─────────────────────────────────────

router.delete(
  "/content/:contentId",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const contentId = req.params.contentId as string;
    const existing = await db.collection(Collections.CONTENT).doc(contentId).get();

    if (!existing.exists) {
      return res.status(404).json({ error: "Content not found" });
    }

    const data = existing.data()!;
    if (data.createdBy !== uid && req.role !== "Principal") {
      return res.status(403).json({ error: "You can only delete your own content" });
    }

    await db.collection(Collections.CONTENT).doc(contentId).delete();

    invalidateDashboards("content_");
    res.json({ contentId, deleted: true });
  })
);

export default router;
