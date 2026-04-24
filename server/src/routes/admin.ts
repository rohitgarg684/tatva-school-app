import { Router } from "express";
import * as admin from "firebase-admin";
import { requireAuth, requireRole } from "../middleware/auth";
import { db } from "../lib/firestore-helpers";

const router = Router();

// POST /api/auth/sync-claims
// Any authenticated user can call this for themselves.
// Reads role from Firestore, stamps it as a custom claim.
router.post("/auth/sync-claims", requireAuth, async (req, res) => {
  try {
    const uid = req.uid!;
    const userDoc = await db.collection("users").doc(uid).get();
    const role = userDoc.data()?.role;

    if (!role) {
      return res.status(404).json({ error: "User profile not found" });
    }

    await admin.auth().setCustomUserClaims(uid, { role });
    res.json({ role, synced: true });
  } catch (err: any) {
    console.error("sync-claims error:", err);
    res.status(500).json({ error: err.message || "Internal server error" });
  }
});

// POST /api/admin/set-role
// Principal-only. Changes a user's role in both Firestore and custom claims.
router.post(
  "/admin/set-role",
  requireAuth,
  requireRole("Principal"),
  async (req, res) => {
    try {
      const { targetUid, role } = req.body;

      if (!targetUid || !role) {
        return res
          .status(400)
          .json({ error: "targetUid and role are required" });
      }

      const validRoles = ["Student", "Teacher", "Parent", "Principal"];
      if (!validRoles.includes(role)) {
        return res.status(400).json({ error: `Invalid role: ${role}` });
      }

      await admin.auth().setCustomUserClaims(targetUid, { role });
      await db.collection("users").doc(targetUid).update({ role });

      res.json({ targetUid, role, updated: true });
    } catch (err: any) {
      console.error("set-role error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

export default router;
