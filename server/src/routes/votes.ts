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
  "/vote",
  requireRole("Principal"),
  asyncHandler(async (req, res) => {
    const { question, type } = req.body;
    if (!question)
      return res.status(400).json({ error: "question required" });

    const uid = req.uid!;
    const userDoc = await getDoc(Collections.USERS, uid);

    const ref = await db.collection(Collections.VOTES).add({
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
  })
);

router.post(
  "/vote/:voteId/cast",
  requireRole("Student", "Parent"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const voteId = req.params.voteId as string;
    const { choice } = req.body;

    if (!choice) return res.status(400).json({ error: "choice required" });

    const ref = db.collection(Collections.VOTES).doc(voteId);
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
      [voteKey]: FieldValue.increment(1),
      voters: FieldValue.arrayUnion(uid),
    });

    cacheDeletePrefix("votes_active");
    res.json({ voteId, voted: true, choice });
  })
);

router.post(
  "/vote/:voteId/close",
  requireRole("Principal"),
  asyncHandler(async (req, res) => {
    const voteId = req.params.voteId as string;

    await db.collection(Collections.VOTES).doc(voteId).update({ active: false });
    cacheDeletePrefix("votes_active");

    res.json({ voteId, closed: true });
  })
);

export default router;
