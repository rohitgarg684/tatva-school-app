import { Router, Request, Response } from "express";
import * as admin from "firebase-admin";
import multer from "multer";
import { requireAuth, requireRole } from "../middleware/auth";
import { isValidImage, isValidDocument } from "../lib/file-validation";

// ─── Image upload config ────────────────────────────────────────────────────

const IMAGE_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
];
const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5 MB

const imageUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_IMAGE_SIZE },
  fileFilter: (_req, file, cb) => {
    if (IMAGE_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new Error(
          `Invalid image type: ${file.mimetype}. Allowed: JPEG, PNG, GIF, WebP.`
        )
      );
    }
  },
});

// ─── Document upload config ─────────────────────────────────────────────────

const DOC_MIME_TYPES = [
  ...IMAGE_MIME_TYPES,
  "application/pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation",
];
const MAX_DOC_SIZE = 10 * 1024 * 1024; // 10 MB

const docUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_DOC_SIZE },
  fileFilter: (_req, file, cb) => {
    if (DOC_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new Error(
          `Invalid file type: ${file.mimetype}. Allowed: images, PDF, DOCX, XLSX, PPTX.`
        )
      );
    }
  },
});

// ─── Helpers ────────────────────────────────────────────────────────────────

const SIGNED_URL_EXPIRY_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

function sanitizeId(val: string): string {
  return val.replace(/[^a-zA-Z0-9_-]/g, "_");
}

