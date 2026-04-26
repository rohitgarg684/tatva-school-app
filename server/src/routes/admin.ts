import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db } from "../lib/firestore-helpers";
import { asyncHandler } from "../lib/async-handler";
import { Collections } from "../lib/collections";

const router = Router();

router.post(
  "/auth/sync-claims",
  requireAuth,
  asyncHandler(async (req, res) => {
    const uid = req.uid!;
    const userDoc = await db.collection(Collections.USERS).doc(uid).get();
    const role = userDoc.data()?.role;

    if (!role) {
      return res.status(404).json({ error: "User profile not found" });
    }

    await admin.auth().setCustomUserClaims(uid, { role });
    res.json({ role, synced: true });
  })
);

router.post(
  "/admin/set-role",
  requireAuth,
  requireRole("Principal"),
  asyncHandler(async (req, res) => {
    const { targetUid, role } = req.body;

    if (!targetUid || !role) {
      return res.status(400).json({ error: "targetUid and role are required" });
    }

    const validRoles = ["Student", "Teacher", "Parent", "Principal"];
    if (!validRoles.includes(role)) {
      return res.status(400).json({ error: `Invalid role: ${role}` });
    }

    await admin.auth().setCustomUserClaims(targetUid, { role });
    await db.collection(Collections.USERS).doc(targetUid).update({ role });

    res.json({ targetUid, role, updated: true });
  })
);

export default router;
