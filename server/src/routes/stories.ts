import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db, getDoc } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";

const router = Router();
router.use(requireAuth);

const FieldValue = admin.firestore.FieldValue;

router.post(
  "/story",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { classId, className, text, mediaUrls, mediaType } = req.body;
    if (!classId || !text)
      return res.status(400).json({ error: "classId, text required" });

    const uid = req.uid!;
    const userDoc = await getDoc(Collections.USERS, uid);

    const ref = await db.collection(Collections.STORIES).add({
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
  })
);

router.post(
  "/story/:storyId/like",
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const storyId = req.params.storyId as string;

    const ref = db.collection(Collections.STORIES).doc(storyId);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: "Story not found" });

    const likedBy: string[] = snap.data()?.likedBy || [];
    const isLiked = likedBy.includes(uid);

    await ref.update({
      likedBy: isLiked
        ? FieldValue.arrayRemove(uid)
        : FieldValue.arrayUnion(uid),
    });

    cacheDeletePrefix("teacher_dash_");
    cacheDeletePrefix("student_dash_");
    cacheDeletePrefix("parent_dash_");
    res.json({ storyId, liked: !isLiked });
  })
);

export default router;
