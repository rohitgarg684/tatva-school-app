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

const FieldValue = admin.firestore.FieldValue;

const DEFAULT_OPTIONS = ["school", "no_school", "undecided"];

function buildVotesMap(options: string[]): Record<string, number> {
  const m: Record<string, number> = {};
  for (const o of options) m[o] = 0;
  return m;
}

router.post(
  "/vote",
  requireRole("Principal", "Teacher"),
  asyncHandler(async (req, res) => {
    const { question, type, options, votingDeadline, resultsVisibleUntil } = req.body;
    if (!question)
      return res.status(400).json({ error: "question required" });
    if (!votingDeadline || !resultsVisibleUntil)
      return res.status(400).json({ error: "votingDeadline and resultsVisibleUntil required" });

    const uid = req.uid!;
    const userDoc = await getDoc(Collections.USERS, uid);
    const opts: string[] = Array.isArray(options) && options.length >= 2 ? options : DEFAULT_OPTIONS;

    const ref = await db.collection(Collections.VOTES).add({
      question,
      type: type || "school_decision",
      options: opts,
      createdBy: uid,
      createdByName: userDoc?.name || "",
      createdByRole: req.role || "",
      votes: buildVotesMap(opts),
      voters: [],
      active: true,
      votingDeadline,
      resultsVisibleUntil,
      createdAt: FieldValue.serverTimestamp(),
    });

    logActivity({
      type: "voteCreated",
      actorUid: uid,
      actorName: userDoc?.name || "",
      actorRole: req.role || "Teacher",
      title: `Vote: ${question}`,
    });

    invalidateDashboards("votes_visible");
    res.json({ id: ref.id, created: true });
  })
);

router.put(
  "/vote/:voteId",
  requireRole("Principal", "Teacher"),
  asyncHandler(async (req, res) => {
    const voteId = req.params.voteId as string;
    const uid = req.uid!;
    const ref = db.collection(Collections.VOTES).doc(voteId);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: "Vote not found" });

    const data = snap.data()!;
    if (data.createdBy !== uid)
      return res.status(403).json({ error: "Only the creator can edit this vote" });

    const updates: Record<string, unknown> = {};
    const { question, type, options, votingDeadline, resultsVisibleUntil } = req.body;
    if (question) updates.question = question;
    if (type) updates.type = type;
    if (votingDeadline) updates.votingDeadline = votingDeadline;
    if (resultsVisibleUntil) updates.resultsVisibleUntil = resultsVisibleUntil;

    if (Array.isArray(options) && options.length >= 2) {
      const voters: string[] = data.voters || [];
      if (voters.length > 0)
        return res.status(400).json({ error: "Cannot change options after votes have been cast" });
      updates.options = options;
      updates.votes = buildVotesMap(options);
    }

    await ref.update(updates);
    invalidateDashboards("votes_visible");
    res.json({ voteId, updated: true });
  })
);

router.delete(
  "/vote/:voteId",
  requireRole("Principal", "Teacher"),
  asyncHandler(async (req, res) => {
    const voteId = req.params.voteId as string;
    const uid = req.uid!;
    const ref = db.collection(Collections.VOTES).doc(voteId);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: "Vote not found" });

    const data = snap.data()!;
    if (data.createdBy !== uid && req.role !== "Principal")
      return res.status(403).json({ error: "Not authorized to delete this vote" });

    await ref.delete();
    invalidateDashboards("votes_visible");
    res.json({ voteId, deleted: true });
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

    if (data.votingDeadline && new Date(data.votingDeadline) < new Date())
      return res.status(400).json({ error: "Voting deadline has passed" });

    const voters: string[] = data.voters || [];
    if (voters.includes(uid)) {
      return res.status(409).json({ error: "Already voted" });
    }

    const validOptions: string[] = data.options || DEFAULT_OPTIONS;
    if (!validOptions.includes(choice))
      return res.status(400).json({ error: "Invalid choice" });

    const voteKey = `votes.${choice}`;
    await ref.update({
      [voteKey]: FieldValue.increment(1),
      voters: FieldValue.arrayUnion(uid),
    });

    invalidateDashboards("votes_visible");
    res.json({ voteId, voted: true, choice });
  })
);

router.post(
  "/vote/:voteId/close",
  requireRole("Principal", "Teacher"),
  asyncHandler(async (req, res) => {
    const voteId = req.params.voteId as string;
    const uid = req.uid!;
    const ref = db.collection(Collections.VOTES).doc(voteId);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: "Vote not found" });

    const data = snap.data()!;
    if (data.createdBy !== uid && req.role !== "Principal")
      return res.status(403).json({ error: "Not authorized" });

    await ref.update({ active: false });
    invalidateDashboards("votes_visible");

    res.json({ voteId, closed: true });
  })
);

router.get(
  "/votes/history",
  requireRole("Principal", "Teacher"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const role = req.role!;
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);
    const after = req.query.after as string | undefined;

    let query: FirebaseFirestore.Query = db
      .collection(Collections.VOTES)
      .orderBy("createdAt", "desc");

    if (role === "Teacher") {
      query = query.where("createdBy", "==", uid);
    }

    if (after) {
      query = query.where("createdAt", "<", new Date(after));
    }

    const snap = await query.limit(limit + 1).get();
    const docs = snap.docs.map((d) => {
      const data = d.data();
      const ts = data.createdAt;
      return {
        id: d.id,
        ...data,
        createdAt: ts?.toDate ? ts.toDate().toISOString() : ts,
      };
    });
    const hasMore = docs.length > limit;
    res.json({ votes: docs.slice(0, limit), hasMore });
  })
);

export default router;
