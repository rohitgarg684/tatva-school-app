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
  "/announcement",
  requireRole("Teacher", "Principal"),
  asyncHandler(async (req, res) => {
    const { title, body: bodyText, audience } = req.body;
    if (!title || !bodyText)
      return res.status(400).json({ error: "title, body required" });

    const uid = req.uid!;
    const userDoc = await getDoc(Collections.USERS, uid);

    const ref = await db.collection(Collections.ANNOUNCEMENTS).add({
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
  })
);

export default router;
