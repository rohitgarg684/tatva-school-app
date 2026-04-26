import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";

const router = Router();
router.use(requireAuth);

router.post(
  "/content/:contentId/complete",
  requireRole("Student"),
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const contentId = req.params.contentId as string;

    await db.collection(Collections.CONTENT).doc(contentId).update({
      completedBy: admin.firestore.FieldValue.arrayUnion(uid),
    });

    cacheDeletePrefix("student_dash_");
    res.json({ contentId, completed: true });
  })
);

export default router;
