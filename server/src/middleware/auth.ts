import { Request, Response, NextFunction } from "express";
import * as admin from "firebase-admin";
import { db } from "../lib/firestore-helpers";
import { Collections } from "../lib/collections";

declare global {
  namespace Express {
    interface Request {
      uid?: string;
      role?: string;
    }
  }
}

export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    res.status(401).json({ error: "Missing or invalid Authorization header" });
    return;
  }

  try {
    const token = header.slice(7);
    const decoded = await admin.auth().verifyIdToken(token);
    req.uid = decoded.uid;
    req.role = (decoded as any).role || null;

    if (!req.role) {
      const userDoc = await db.collection(Collections.USERS).doc(decoded.uid).get();
      const firestoreRole = userDoc.data()?.role;
      if (firestoreRole) {
        req.role = firestoreRole;
        admin
          .auth()
          .setCustomUserClaims(decoded.uid, { role: firestoreRole })
          .catch(() => {});
      }
    }

    next();
  } catch {
    res.status(401).json({ error: "Invalid or expired token" });
  }
}

export function requireRole(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.role || !roles.includes(req.role)) {
      res.status(403).json({ error: "Forbidden: insufficient role" });
      return;
    }
    next();
  };
}
