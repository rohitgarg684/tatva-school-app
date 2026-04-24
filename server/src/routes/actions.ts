import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";

const router = Router();
router.use(requireAuth);

// POST /api/story/:storyId/like  — any authenticated user
router.post("/story/:storyId/like", async (req, res) => {
  try {
    const uid = req.uid!;
    const { storyId } = req.params;

    const ref = db.collection("stories").doc(storyId);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: "Story not found" });

    const likedBy: string[] = snap.data()?.likedBy || [];
    const isLiked = likedBy.includes(uid);

    await ref.update({
      likedBy: isLiked
        ? admin.firestore.FieldValue.arrayRemove(uid)
        : admin.firestore.FieldValue.arrayUnion(uid),
    });

    res.json({ storyId, liked: !isLiked });
  } catch (err: any) {
    console.error("toggleStoryLike error:", err);
    res.status(500).json({ error: err.message || "Internal server error" });
  }
});

// POST /api/homework/:homeworkId/submit  — Student only
router.post(
  "/homework/:homeworkId/submit",
  requireRole("Student"),
  async (req, res) => {
    try {
      const uid = req.uid!;
      const homeworkId = req.params.homeworkId as string;

      await db.collection("homework").doc(homeworkId).update({
        submittedBy: admin.firestore.FieldValue.arrayUnion(uid),
      });

      cacheDeletePrefix("student_dash_");
      res.json({ homeworkId, submitted: true });
    } catch (err: any) {
      console.error("submitHomework error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// POST /api/content/:contentId/complete  — Student only
router.post(
  "/content/:contentId/complete",
  requireRole("Student"),
  async (req, res) => {
    try {
      const uid = req.uid!;
      const contentId = req.params.contentId as string;

      await db.collection("content").doc(contentId).update({
        completedBy: admin.firestore.FieldValue.arrayUnion(uid),
      });

      res.json({ contentId, completed: true });
    } catch (err: any) {
      console.error("markContentCompleted error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// POST /api/vote/:voteId/cast  — Student, Parent
router.post(
  "/vote/:voteId/cast",
  requireRole("Student", "Parent"),
  async (req, res) => {
    try {
      const uid = req.uid!;
      const voteId = req.params.voteId as string;
      const { choice } = req.body;

      if (!choice) return res.status(400).json({ error: "choice required" });

      const ref = db.collection("votes").doc(voteId);
      const snap = await ref.get();
      if (!snap.exists)
        return res.status(404).json({ error: "Vote not found" });

      const data = snap.data()!;
      const voters: string[] = data.voters || [];
      if (voters.includes(uid)) {
        return res.status(409).json({ error: "Already voted" });
      }

      const voteKey = `votes.${choice}`;
      await ref.update({
        [voteKey]: admin.firestore.FieldValue.increment(1),
        voters: admin.firestore.FieldValue.arrayUnion(uid),
      });

      res.json({ voteId, voted: true, choice });
    } catch (err: any) {
      console.error("castVote error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// POST /api/vote/:voteId/close  — Principal only
router.post(
  "/vote/:voteId/close",
  requireRole("Principal"),
  async (req, res) => {
    try {
      const voteId = req.params.voteId as string;

      await db.collection("votes").doc(voteId).update({ active: false });
      cacheDeletePrefix("votes_active");

      res.json({ voteId, closed: true });
    } catch (err: any) {
      console.error("closeVote error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// POST /api/attendance  — Teacher, Principal
router.post(
  "/attendance",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const { records } = req.body;

      if (!Array.isArray(records) || records.length === 0) {
        return res.status(400).json({ error: "records array required" });
      }

      const batch = db.batch();
      for (const rec of records) {
        const docId = `${rec.studentUid}_${rec.date}`;
        const ref = db.collection("attendance").doc(docId);
        batch.set(
          ref,
          {
            ...rec,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
      await batch.commit();

      cacheDeletePrefix("teacher_dash_");
      res.json({ marked: records.length });
    } catch (err: any) {
      console.error("markAttendance error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// POST /api/behavior-point  — Teacher, Principal
router.post(
  "/behavior-point",
  requireRole("Teacher", "Principal"),
  async (req, res) => {
    try {
      const uid = req.uid!;
      const { studentUid, studentName, classId, categoryId, points, note } =
        req.body;

      if (!studentUid || !classId || !categoryId) {
        return res
          .status(400)
          .json({ error: "studentUid, classId, categoryId required" });
      }

      const userSnap = await db.collection("users").doc(uid).get();
      const awardedByName = userSnap.data()?.name || "";

      const ref = await db.collection("behavior_points").add({
        studentUid,
        studentName: studentName || "",
        classId,
        categoryId,
        points: points || 1,
        awardedBy: uid,
        awardedByName,
        note: note || "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      cacheDeletePrefix("student_dash_");
      cacheDeletePrefix("teacher_dash_");

      res.json({ id: ref.id, awarded: true });
    } catch (err: any) {
      console.error("awardBehaviorPoint error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

export default router;