function generateFileName(mimetype: string): string {
  const extMap: Record<string, string> = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/gif": "gif",
    "image/webp": "webp",
    "application/pdf": "pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
      "docx",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
      "xlsx",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation":
      "pptx",
  };
  const ext = extMap[mimetype] || "bin";
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}.${ext}`;
}

async function uploadToStorage(
  buffer: Buffer,
  storagePath: string,
  contentType: string
): Promise<string> {
  const bucket = admin.storage().bucket();
  const fileRef = bucket.file(storagePath);

  await fileRef.save(buffer, {
    metadata: { contentType },
  });

  const [signedUrl] = await fileRef.getSignedUrl({
    action: "read",
    expires: Date.now() + SIGNED_URL_EXPIRY_MS,
  });

  return signedUrl;
}

function handleMulterError(err: any, res: Response): boolean {
  if (err instanceof multer.MulterError) {
    if (err.code === "LIMIT_FILE_SIZE") {
      res.status(413).json({ error: "File too large." });
      return true;
    }
    res.status(400).json({ error: err.message });
    return true;
  }
  if (err?.message?.startsWith("Invalid")) {
    res.status(400).json({ error: err.message });
    return true;
  }
  return false;
}

// ─── Router ─────────────────────────────────────────────────────────────────

const router = Router();
router.use(requireAuth);

// POST /api/story/upload  (multipart: file + classId) — Teacher, Principal
router.post(
  "/story/upload",
  requireRole("Teacher", "Principal"),
  imageUpload.single("file"),
  async (req: Request, res: Response) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
      }

      if (!isValidImage(req.file.buffer)) {
        return res
          .status(400)
          .json({ error: "File content does not match a valid image format" });
      }

      const classId = req.body.classId;
      if (!classId || typeof classId !== "string") {
        return res.status(400).json({ error: "classId required" });
      }

      const storagePath = `stories/${sanitizeId(classId)}/${generateFileName(req.file.mimetype)}`;
      const url = await uploadToStorage(
        req.file.buffer,
        storagePath,
        req.file.mimetype
      );

      res.json({ url, path: storagePath });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("story upload error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// POST /api/document/upload  (multipart: file + classId) — Teacher, Principal
router.post(
  "/document/upload",
  requireRole("Teacher", "Principal"),
  docUpload.single("file"),
  async (req: Request, res: Response) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
      }

      if (!isValidDocument(req.file.buffer)) {
        return res
          .status(400)
          .json({ error: "File content does not match a valid document format" });
      }

      const classId = req.body.classId;
      if (!classId || typeof classId !== "string") {
        return res.status(400).json({ error: "classId required" });
      }

      const storagePath = `documents/${sanitizeId(classId)}/${generateFileName(req.file.mimetype)}`;
      const url = await uploadToStorage(
        req.file.buffer,
        storagePath,
        req.file.mimetype
      );

      res.json({ url, path: storagePath });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("document upload error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// ─── Homework file uploads ───────────────────────────────────────────────────

import { db, getDoc, serializeDocs } from "../lib/firestore-helpers";
import { cacheDeletePrefix } from "../lib/cache";

// POST /api/homework/:id/upload  — Teacher uploads attachment files
router.post(
  "/homework/:id/upload",
  requireRole("Teacher", "Principal"),
  docUpload.array("files", 10),
  async (req: Request, res: Response) => {
    try {
      const homeworkId = sanitizeId(req.params.id as string);
      const files = req.files as Express.Multer.File[];
      if (!files || files.length === 0) {
        return res.status(400).json({ error: "No files uploaded" });
      }

      const uploaded: { url: string; name: string; type: string }[] = [];
      for (const file of files) {
        if (!isValidDocument(file.buffer)) {
          return res.status(400).json({
            error: `File "${file.originalname}" has invalid content`,
          });
        }
        const ext = file.originalname.split(".").pop()?.toLowerCase() || "";
        const fileType = ["pdf"].includes(ext)
          ? "pdf"
          : ["jpg", "jpeg", "png", "gif", "webp"].includes(ext)
          ? "image"
          : "document";
        const storagePath = `homework/${homeworkId}/attachments/${generateFileName(file.mimetype)}`;
        const url = await uploadToStorage(file.buffer, storagePath, file.mimetype);
        uploaded.push({ url, name: file.originalname, type: fileType });
      }

      const hwRef = db.collection("homework").doc(homeworkId);
      await hwRef.update({
        attachments: admin.firestore.FieldValue.arrayUnion(...uploaded),
      });

      cacheDeletePrefix("teacher_dash_");
      cacheDeletePrefix("student_dash_");
      res.json({ uploaded });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("homework upload error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// POST /api/homework/:id/submit-files  — Student uploads submission files
router.post(
  "/homework/:id/submit-files",
  requireRole("Student"),
  docUpload.array("files", 10),
  async (req: Request, res: Response) => {
    try {
      const homeworkId = sanitizeId(req.params.id as string);
      const uid = req.uid!;
      const files = req.files as Express.Multer.File[];
      const note = (req.body.note as string) || "";

      const fileUrls: { url: string; name: string; type: string }[] = [];
      if (files && files.length > 0) {
        for (const file of files) {
          if (!isValidDocument(file.buffer)) {
            return res.status(400).json({
              error: `File "${file.originalname}" has invalid content`,
            });
          }
          const ext = file.originalname.split(".").pop()?.toLowerCase() || "";
          const fileType = ["pdf"].includes(ext)
            ? "pdf"
            : ["jpg", "jpeg", "png", "gif", "webp"].includes(ext)
            ? "image"
            : "document";
          const storagePath = `homework/${homeworkId}/submissions/${sanitizeId(uid)}/${generateFileName(file.mimetype)}`;
          const url = await uploadToStorage(file.buffer, storagePath, file.mimetype);
          fileUrls.push({ url, name: file.originalname, type: fileType });
        }
      }

      const subRef = db
        .collection("homework_submissions")
        .doc(`${homeworkId}_${uid}`);
      await subRef.set(
        {
          homeworkId,
          studentUid: uid,
          files: admin.firestore.FieldValue.arrayUnion(...(fileUrls.length > 0 ? fileUrls : [])),
          note,
          submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      await db
        .collection("homework")
        .doc(homeworkId)
        .update({
          submittedBy: admin.firestore.FieldValue.arrayUnion(uid),
        });

      cacheDeletePrefix("student_dash_");
      cacheDeletePrefix("teacher_dash_");
      res.json({ submitted: true, files: fileUrls });
    } catch (err: any) {
      if (handleMulterError(err, res)) return;
      console.error("homework submit error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// GET /api/homework/:id/submissions  — Teacher sees all submissions
router.get(
  "/homework/:id/submissions",
  requireRole("Teacher", "Principal"),
  async (req: Request, res: Response) => {
    try {
      const homeworkId = req.params.id as string;
      const snaps = await db
        .collection("homework_submissions")
        .where("homeworkId", "==", homeworkId)
        .get();

      const submissions = snaps.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          ...data,
          submittedAt: data.submittedAt?.toDate?.()?.toISOString?.() || null,
        };
      });

      const studentUids = submissions.map((s: any) => s.studentUid).filter(Boolean);
      const userMap: Record<string, string> = {};
      if (studentUids.length > 0) {
        const chunks = [];
        for (let i = 0; i < studentUids.length; i += 10) {
          chunks.push(studentUids.slice(i, i + 10));
        }
        for (const chunk of chunks) {
          const snap = await db
            .collection("users")
            .where(admin.firestore.FieldPath.documentId(), "in", chunk)
            .get();
          snap.docs.forEach((d) => {
            userMap[d.id] = d.data().name || d.id;
          });
        }
      }

      const enriched = submissions.map((s: any) => ({
        ...s,
        studentName: userMap[s.studentUid] || s.studentUid,
      }));

      res.json({ submissions: enriched });
    } catch (err: any) {
      console.error("getSubmissions error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

// GET /api/homework/:id/my-submission  — Student sees their own submission
router.get(
  "/homework/:id/my-submission",
  requireRole("Student"),
  async (req: Request, res: Response) => {
    try {
      const homeworkId = req.params.id as string;
      const uid = req.uid!;
      const docRef = db
        .collection("homework_submissions")
        .doc(`${homeworkId}_${uid}`);
      const snap = await docRef.get();
      if (!snap.exists) {
        return res.json({ submission: null });
      }
      const data = snap.data()!;
      res.json({
        submission: {
          id: snap.id,
          ...data,
          submittedAt: data.submittedAt?.toDate?.()?.toISOString?.() || null,
        },
      });
    } catch (err: any) {
      console.error("getMySubmission error:", err);
      res.status(500).json({ error: err.message || "Internal server error" });
    }
  }
);

export default router;
